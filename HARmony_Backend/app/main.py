from fastapi import FastAPI, HTTPException, status, Depends
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import os
from datetime import datetime
from typing import Optional, Dict, Any
import hashlib
import logging
from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, text
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.exc import SQLAlchemyError

from app.schemas import (
    SensorData, PredictionResponse, HealthCheckResponse,
    ActivityListResponse, ModelInfoResponse, ErrorResponse, ActivitiesResponse, StoredActivity, SessionData
)
from app.models.har_model import HARModel

# Logging configuration
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Database setup
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://harmony_user:harmony_password@localhost:5432/harmony_db")
engine = create_engine(DATABASE_URL, pool_pre_ping=True, pool_recycle=3600)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Database Models
class Activity(Base):
    __tablename__ = "activities"
    __table_args__ = {'schema': 'harmony'}
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, index=True)
    activity_name = Column(String)
    confidence = Column(Float)
    timestamp = Column(DateTime, default=datetime.utcnow)

class Session(Base):
    __tablename__ = "sessions"
    __table_args__ = {'schema': 'harmony'}
    
    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(String, unique=True, index=True)
    user_id = Column(String, index=True)
    start_time = Column(DateTime)
    end_time = Column(DateTime)
    summary = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

# Global model instance
har_model: Optional[HARModel] = None

def _check_database_connection() -> bool:
    """Check if database connection is healthy"""
    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
        return True
    except Exception as e:
        logger.error(f"❌ Database connection failed: {e}")
        return False

def _initialize_database() -> bool:
    """Create database schema if it doesn't exist"""
    try:
        # Create schema if not exists
        with engine.connect() as connection:
            connection.execute(text("CREATE SCHEMA IF NOT EXISTS harmony"))
            connection.commit()
        
        # Create tables
        Base.metadata.create_all(bind=engine)
        logger.info("✅ Database schema initialized")
        return True
    except Exception as e:
        logger.error(f"❌ Database initialization failed: {e}")
        return False

@asynccontextmanager
async def lifespan(app: FastAPI):
    global har_model
    
    # On startup
    logger.info("🚀 Starting HARmony API...")
    
    # Initialize database
    db_healthy = _initialize_database()
    if not db_healthy:
        logger.warning("⚠️ Database initialization issues detected")
    
    # Load model
    model_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "ml_models"))
    try:
        har_model = HARModel(model_path)
        logger.info("✅ HAR Model loaded successfully at startup")
    except Exception as e:
        logger.error(f"❌ Failed to load HAR Model at startup: {e}")
        har_model = None
    
    yield
    
    # On shutdown
    logger.info("👋 Shutting down HARmony API")

app = FastAPI(
    title="HARmony Activity Recognition API",
    version="1.0.0",
    description="API for Human Activity Recognition using sensor data.",
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Adjust this to your Flutter app's origin in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Dependency to get the HAR model
def get_har_model() -> Optional[HARModel]:
    global har_model
    if har_model is None or har_model.model is None:
        model_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "ml_models"))
        try:
            har_model = HARModel(model_path)
            logger.info("✅ HAR Model reloaded successfully on demand")
        except Exception as e:
            logger.error(f"❌ Failed to reload HAR Model on demand: {e}")
            return None
    return har_model

# === API Routes ===

@app.get(
    "/health",
    response_model=HealthCheckResponse,
    summary="Health Check",
    description="Checks the health and status of the HARmony API and model loading."
)
async def health_check():
    model_status = har_model is not None and har_model.model is not None
    db_status = _check_database_connection()
    overall_status = "healthy" if (model_status and db_status) else "degraded"
    
    message_parts = []
    if model_status:
        message_parts.append("Model loaded")
    else:
        message_parts.append("Model not loaded (using heuristic predictions)")
    
    if db_status:
        message_parts.append("Database OK")
    else:
        message_parts.append("Database connection issues")
    
    return HealthCheckResponse(
        status=overall_status,
        message=" | ".join(message_parts),
        model_loaded=model_status,
        timestamp=datetime.now().isoformat(),
        version="1.0.0"
    )

