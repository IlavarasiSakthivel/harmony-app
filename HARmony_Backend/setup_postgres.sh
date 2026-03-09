#!/bin/bash
# PostgreSQL Database Setup Script for HARmony
# Run this script to set up PostgreSQL for the HARmony application

set -e

echo "================================"
echo "🗄️  PostgreSQL Setup for HARmony"
echo "================================"

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "❌ PostgreSQL is not installed. Please install it first:"
    echo "   macOS: brew install postgresql@15"
    echo "   Ubuntu/Debian: sudo apt-get install postgresql postgresql-contrib"
    echo "   Windows: Download from https://www.postgresql.org/download/windows/"
    exit 1
fi

echo "✅ PostgreSQL found"

# Create user and database
echo ""
echo "Creating database user and database..."

# Run as postgres user or use sudo
if command -v sudo &> /dev/null; then
    sudo -u postgres psql << EOF
-- Create user
CREATE USER harmony_user WITH PASSWORD 'harmony_password';

-- Create database
CREATE DATABASE harmony_db OWNER harmony_user;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE harmony_db TO harmony_user;

-- Connect to database and create schema
\c harmony_db

-- Create schema
CREATE SCHEMA IF NOT EXISTS harmony;
GRANT ALL PRIVILEGES ON SCHEMA harmony TO harmony_user;

-- Create tables
CREATE TABLE IF NOT EXISTS harmony.activities (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255),
    activity_name VARCHAR(100),
    confidence FLOAT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sensor_data JSONB
);

CREATE TABLE IF NOT EXISTS harmony.sessions (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255) UNIQUE,
    user_id VARCHAR(255),
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    summary TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS harmony.coaching_alerts (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255),
    alert_type VARCHAR(50),
    message TEXT,
    activity VARCHAR(100),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_activities_user_timestamp 
    ON harmony.activities(user_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_sessions_user_timestamp 
    ON harmony.sessions(user_id, start_time DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_user_timestamp 
    ON harmony.coaching_alerts(user_id, timestamp DESC);

-- Grant table privileges
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA harmony TO harmony_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA harmony TO harmony_user;

EOF
    
    echo "✅ Database setup complete!"
    echo ""
    echo "Connection Details:"
    echo "  Host: localhost"
    echo "  Port: 5432"
    echo "  Database: harmony_db"
    echo "  User: harmony_user"
    echo "  Password: harmony_password"
    echo ""
    echo "📝 Update your .env file with:"
    echo "  DATABASE_URL=postgresql://harmony_user:harmony_password@localhost:5432/harmony_db"
    
else
    echo "❌ Unable to access PostgreSQL. Please run this with sudo or as postgres user"
    exit 1
fi
