"""
Load HAR model once at startup and run predictions.
Uses only the new TFLite model (har_model_fixed.tflite + labels.json).
"""
import json
import os
import time

import numpy as np

from app.config.constants import get_intensity_for_activity

_model = None
_model_path = None
_activity_labels = None
_tflite_input_details = None
_tflite_output_details = None
_tflite_timesteps = None
_tflite_features = None


def _load_labels(model_path: str):
    labels_json = os.path.join(model_path, "labels.json")
    if not os.path.exists(labels_json):
        raise FileNotFoundError(
            f"labels.json not found in {model_path}. This backend requires labels.json."
        )
    with open(labels_json, "r", encoding="utf-8") as f:
        labels = json.load(f)
    if not isinstance(labels, list):
        raise ValueError("labels.json must contain a JSON array of label names")
    return [str(x) for x in labels]


def _prepare_tflite_input(sensor_data):
    values = np.array(sensor_data, dtype=np.float32)
    if values.ndim == 2:
        if values.shape[1] != _tflite_features:
            raise ValueError(
                f"Expected {_tflite_features} features per timestep, got {values.shape[1]}"
            )
        values = values.flatten()
    else:
        values = values.flatten()

    expected_len = _tflite_timesteps * _tflite_features
    if values.size < expected_len:
        raise ValueError(
            f"Expected at least {expected_len} values for TFLite model input, got {values.size}"
        )
    if values.size > expected_len:
        values = values[:expected_len]

    arr = values.reshape(1, _tflite_timesteps, _tflite_features)

    # Per-window normalization across timesteps.
    mean = arr.mean(axis=1, keepdims=True)
    std = arr.std(axis=1, keepdims=True)
    std[std == 0] = 1.0
    return ((arr - mean) / std).astype(np.float32)


def init_model(app):
    """Load model once at startup. Call from create_app()."""
    global _model, _model_path, _activity_labels
    global _tflite_input_details, _tflite_output_details, _tflite_timesteps, _tflite_features

    model_path = os.path.abspath(app.config.get("MODEL_PATH", ""))
    _model_path = model_path

    tflite_path = os.path.join(model_path, "har_model_fixed.tflite")
    if not os.path.exists(tflite_path):
        raise FileNotFoundError(f"har_model_fixed.tflite not found in {model_path}")

    import tensorflow as tf

    interpreter = tf.lite.Interpreter(model_path=tflite_path)
    _tflite_input_details = interpreter.get_input_details()
    _tflite_output_details = interpreter.get_output_details()

    in_shape = _tflite_input_details[0].get("shape", [])
    if len(in_shape) < 3:
        raise ValueError(f"Unsupported TFLite input shape: {in_shape}")

    _tflite_timesteps = int(in_shape[1])
    _tflite_features = int(in_shape[2])

    out_shape = _tflite_output_details[0].get("shape", [])
    n_classes = int(out_shape[-1]) if len(out_shape) > 0 else 0
    labels = _load_labels(model_path)
    if n_classes > 0 and len(labels) != n_classes:
        raise ValueError(
            f"labels.json has {len(labels)} labels but model output has {n_classes} classes"
        )

    interpreter.allocate_tensors()

    _model = interpreter
    _activity_labels = labels

    print("HAR model loaded from", tflite_path)


def is_loaded():
    return _model is not None


def predict(sensor_data_2d):
    """
    sensor_data_2d: list (flattened) or list of lists depending on input.
    Returns dict: activity, confidence, probabilities, movement_intensity, energy_level.
    """
    if _model is None:
        raise RuntimeError("Model not loaded")

    t0 = time.perf_counter()

    X = _prepare_tflite_input(sensor_data_2d)
    input_index = _tflite_input_details[0]["index"]
    output_index = _tflite_output_details[0]["index"]

    _model.set_tensor(input_index, X)
    _model.invoke()
    probs = _model.get_tensor(output_index)[0]

    idx = int(np.argmax(probs))
    activity = _activity_labels[idx]
    confidence = float(probs[idx])
    probabilities = {_activity_labels[i]: float(probs[i]) for i in range(len(probs))}

    inference_ms = (time.perf_counter() - t0) * 1000
    movement_intensity = get_intensity_for_activity(activity)
    energy_level = "MODERATE"

    return {
        "activity": activity,
        "confidence": confidence,
        "probabilities": probabilities,
        "inference_time_ms": round(inference_ms, 2),
        "movement_intensity": movement_intensity,
        "energy_level": energy_level,
    }
