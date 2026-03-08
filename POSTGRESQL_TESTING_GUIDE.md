# PostgreSQL Database Testing & Debugging Guide

## 🚀 Quick Start

### 1. Start PostgreSQL Server

**macOS (with Homebrew):**
```bash
brew services start postgresql@15
```

**Ubuntu/Debian:**
```bash
sudo systemctl start postgresql
```

**Windows:**
```cmd
# Using pgAdmin or Services panel, or command line:
net start PostgreSQL
```

### 2. Verify PostgreSQL is Running

```bash
psql --version
psql -U postgres -c "SELECT version();"
```

---

## 📊 Testing Database Connection

### From Command Line
```bash
# Connect to harmony database
psql -U harmony_user -h localhost -d harmony_db -p 5432

# Password: harmony_password (when prompted)
```

### From Python

```python
import psycopg2

try:
    conn = psycopg2.connect(
        host="localhost",
        port=5432,
        database="harmony_db",
        user="harmony_user",
        password="harmony_password"
    )
    print("✅ Connection successful!")
    cur = conn.cursor()
    cur.execute("SELECT COUNT(*) FROM harmony.activities;")
    print(f"Total activities: {cur.fetchone()[0]}")
    conn.close()
except Exception as e:
    print(f"❌ Connection failed: {e}")
```

### From Django/Flask

```python
# In your Django settings or Flask config
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'harmony_db',
        'USER': 'harmony_user',
        'PASSWORD': 'harmony_password',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}

# Or in Flask:
app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://harmony_user:harmony_password@localhost:5432/harmony_db'
```

---

## 🔍 Common PostgreSQL Commands

### Connection Info
```sql
-- Check current connection
\conninfo

-- List all databases
\l

-- List all users
\du

-- Switch to specific database
\c harmony_db
```

### View Tables & Data
```sql
-- List all tables in schema
\dt harmony.*

-- Show table structure
\d harmony.activities

-- Count records
SELECT COUNT(*) FROM harmony.activities;

-- View recent activities
SELECT * FROM harmony.activities ORDER BY timestamp DESC LIMIT 10;

-- View recent sessions
SELECT * FROM harmony.sessions ORDER BY start_time DESC LIMIT 5;
```

### Insert Test Data
```sql
-- Insert test activity
INSERT INTO harmony.activities (user_id, activity_name, confidence, sensor_data)
VALUES ('test_user', 'Walking', 0.95, '{"ax": 0.1, "ay": 9.8, "az": 0.2}');

-- Insert test session
INSERT INTO harmony.sessions (user_id, start_time, end_time, duration_minutes, active_minutes)
VALUES ('test_user', NOW() - INTERVAL '1 hour', NOW(), 60, 45);

-- Insert test alert
INSERT INTO harmony.coaching_alerts (user_id, alert_type, message, activity)
VALUES ('test_user', 'movement', 'Time to move!', 'Sitting');
```

### Query Data
```sql
-- Get all activities for user today
SELECT activity_name, COUNT(*) as count, AVG(confidence) as avg_confidence
FROM harmony.activities
WHERE user_id = 'test_user' 
  AND timestamp::date = CURRENT_DATE
GROUP BY activity_name
ORDER BY count DESC;

-- Get session summary
SELECT 
    DATE(start_time) as date,
    COUNT(*) as sessions,
    SUM(duration_minutes) as total_minutes,
    SUM(active_minutes) as active_minutes
FROM harmony.sessions
WHERE user_id = 'test_user'
GROUP BY DATE(start_time)
ORDER BY date DESC;

-- Get alert history
SELECT alert_type, COUNT(*) as count, MAX(timestamp) as latest
FROM harmony.coaching_alerts
WHERE user_id = 'test_user'
GROUP BY alert_type
ORDER BY latest DESC;
```

### Performance & Monitoring
```sql
-- Check table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname = 'harmony'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Check index usage
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan as scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'harmony'
ORDER BY idx_scan DESC;

-- Monitor active connections
SELECT pid, usename, application_name, state FROM pg_stat_activity;

-- Check cache hit ratio
SELECT 
    sum(heap_blks_read) as heap_read,
    sum(heap_blks_hit) as heap_hit,
    sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) as ratio
FROM pg_statio_user_tables;
```

---

## ⚠️ Common Issues & Solutions

### Connection Refused
```
ERROR: could not connect to server: Connection refused
Is the server running on host "localhost" (127.0.0.1) and accepting TCP/IP connections on port 5432?
```

