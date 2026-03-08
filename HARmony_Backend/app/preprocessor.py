"""
Preprocess raw accelerometer data for the WISDM HAR 2D CNN model.
Expects 80 samples × 3 axes (x, y, z) = 240 floats. Also accepts 100×3 = 300 (uses first 80×3).
"""
import os
import numpy as np
import joblib

# Model expects: frame_size=80, N_FEATURES=3, input shape (80, 3, 1) for Conv2D
FRAME_SIZE = 80
N_FEATURES = 3
EXPECTED_FLOATS = FRAME_SIZE * N_FEATURES  # 240
# Alternative: 100-sample window from app -> use first 80*3
FALLBACK_FLOATS = 100 * N_FEATURES  # 300


def _get_scaler(model_dir: str):
    """Load optional StandardScaler fit on WISDM (har_scaler_wisdm.pkl)."""
    path = os.path.join(model_dir, 'har_scaler_wisdm.pkl')
    if os.path.exists(path):
        return joblib.load(path)
    return None


def prepare_sensor_window(sensor_data: list, model_dir: str = None):
    """
    Convert raw sensor_data (list of floats) into the shape the WISDM CNN expects.

    Expected input: 240 floats (80 timesteps × 3 axes: x, y, z), optionally interleaved
    as [x0,y0,z0, x1,y1,z1, ...] or 300 floats (100×3) — then first 240 are used.

    Preprocessing:
    1. Trim or pad to 240 values; reshape to (80, 3) as [x_series, y_series, z_series].
    2. If har_scaler_wisdm.pkl exists in model_dir, transform with it; else per-axis standardization.
    3. Reshape to (1, 80, 3, 1) for Conv2D input.

    Returns numpy array of shape (1, 80, 3, 1), dtype float32.
    """
    arr = np.array(sensor_data, dtype=np.float64)
    if arr.size < EXPECTED_FLOATS:
        raise ValueError(
            f"Need at least {EXPECTED_FLOATS} values (80 samples × 3 axes). Got {arr.size}. "
            "Send accelerometer x,y,z for 80 (or 100) timesteps."
        )
    # Use first 240
    arr = arr[:EXPECTED_FLOATS].reshape(FRAME_SIZE, N_FEATURES)

    # Assume order is [x, y, z] per timestep (x,y,z interleaved: idx 0,1,2 = x,y,z)
    # WISDM get_frames uses df['x'], df['y'], df['z'] -> columns 0,1,2 = x,y,z. OK.

    scaler = _get_scaler(model_dir) if model_dir else None
    if scaler is not None:
        # Scaler was fit on (N, 3); transform (80, 3)
        arr = scaler.transform(arr)
    else:
        # Per-axis standardization (zero mean, unit variance) on the window
        mean = arr.mean(axis=0)
        std = arr.std(axis=0)
        std[std == 0] = 1.0
        arr = (arr - mean) / std

    # Conv2D input: (batch, height, width, channels) -> (1, 80, 3, 1)
    arr = arr.astype(np.float32).reshape(1, FRAME_SIZE, N_FEATURES, 1)
    return arr


def get_expected_length():
    """Return the number of floats the API expects (240 for 80×3)."""
    return EXPECTED_FLOATS
