import tensorflow as tf
import numpy as np
import json
import os

# Load the trained model
model = tf.keras.models.load_model('models/har_model.h5')
print("Model loaded successfully.")

# Configure converter for LSTM support
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.target_spec.supported_ops = [
    tf.lite.OpsSet.TFLITE_BUILTINS,
    tf.lite.OpsSet.SELECT_TF_OPS
]
converter._experimental_lower_tensor_list_ops = False

# Convert and save
tflite_model = converter.convert()
with open('models/har_model_fixed.tflite', 'wb') as f:
    f.write(tflite_model)
print("TFLite model saved to models/har_model_fixed.tflite")

# Optional: quantized version
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_quant_model = converter.convert()
with open('models/har_model_quant_fixed.tflite', 'wb') as f:
    f.write(tflite_quant_model)
print("Quantized TFLite model saved to models/har_model_quant_fixed.tflite")