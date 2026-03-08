import json
import os

import numpy as np


class HARModel:
    def __init__(self, model_path):
        self.model_path = model_path
        self.model = None
        self.scaler = None
        self.feature_names = None
        self.activity_labels = None

        self.tflite_interpreter = None
        self.tflite_input_details = None
        self.tflite_output_details = None
        self.tflite_timesteps = None
        self.tflite_features = None
        self._expected_input_len = None

        self.load_models()

    def _load_labels_json(self):
        labels_path = os.path.join(self.model_path, "labels.json")
        if not os.path.exists(labels_path):
            raise FileNotFoundError(
                f"labels.json not found in {self.model_path}. "
                "This backend now requires labels.json for the new TFLite model."
            )
        with open(labels_path, "r", encoding="utf-8") as f:
            labels = json.load(f)
        if not isinstance(labels, list):
            raise ValueError("labels.json must contain a JSON array of label names")
        return [str(x) for x in labels]

    def load_models(self):
        """Load only the new TFLite model (har_model_fixed.tflite)."""
        tflite_path = os.path.join(self.model_path, "har_model_fixed.tflite")
        if not os.path.exists(tflite_path):
            raise FileNotFoundError(
                f"har_model_fixed.tflite not found in {self.model_path}."
            )

        import tensorflow as tf

        interpreter = tf.lite.Interpreter(model_path=tflite_path)
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()

        input_shape = input_details[0].get("shape", [])
        if len(input_shape) < 3:
            raise ValueError(f"Unsupported TFLite input shape: {input_shape}")

        self.tflite_timesteps = int(input_shape[1])
        self.tflite_features = int(input_shape[2])
        self._expected_input_len = self.tflite_timesteps * self.tflite_features

        output_shape = output_details[0].get("shape", [])
        n_classes = int(output_shape[-1]) if len(output_shape) > 0 else 0

        labels = self._load_labels_json()
        if n_classes > 0 and len(labels) != n_classes:
            raise ValueError(
                f"labels.json has {len(labels)} labels but model output has {n_classes} classes"
            )

        interpreter.allocate_tensors()

        self.tflite_interpreter = interpreter
        self.tflite_input_details = input_details
        self.tflite_output_details = output_details
        self.model = interpreter
        self.activity_labels = labels
        self.feature_names = [f"window_{i}" for i in range(self._expected_input_len)]

        print("🎉 TFLite model loaded successfully!")
        print(f"🤖 Model type: TFLite (input: {self.tflite_timesteps}x{self.tflite_features})")
        print(f"🔢 Send exactly {self._expected_input_len} floats")

    def predict(self, features, input_format: str | None = None):
        """Predict activity from raw window input expected by the TFLite model."""
        if input_format == "features":
            raise ValueError(
                "Feature-vector input is not supported. Send raw sensor window values for the TFLite model."
            )

        values = np.array(features, dtype=np.float32).flatten()
        if values.size < self._expected_input_len:
            raise ValueError(
                f"Expected at least {self._expected_input_len} values, got {values.size}."
            )
        if values.size > self._expected_input_len:
            values = values[: self._expected_input_len]

        window = values.reshape(1, self.tflite_timesteps, self.tflite_features)

        # Per-window normalization across timesteps.
        mean = window.mean(axis=1, keepdims=True)
        std = window.std(axis=1, keepdims=True)
        std[std == 0] = 1.0
        window = (window - mean) / std

        input_index = self.tflite_input_details[0]["index"]
        output_index = self.tflite_output_details[0]["index"]

        self.tflite_interpreter.set_tensor(input_index, window.astype(np.float32))
        self.tflite_interpreter.invoke()
        probs = self.tflite_interpreter.get_tensor(output_index)[0]

        pred_idx = int(np.argmax(probs))
        confidence = float(probs[pred_idx])
        activity = self.activity_labels[pred_idx]
        probs_dict = {self.activity_labels[i]: float(probs[i]) for i in range(len(probs))}

        return {
            "activity": activity,
            "confidence": confidence,
            "prediction": pred_idx,
            "probabilities": probs_dict,
        }
