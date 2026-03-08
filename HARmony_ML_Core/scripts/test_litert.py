from ai_edge_litert.interpreter import Interpreter
import numpy as np
import json

# Load model
interpreter = Interpreter(model_path='models/har_model_fixed.tflite')
interpreter.allocate_tensors()

# Load labels
with open('models/labels.json') as f:
    labels = json.load(f)

# Dummy input (1, 40, 3)
input_data = np.random.randn(1, 40, 3).astype(np.float32)
interpreter.set_tensor(interpreter.get_input_details()[0]['index'], input_data)
interpreter.invoke()
output = interpreter.get_tensor(interpreter.get_output_details()[0]['index'])

pred_class = np.argmax(output[0])
print("Predicted:", labels[pred_class])