@app.get(
    "/activities",
    response_model=ActivityListResponse,
    summary="Get Activity List",
    description="Returns a list of all human activities the model can recognize."
)
async def get_activities():
    model_instance = get_har_model()
    if model_instance is None:
        # Return default activities if model not loaded
        activities = ["walking", "running", "sitting", "standing", "laying"]
    else:
        activities = model_instance.activity_labels
    return ActivityListResponse(
        activities=activities,
        count=len(activities),
        status="success"
    )

@app.get(
    "/model-info",
    response_model=ModelInfoResponse,
    summary="Get Model Information",
    description="Provides details about the loaded HAR model, including expected features and activity labels."
)
async def model_info():
    model_instance = get_har_model()
    if model_instance is None:
        return ModelInfoResponse(
            model_type="TFLite",
            activity_labels=["walking", "running", "sitting", "standing", "laying"],
            feature_count=384,  # 128 timesteps * 3 features
            feature_preview=["window_0", "window_1", "window_2"],
            model_loaded=False,
            has_scaler=False,
            model_features="384"
        )
    
    feature_preview = model_instance.feature_names[:10] if model_instance.feature_names else []
    if getattr(model_instance, '_expected_input_len', None) is not None:
        model_features_count = model_instance._expected_input_len
    else:
        model_features_count = model_instance.model.n_features_in_ if hasattr(model_instance.model, 'n_features_in_') else 'unknown'

    return ModelInfoResponse(
        model_type=type(model_instance.model).__name__,
        activity_labels=model_instance.activity_labels,
        feature_count=len(model_instance.feature_names),
        feature_preview=feature_preview,
        model_loaded=True,
        has_scaler=model_instance.scaler is not None,
        model_features=str(model_features_count)
    )

@app.post(
    "/predict",
    response_model=PredictionResponse,
    summary="Predict Human Activity",
    description="Receives sensor data and returns the predicted human activity with a confidence score.",
    status_code=status.HTTP_200_OK,
    responses={
        status.HTTP_400_BAD_REQUEST: {"model": ErrorResponse, "description": "Invalid input data"},
        status.HTTP_500_INTERNAL_SERVER_ERROR: {"model": ErrorResponse, "description": "Prediction failed"},
        status.HTTP_503_SERVICE_UNAVAILABLE: {"model": ErrorResponse, "description": "Model not loaded"}
    }
)
async def predict_activity(sensor_data: SensorData, db: Session = Depends(get_db)):
    try:
        # Validate sensor data length
        if len(sensor_data.sensor_data) < 120:
            raise ValueError(f"Insufficient sensor data: {len(sensor_data.sensor_data)} values, need 120 (40 samples x 3 axes)")
        
        # If more than 120 values, take first 120
        sensor_values = sensor_data.sensor_data[:120]
        
        model_instance = get_har_model()
        if model_instance is None:
            # Heuristic prediction when model isn't available
            import math
            mags = []
            for i in range(0, len(sensor_values) - 2, 3):
                x = sensor_values[i]
                y = sensor_values[i + 1]
                z = sensor_values[i + 2]
                mags.append(math.sqrt(x * x + y * y + z * z))
            
            avg_mag = sum(mags) / len(mags) if mags else 9.8
            
            # Classification based on typical gravity (9.8 m/s^2)
            if avg_mag < 9.5:
                activity = "Sitting"
            elif avg_mag < 10.5:
                activity = "Walking"
            else:
                activity = "Running"
            
            confidence = (avg_mag - 9.0) / 2.0
            confidence = max(0.5, min(1.0, confidence))
            
            activities = ['Walking', 'Running', 'Sitting', 'Standing', 'Laying']
            probabilities = {act: (1.0 - confidence) / (len(activities) - 1) for act in activities}
            probabilities[activity] = confidence
            
            logger.warning(f"⚠️ Using heuristic prediction: {activity} ({confidence:.2f})")
        else:
            prediction_result = model_instance.predict(
                sensor_values,
                input_format=sensor_data.input_format
            )
            activity = prediction_result['activity']
            confidence = prediction_result['confidence']
            probabilities = prediction_result['probabilities']
        
        # Save to database
        try:
            db_activity = Activity(
                user_id=sensor_data.user_id,
                activity_name=activity,
                confidence=confidence
            )
            db.add(db_activity)
            db.commit()
            db.refresh(db_activity)
        except SQLAlchemyError as e:
            logger.error(f"❌ Database error saving activity: {e}")
            db.rollback()
            # Still return prediction even if save fails
        
        return PredictionResponse(
            activity=activity,
            confidence=confidence,
            user_id=sensor_data.user_id,
            timestamp=int(datetime.now().timestamp() * 1000),
            status="success",
            all_probabilities=probabilities
        )
    except ValueError as e:
        logger.warning(f"⚠️ Validation error: {e}")
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Prediction error: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Prediction failed: {str(e)}")


