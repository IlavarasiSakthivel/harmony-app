from pydantic import BaseModel, Field
from typing import List, Dict, Optional
from datetime import datetime

class SensorData(BaseModel):
    sensor_data: List[float] = Field(
        ...,
        example=[
            0.12, -0.03, 9.81,
            0.10, -0.02, 9.80,
            0.11, -0.01, 9.79
        ]
    )
    input_format: Optional[str] = Field(
        default=None,
        description="Use 'raw' for accelerometer windows (x,y,z interleaved) or 'features' for 561-length feature vectors."
    )
    user_id: Optional[str] = "anonymous"

class PredictionResponse(BaseModel):
    activity: str = Field(..., example="walking")
    confidence: float = Field(..., example=0.95)
    user_id: str = Field(..., example="anonymous")
    timestamp: str = Field(..., example="2026-01-26T12:34:56.789")
    status: str = Field(..., example="success")
    all_probabilities: Dict[str, float] = Field(..., example={"walking": 0.95, "running": 0.03, "sitting": 0.02})

class HealthCheckResponse(BaseModel):
    status: str = Field(..., example="healthy")
    message: str = Field(..., example="HARmony API is running")
    model_loaded: bool = Field(..., example=True)
    timestamp: str = Field(..., example="2026-01-26T12:34:56.789")
    version: str = Field(..., example="1.0.0")

class ActivityListResponse(BaseModel):
    activities: List[str] = Field(..., example=["walking", "running", "sitting"])
    count: int = Field(..., example=5)
    status: str = Field(..., example="success")

class ModelInfoResponse(BaseModel):
    model_type: str = Field(..., example="RandomForestClassifier")
    activity_labels: List[str] = Field(..., example=["walking", "running", "sitting"])
    feature_count: int = Field(..., example=561)
    feature_preview: List[str] = Field(..., example=["tBodyAcc-mean()-X", "tBodyAcc-mean()-Y"])
    model_loaded: bool = Field(..., example=True)
    has_scaler: bool = Field(..., example=True)
    model_features: str = Field(..., example="561") # Can be int or 'unknown'

class ErrorResponse(BaseModel):
    error: str = Field(..., example="Missing sensor_data in request")
    status_code: int = Field(..., example=400)
