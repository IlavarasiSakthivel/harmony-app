from fastapi import FastAPI, HTTPException, status, Depends
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import os
from datetime import datetime
from typing import Optional, Dict, Any
import hashlib
from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.ext.declarative import declarative_base

from app.schemas import (
    SensorData, PredictionResponse, HealthCheckResponse,
    ActivityListResponse, ModelInfoResponse, ErrorResponse, ActivitiesResponse, StoredActivity, SessionData
)
from app.models.har_model import HARModel

# Database setup
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://harmony_user:harmony_password@localhost:5432/harmony_db")
engine = create_engine(DATABASE_URL)
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

@asynccontextmanager
async def lifespan(app: FastAPI):
    global har_model
    model_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "ml_models"))
    try:
        har_model = HARModel(model_path)
        print("✅ HAR Model loaded successfully at startup.")
    except Exception as e:
        print(f"❌ Failed to load HAR Model at startup: {e}")
        har_model = None  # Ensure model is None if loading fails
    yield
    # Clean up or close resources if needed
    print("👋 Shutting down HARmony API.")

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
    global har_model  # Declare global to modify it
    if har_model is None or har_model.model is None:
        model_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "ml_models"))
        try:
            har_model = HARModel(model_path)
            print("✅ HAR Model reloaded successfully on demand.")
        except Exception as e:
            print(f"❌ Failed to reload HAR Model on demand: {e}")
            return None  # Return None instead of raising exception
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
    return HealthCheckResponse(
        status="healthy" if model_status else "unhealthy",
        message="HARmony API is running" if model_status else "HARmony API is running but model not loaded",
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
        model_instance = get_har_model()
        if model_instance is None:
            # Heuristic prediction when model isn't available. We examine the
            # accelerometer magnitude (sqrt(x^2+y^2+z^2)) and classify based on
            # how much the value deviates from gravity. This yields much more
            # sensible results during manual testing compared to the previous
            # arbitrary hash-based scheme.
            import math
            mags = []
            vals = sensor_data.sensor_data
            for i in range(0, len(vals) - 2, 3):
                x = vals[i]
                y = vals[i + 1]
                z = vals[i + 2]
                mags.append(math.sqrt(x * x + y * y + z * z))
            avg_mag = sum(mags) / len(mags) if mags else 0.0

            # Typical stationary magnitude is ~9.8 (gravity). Use loose thresholds.
            if avg_mag < 9.5:
                activity = "sitting"
            elif avg_mag < 10.5:
                activity = "walking"
            else:
                activity = "running"
            confidence = (avg_mag - 9.0) / 2.0
            confidence = max(0.5, min(1.0, confidence))

            activities = ['walking', 'running', 'sitting', 'standing', 'laying']
            probabilities = {act: (1.0 - confidence) / (len(activities) - 1) for act in activities}
            probabilities[activity] = confidence
        else:
            prediction_result = model_instance.predict(
                sensor_data.sensor_data,
                input_format=sensor_data.input_format
            )
            activity = prediction_result['activity']
            confidence = prediction_result['confidence']
            probabilities = prediction_result['probabilities']

        # Save to database
        db_activity = Activity(
            user_id=sensor_data.user_id,
            activity_name=activity,
            confidence=confidence
        )
        db.add(db_activity)
        db.commit()
        db.refresh(db_activity)

        return PredictionResponse(
            activity=activity,
            confidence=confidence,
            user_id=sensor_data.user_id,
            # send timestamp as integer milliseconds
            timestamp=int(datetime.now().timestamp() * 1000),
            status="success",
            all_probabilities=probabilities
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except HTTPException:
        raise # Re-raise HTTPExceptions
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Prediction failed: {e}")


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
        db.commit()
        db.refresh(db_session)
        
        # Save individual activities
        for activity in session_data.activities:
            db_activity = Activity(
                user_id=session_data.user_id,
                activity_name=activity.get('activity', 'unknown'),
                confidence=activity.get('confidence', 0.0),
                timestamp=datetime.fromtimestamp(activity.get('timestamp', session_data.end_time) / 1000)
            )
            db.add(db_activity)
        
        db.commit()
        
        return {"status": "success", "message": "Session saved successfully"}
    except Exception as e:
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
                "summary": session.summary,
                "activities": [{
                    "activity": a.activity_name,
                    "confidence": a.confidence,
                    "timestamp": int(a.timestamp.timestamp() * 1000)
                } for a in activities]
            })
        
        return {"sessions": result, "count": len(result)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch sessions: {str(e)}")


# Simple diagnostics endpoint for quick test count
@app.get(
    "/diagnostics/quick-tests/count",
    summary="Quick test count",
    description="Returns the number of quick tests run (placeholder implementation).",
)
async def quick_test_count():
    # In a real deployment this might query a database or cache.
    return {"count": 0}
