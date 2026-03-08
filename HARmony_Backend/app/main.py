from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import os
from datetime import datetime
from typing import Optional

from app.schemas import (
    SensorData, PredictionResponse, HealthCheckResponse,
    ActivityListResponse, ModelInfoResponse, ErrorResponse
)
from app.models.har_model import HARModel

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

# Dependency to get the HAR model
def get_har_model() -> HARModel:
    global har_model  # Declare global to modify it
    if har_model is None or har_model.model is None:
        model_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "ml_models"))
        try:
            har_model = HARModel(model_path)
            print("✅ HAR Model reloaded successfully on demand.")
        except Exception as e:
            print(f"❌ Failed to reload HAR Model on demand: {e}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="HAR Model not loaded and failed to reload."
            )
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
    return ActivityListResponse(
        activities=model_instance.activity_labels,
        count=len(model_instance.activity_labels),
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
async def predict_activity(sensor_data: SensorData):
    try:
        model_instance = get_har_model()
        prediction_result = model_instance.predict(
            sensor_data.sensor_data,
            input_format=sensor_data.input_format
        )

        return PredictionResponse(
            activity=prediction_result['activity'],
            confidence=prediction_result['confidence'],
            user_id=sensor_data.user_id,
            # send timestamp as integer milliseconds
            timestamp=int(datetime.now().timestamp() * 1000),
            status="success",
            all_probabilities=prediction_result['probabilities']
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except HTTPException:
        raise # Re-raise HTTPExceptions
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Prediction failed: {e}")


# Simple diagnostics endpoint for quick test count
@app.get(
    "/diagnostics/quick-tests/count",
    summary="Quick test count",
    description="Returns the number of quick tests run (placeholder implementation).",
)
async def quick_test_count():
    # In a real deployment this might query a database or cache.
    return {"count": 0}