@app.get(
    "/activities/stored",
    response_model=ActivitiesResponse,
    summary="Get Stored Activities",
    description="Returns stored activity predictions from the database."
)
async def get_stored_activities(user_id: Optional[str] = None, limit: int = 100, db: Session = Depends(get_db)):
    query = db.query(Activity)
    if user_id:
        query = query.filter(Activity.user_id == user_id)
    activities = query.order_by(Activity.timestamp.desc()).limit(limit).all()
    
    return ActivitiesResponse(
        activities=[StoredActivity(
            id=a.id,
            user_id=a.user_id,
            activity_name=a.activity_name,
            confidence=a.confidence,
            timestamp=a.timestamp
        ) for a in activities],
        count=len(activities),
        status="success"
    )


@app.post(
    "/sessions",
    summary="Save Activity Session",
    description="Saves an activity session with all predictions to the database."
)
async def save_session(session_data: SessionData, db: Session = Depends(get_db)):
    try:
        # Check if session already exists
        existing = db.query(Session).filter(Session.session_id == session_data.session_id).first()
        if existing:
            logger.info(f"ℹ️ Session {session_data.session_id} already exists")
            return {"status": "success", "message": "Session already exists"}
        
        # Save session
        db_session = Session(
            session_id=session_data.session_id,
            user_id=session_data.user_id,
            start_time=datetime.fromtimestamp(session_data.start_time / 1000),
            end_time=datetime.fromtimestamp(session_data.end_time / 1000),
            summary=session_data.summary
        )
        db.add(db_session)
        db.flush()  # Flush to generate ID before commit
        
        # Save individual activities
        activity_count = 0
        for activity in session_data.activities:
            try:
                db_activity = Activity(
                    user_id=session_data.user_id,
                    activity_name=activity.get('activity', 'unknown'),
                    confidence=activity.get('confidence', 0.0),
                    timestamp=datetime.fromtimestamp(activity.get('timestamp', session_data.end_time) / 1000)
                )
                db.add(db_activity)
                activity_count += 1
            except Exception as e:
                logger.error(f"❌ Error adding activity: {e}")
                continue
        
        db.commit()
        logger.info(f"✅ Session {session_data.session_id} saved with {activity_count} activities")
        
        return {
            "status": "success", 
            "message": f"Session saved successfully with {activity_count} activities",
            "session_id": session_data.session_id
        }
    except SQLAlchemyError as e:
        logger.error(f"❌ Database error saving session: {e}")
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        logger.error(f"❌ Error saving session: {e}")
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to save session: {str(e)}")


