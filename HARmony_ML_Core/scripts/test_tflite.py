import numpy as np
import tensorflow as tf
import os
import glob

def find_flex_lib():
    """Search for the Flex delegate shared library in the virtual environment."""
    # Common patterns for the Flex library
    patterns = [
        '**/libtensorflowlite_flex.so',
        '**/_flex_delegate.so',
        '**/tensorflow/lite/experimental/acceleration/compatibility/*.so',
    ]
    for pattern in patterns:
        matches = glob.glob(os.path.join(os.path.dirname(tf.__file__), pattern), recursive=True)
        if matches:
            return matches[0]
    return None

def load_flex_delegate():
    """Try to load the Flex delegate, returns None if not found."""
    lib_path = find_flex_lib()
    if lib_path and os.path.exists(lib_path):
        print(f"Found Flex delegate: {lib_path}")
        try:
            return tf.lite.experimental.load_delegate(lib_path)
        except Exception as e:
            print(f"Failed to load delegate: {e}")
    else:
        print("Flex delegate library not found. Trying AUTO resolver...")
    return None

def main():
    # Attempt to load Flex delegate
    delegate = load_flex_delegate()
    if delegate:
        interpreter = tf.lite.Interpreter(
            model_path='models/har_model_fixed.tflite',
            experimental_delegates=[delegate]
        )
    else:
        # Fallback to AUTO resolver (may still fail if lib missing)
        interpreter = tf.lite.Interpreter(
            model_path='models/har_model_fixed.tflite',
            experimental_op_resolver_type=tf.lite.experimental.OpResolverType.AUTO
        )

    interpreter.allocate_tensors()

    # Get input/output details
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    # Create random input matching model shape (1, 40, 3)
    input_data = np.random.randn(1, 40, 3).astype(np.float32)
    interpreter.set_tensor(input_details[0]['index'], input_data)
    interpreter.invoke()
    output = interpreter.get_tensor(output_details[0]['index'])

    print("Inference output shape:", output.shape)
    print("Sample output (class probabilities):", output[0])

if __name__ == '__main__':
    main()