**Solution:**
```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql  # Linux
brew services list | grep postgres  # macOS

# Start PostgreSQL
sudo systemctl start postgresql  # Linux
brew services start postgresql@15  # macOS
```

### "password authentication failed"
```
FATAL: password authentication failed for user "harmony_user"
```

**Solution:**
```bash
# Reset password
psql -U postgres -c "ALTER USER harmony_user WITH PASSWORD 'harmony_password';"
```

### "database does not exist"
```
ERROR: database "harmony_db" does not exist
```

**Solution:**
```bash
# Run the setup script again
bash setup_postgres.sh
```

### "permission denied"
```
ERROR: permission denied for schema harmony
```

**Solution:**
```sql
-- Grant permissions
GRANT ALL PRIVILEGES ON SCHEMA harmony TO harmony_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA harmony TO harmony_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA harmony TO harmony_user;
```

---

## 🧪 Testing Script

Save as `test_db.py`:

```python
#!/usr/bin/env python3
import psycopg2
from datetime import datetime, timedelta
import json

def test_database():
    try:
        # Connect
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            database="harmony_db",
            user="harmony_user",
            password="harmony_password"
        )
        cur = conn.cursor()
        print("✅ Connected to database")
        
        # Test inserts
        sensor_data = json.dumps({"ax": 0.1, "ay": 9.8, "az": 0.2})
        cur.execute(
            "INSERT INTO harmony.activities (user_id, activity_name, confidence, sensor_data) VALUES (%s, %s, %s, %s)",
            ('test_user', 'Walking', 0.92, sensor_data)
        )
        print("✅ Inserted activity")
        
        # Test queries
        cur.execute("SELECT COUNT(*) FROM harmony.activities")
        count = cur.fetchone()[0]
        print(f"✅ Total activities in DB: {count}")
        
        cur.execute("SELECT * FROM harmony.activities ORDER BY timestamp DESC LIMIT 1")
        latest = cur.fetchone()
        print(f"✅ Latest activity: {latest}")
        
        # Cleanup
        cur.execute("DELETE FROM harmony.activities WHERE user_id = 'test_user'")
        conn.commit()
        print("✅ Cleanup completed")
        
        conn.close()
        print("✅ All tests passed!")
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    test_database()
```

Run it:
```bash
python test_db.py
```

---

## 📱 Using pgAdmin GUI

**Download:** https://www.pgadmin.org/download/

1. Open pgAdmin
2. Click "Add New Server"
3. Fill in:
   - Name: `HARmony DB`
   - Host: `localhost`
   - Port: `5432`
   - Username: `harmony_user`
   - Password: `harmony_password`
4. Click "Save"
5. Browse tables under `harmony_db` > `Schemas` > `harmony`

---

## 🔐 Remote Access (Production)

To allow remote connections, edit `/etc/postgresql/*/main/postgresql.conf`:

```
listen_addresses = '*'  # or specific IP addresses
```

And edit `/etc/postgresql/*/main/pg_hba.conf`:

```
# remote connection
host    harmony_db    harmony_user    0.0.0.0/0    md5
```

**⚠️ WARNING:** Only do this in secure networks. Use SSH tunneling for production:

```bash
ssh -L 5432:localhost:5432 your_server
```

---

## 📈 Performance Tuning

For development, these settings in `postgresql.conf` are fine. For production:

```conf
# Memory
shared_buffers = 256MB          # 25% of available RAM
effective_cache_size = 1GB      # 50-75% of available RAM
work_mem = 16MB                 # per operation

# Connections
max_connections = 100

# Query planning
random_page_cost = 1.1          # for SSD
```

Restart PostgreSQL to apply changes:
```bash
sudo systemctl restart postgresql
```

---

## 🗑️ Cleanup/Reset

**Delete all data:**
```sql
TRUNCATE TABLE harmony.activities CASCADE;
TRUNCATE TABLE harmony.sessions CASCADE;
TRUNCATE TABLE harmony.coaching_alerts CASCADE;
```

**Drop everything and recreate:**
```bash
bash setup_postgres.sh
```

**Full uninstall (caution!):**
```bash
# Ubuntu
sudo apt-get remove postgresql postgresql-contrib

# macOS
brew uninstall postgresql@15
```

---

Need help? Check PostgreSQL docs: https://www.postgresql.org/docs/
