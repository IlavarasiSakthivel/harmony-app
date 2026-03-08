from fastapi import APIRouter, HTTPException, status, Depends
from datetime import datetime
import os

from app.schemas import (
    SensorData, PredictionResponse, HealthCheckResponse,
    ActivityListResponse, ModelInfoResponse, ErrorResponse
)
from app.models.har_model import HARModel

# Initialize router
api_router = APIRouter(prefix="/api", tags=["HARmony API"])

# Global model instance, to be initialized by lifespan event in main.py
har_model_instance: HARModel = None

# Dependency to get the HAR model
def get_har_model_dependency() -> HARModel:
    # This dependency assumes har_model_instance is set by main.py's lifespan
    if har_model_instance is None or har_model_instance.model is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="HAR Model not loaded. Server might be initializing or encountered an error."
        )
    return har_model_instance

# === API Routes ===

@api_router.get(
    "/health",
    response_model=HealthCheckResponse,
    summary="Health Check",
    description="Checks the health and status of the HARmony API and model loading."
)
async def health_check():
    model_status = har_model_instance is not None and har_model_instance.model is not None
    return HealthCheckResponse(
        status="healthy" if model_status else "unhealthy",
        message="HARmony API is running" if model_status else "HARmony API is running but model not loaded",
        model_loaded=model_status,
        timestamp=datetime.now().isoformat(),
        version="1.0.0"
    )

@api_router.get(
    "/activities",
    response_model=ActivityListResponse,
    summary="Get Activity List",
    description="Returns a list of all human activities the model can recognize."
)
async def get_activities(model_instance: HARModel = Depends(get_har_model_dependency)):
    return ActivityListResponse(
        activities=model_instance.activity_labels,
        count=len(model_instance.activity_labels),
        status="success"
    )

@api_router.get(
    "/model-info",
    response_model=ModelInfoResponse,
    summary="Get Model Information",
    description="Provides details about the loaded HAR model, including expected features and activity labels."
)
async def model_info(model_instance: HARModel = Depends(get_har_model_dependency)):
    
    feature_preview = model_instance.feature_names[:10] if model_instance.feature_names else []
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

@api_router.post(
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
async def predict_activity(
    sensor_data: SensorData,
    model_instance: HARModel = Depends(get_har_model_dependency)
):
    try:
        prediction_result = model_instance.predict(
            sensor_data.sensor_data,
            input_format=sensor_data.input_format
        )

        return PredictionResponse(
            activity=prediction_result['activity'],
            confidence=prediction_result['confidence'],
            user_id=sensor_data.user_id,
            timestamp=datetime.now().isoformat(),
            status="success",
            all_probabilities=prediction_result['probabilities']
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except HTTPException:
        raise # Re-raise HTTPExceptions
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Prediction failed: {e}")