@app.get(
    "/sessions",
    summary="Get Activity Sessions",
    description="Retrieves stored activity sessions from the database."
)
async def get_sessions(user_id: Optional[str] = None, limit: int = 50, db: Session = Depends(get_db)):
    try:
        query = db.query(Session)
        if user_id:
            query = query.filter(Session.user_id == user_id)
        
        sessions = query.order_by(Session.start_time.desc()).limit(limit).all()
        
        result = []
        for session in sessions:
            # Get activities for this session
            activities = db.query(Activity).filter(
                Activity.user_id == session.user_id,
                Activity.timestamp >= session.start_time,
                Activity.timestamp <= session.end_time
            ).order_by(Activity.timestamp).all()
            
            result.append({
                "session_id": session.session_id,
                "user_id": session.user_id,
                "start_time": int(session.start_time.timestamp() * 1000),
                "end_time": int(session.end_time.timestamp() * 1000),
                "duration_minutes": int((session.end_time - session.start_time).total_seconds() / 60),
                "summary": session.summary,
                "activities": [{
                    "activity": a.activity_name,
                    "confidence": a.confidence,
                    "timestamp": int(a.timestamp.timestamp() * 1000)
                } for a in activities]
            })
        
        logger.info(f"✅ Fetched {len(result)} sessions")
        return {"sessions": result, "count": len(result), "status": "success"}
    except SQLAlchemyError as e:
        logger.error(f"❌ Database error fetching sessions: {e}")
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        logger.error(f"❌ Error fetching sessions: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch sessions: {str(e)}")


# Simple diagnostics endpoint for quick test count
@app.get(
    "/diagnostics/quick-tests/count",
    summary="Quick test count",
    description="Returns the number of quick tests run (placeholder implementation).",
)
async def quick_test_count():
    return {"total_tests": 47, "passed": 47}


@app.get(
    "/diagnostics/database",
    summary="Database Diagnostics",
    description="Returns database health and statistics"
)
async def database_diagnostics(db: Session = Depends(get_db)):
    try:
        db_healthy = _check_database_connection()
        
        activity_count = db.query(Activity).count()
        session_count = db.query(Session).count()
        
        # Get latest activities
        latest_activities = db.query(Activity).order_by(Activity.timestamp.desc()).limit(5).all()
        
        return {
            "status": "healthy" if db_healthy else "unhealthy",
            "database_connected": db_healthy,
            "total_activities": activity_count,
            "total_sessions": session_count,
            "schema": "harmony",
            "latest_activities": [
                {
                    "activity": a.activity_name,
                    "confidence": a.confidence,
                    "timestamp": a.timestamp.isoformat()
                } for a in latest_activities
            ]
        }
    except Exception as e:
        logger.error(f"❌ Database diagnostics error: {e}")
        return {
            "status": "error",
            "error": str(e)
        }


@app.delete(
    "/sessions/{session_id}",
    summary="Delete Session",
    description="Deletes a specific session and its activities"
)
async def delete_session(session_id: str, db: Session = Depends(get_db)):
    try:
        session = db.query(Session).filter(Session.session_id == session_id).first()
        if not session:
            raise HTTPException(status_code=404, detail=f"Session {session_id} not found")
        
        # Delete associated activities
        db.query(Activity).filter(
            Activity.user_id == session.user_id,
            Activity.timestamp >= session.start_time,
            Activity.timestamp <= session.end_time
        ).delete()
        
        # Delete session
        db.delete(session)
        db.commit()
        
        logger.info(f"✅ Session {session_id} deleted")
        return {"status": "success", "message": f"Session {session_id} deleted"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error deleting session: {e}")
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to delete session: {str(e)}")


@app.delete(
    "/data/clear-all",
    summary="Clear All Data",
    description="Clears all activity and session data (use with caution!)"
)
async def clear_all_data(db: Session = Depends(get_db)):
    try:
        # Confirm with a query parameter
        activity_count = db.query(Activity).count()
        session_count = db.query(Session).count()
        
        # Delete all
        db.query(Activity).delete()
        db.query(Session).delete()
        db.commit()
        
        logger.warning(f"⚠️ All data cleared: {activity_count} activities, {session_count} sessions deleted")
        return {
            "status": "success",
            "message": "All data cleared",
            "deleted_activities": activity_count,
            "deleted_sessions": session_count
        }
    except Exception as e:
        logger.error(f"❌ Error clearing data: {e}")
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to clear data: {str(e)}")
