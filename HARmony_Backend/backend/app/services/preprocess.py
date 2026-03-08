"""
Normalize and prepare sensor data (128×9) for the HAR model.
"""
import numpy as np

from app.config.constants import (
    EXPECTED_WINDOW_SIZE,
    EXPECTED_FEATURE_DIM,
    DEFAULT_FEATURE_MEAN,
    DEFAULT_FEATURE_STD,
)


def normalize_sensor_data(sensor_data, mean=None, std=None):
    """
    Expects sensor_data as list of lists: 128 rows × 9 cols [x,y,z,gx,gy,gz,tx,ty,tz].
    Truncates or zero-pads to 128×9, then normalizes per feature.
    Returns float32 array of shape (1, 128, 9) for model input.
    """
    arr = np.array(sensor_data, dtype=np.float64)
    if arr.ndim == 1:
        arr = arr.reshape(-1, EXPECTED_FEATURE_DIM)
    rows, cols = arr.shape
    if cols != EXPECTED_FEATURE_DIM:
        raise ValueError(
            f"Expected {EXPECTED_FEATURE_DIM} features per row, got {cols}"
        )
    # Truncate or pad to 128 rows
    if rows < EXPECTED_WINDOW_SIZE:
        pad = np.zeros((EXPECTED_WINDOW_SIZE - rows, EXPECTED_FEATURE_DIM), dtype=np.float64)
        arr = np.vstack([arr, pad])
    else:
        arr = arr[:EXPECTED_WINDOW_SIZE]

    mean = np.array(mean or DEFAULT_FEATURE_MEAN, dtype=np.float64)
    std = np.array(std or DEFAULT_FEATURE_STD, dtype=np.float64)
    std[std == 0] = 1.0
    arr = (arr - mean) / std

    return arr.astype(np.float32).reshape(1, EXPECTED_WINDOW_SIZE, EXPECTED_FEATURE_DIM)
