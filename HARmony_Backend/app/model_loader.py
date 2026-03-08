"""
Load and cache the WISDM HAR Keras model on server startup.
Supports both full model files (.keras / .h5 from load_model) and weights-only .h5
(from the aakashratha1006/Human-Activity-Recognition repo).
"""
import os
import numpy as np

# Lazy import so server can start even if TF not installed (graceful error)
_keras_model = None
_keras_backend = None


def _get_keras():
    """Lazy load TensorFlow/Keras."""
    global _keras_backend
    if _keras_backend is None:
        try:
            import tensorflow as tf
            from tensorflow import keras
            _keras_backend = (tf, keras)
        except ImportError as e:
            raise ImportError(
                "TensorFlow is required for the WISDM HAR model. "
                "Install with: pip install tensorflow"
            ) from e
    return _keras_backend


def _build_wisdm_cnn(input_shape=(80, 3, 1), num_classes=6):
    """Build the 2D CNN architecture used in aakashratha1006/Human-Activity-Recognition."""
    _, keras = _get_keras()
    from tensorflow.keras import Sequential
    from tensorflow.keras.layers import Conv2D, Dropout, Flatten, Dense

    model = Sequential([
        Conv2D(16, (2, 2), activation='relu', input_shape=input_shape),
        Dropout(0.1),
        Conv2D(32, (2, 2), activation='relu'),
        Dropout(0.2),
        Flatten(),
        Dense(64, activation='relu'),
        Dropout(0.5),
        Dense(num_classes, activation='softmax'),
    ])
    return model


def load_har_model(model_dir: str):
    """
    Load the HAR model from model_dir. Caches the model in memory for fast inference.

    Expected files in model_dir:
    - model.h5 (weights only, from aakashratha1006 repo) -> build architecture and load_weights
    - OR har_model.h5 / har_model.keras (full model) -> keras.models.load_model

    Returns the Keras Model instance and the list of activity labels in index order.
    """
    global _keras_model
    if _keras_model is not None:
        return _keras_model

    tf, keras = _get_keras()

    # Activity labels for WISDM (must match training LabelEncoder order)
    # In aakashratha1006, balanced_data order of first appearance: Walking, Jogging, Upstairs, Downstairs, Sitting, Standing
    # So: 0=Walking, 1=Jogging, 2=Upstairs, 3=Downstairs, 4=Sitting, 5=Standing
    activity_labels = [
        'Walking', 'Jogging', 'Upstairs', 'Downstairs', 'Sitting', 'Standing'
    ]

    full_model_paths = [
        os.path.join(model_dir, 'har_model.keras'),
        os.path.join(model_dir, 'har_model.h5'),
    ]
    weights_path = os.path.join(model_dir, 'model.h5')

    for path in full_model_paths:
        if os.path.exists(path):
            print(f"📦 Loading full Keras model from {path}...")
            _keras_model = keras.models.load_model(path)
            print("✅ Keras model loaded (full model)")
            return _keras_model

    if os.path.exists(weights_path):
        print(f"📦 Building WISDM CNN and loading weights from {weights_path}...")
        model = _build_wisdm_cnn(input_shape=(80, 3, 1), num_classes=6)
        model.load_weights(weights_path)
        _keras_model = model
        print("✅ Keras model loaded (weights only)")
        return _keras_model

    raise FileNotFoundError(
        f"No HAR model found in {model_dir}. "
        "Add model.h5 (from aakashratha1006/Human-Activity-Recognition) or har_model.keras / har_model.h5."
    )


def get_cached_model():
    """Return the cached Keras model or None if not loaded."""
    return _keras_model


def get_wisdm_activity_labels():
    """Return activity labels in the same order as the model output indices (LabelEncoder order)."""
    return ['Walking', 'Jogging', 'Upstairs', 'Downstairs', 'Sitting', 'Standing']
