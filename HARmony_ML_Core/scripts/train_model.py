import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models
from sklearn.model_selection import train_test_split
from sklearn.decomposition import PCA
import keras_tuner as kt
import os
import json

# ---------------------------
# 1. Load preprocessed data
# ---------------------------
print("Loading data...")
X = np.load('processed_data/X.npy')
y = np.load('processed_data/y.npy')

print(f"X shape: {X.shape}, y shape: {y.shape}, classes: {np.unique(y)}")

# Split into train/test
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, stratify=y, random_state=42
)
print(f"Train: {X_train.shape}, Test: {X_test.shape}")

# ---------------------------
# 2. Optional PCA
# ---------------------------
# Note: PCA flattens the time dimension. For CNN-LSTM we keep the original shape.
# Uncomment the following block if you want to experiment with PCA + a dense network.
# But for the CNN-LSTM we will skip PCA.
USE_PCA = False  # Set to True if you want to try PCA with a different model

if USE_PCA:
    # Flatten windows: (samples, time_steps * channels)
    ns, ts, ch = X_train.shape
    X_train_flat = X_train.reshape(ns, -1)
    X_test_flat = X_test.reshape(X_test.shape[0], -1)

    # Apply PCA (retain 95% variance)
    pca = PCA(n_components=0.95)
    X_train_pca = pca.fit_transform(X_train_flat)
    X_test_pca = pca.transform(X_test_flat)
    print(f"PCA reduced dimensions: {X_train_pca.shape[1]}")
    # For a dense model, you would use X_train_pca, X_test_pca.
else:
    # Keep original shape for CNN-LSTM
    X_train = X_train
    X_test = X_test

# ---------------------------
# 3. Hyperparameter tuning with Keras Tuner
# ---------------------------
def build_model(hp):
    model = models.Sequential()
    model.add(layers.Input(shape=(40, 3)))  # fixed input shape

    # Conv1D block
    hp_filters = hp.Int('filters', min_value=32, max_value=128, step=32)
    hp_kernel = hp.Int('kernel', min_value=3, max_value=7, step=2)
    model.add(layers.Conv1D(filters=hp_filters, kernel_size=hp_kernel,
                             activation='relu', padding='same'))
    model.add(layers.Dropout(hp.Float('dropout1', 0.2, 0.5, step=0.1)))
    model.add(layers.Conv1D(filters=hp_filters, kernel_size=hp_kernel,
                             activation='relu', padding='same'))
    model.add(layers.MaxPooling1D(pool_size=2))

    # LSTM layers
    hp_lstm_units = hp.Int('lstm_units', min_value=32, max_value=128, step=32)
    model.add(layers.LSTM(units=hp_lstm_units, return_sequences=True))
    model.add(layers.LSTM(units=hp_lstm_units))

    # Dense head
    model.add(layers.Dense(hp_lstm_units, activation='relu'))
    model.add(layers.Dropout(hp.Float('dropout2', 0.3, 0.6, step=0.1)))
    model.add(layers.Dense(7, activation='softmax'))  # 7 classes

    hp_lr = hp.Choice('learning_rate', values=[1e-2, 1e-3, 1e-4])
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=hp_lr),
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy']
    )
    return model

# If you want to skip tuning and just train with default params, set TUNE = False
TUNE = True

if TUNE:
    tuner = kt.RandomSearch(
        build_model,
        objective='val_accuracy',
        max_trials=10,
        executions_per_trial=2,
        directory='tuning_dir',
        project_name='har_tuning'
    )

    print("Starting hyperparameter search...")
    tuner.search(X_train, y_train, epochs=20, validation_split=0.2,
                 batch_size=32, verbose=1)

    # Get best hyperparameters
    best_hps = tuner.get_best_hyperparameters(num_trials=1)[0]
    print("\nBest hyperparameters found:")
    for param in ['filters', 'kernel', 'lstm_units', 'dropout1', 'dropout2', 'learning_rate']:
        print(f"{param}: {best_hps.get(param)}")

    # Build the best model
    model = tuner.hypermodel.build(best_hps)
else:
    # Use a sensible default model
    model = models.Sequential([
        layers.Input(shape=(40, 3)),
        layers.Conv1D(filters=64, kernel_size=3, activation='relu', padding='same'),
        layers.Dropout(0.3),
        layers.Conv1D(filters=64, kernel_size=3, activation='relu', padding='same'),
        layers.MaxPooling1D(pool_size=2),
        layers.LSTM(64, return_sequences=True),
        layers.LSTM(64),
        layers.Dense(64, activation='relu'),
        layers.Dropout(0.5),
        layers.Dense(7, activation='softmax')
    ])
    model.compile(optimizer='adam',
                  loss='sparse_categorical_crossentropy',
                  metrics=['accuracy'])

model.summary()

# ---------------------------
# 4. Train the model
# ---------------------------
print("Training model...")
history = model.fit(
    X_train, y_train,
    validation_split=0.2,
    epochs=50,
    batch_size=32,
    callbacks=[tf.keras.callbacks.EarlyStopping(patience=5, restore_best_weights=True)],
    verbose=1
)

# ---------------------------
# 5. Evaluate on test set
# ---------------------------
test_loss, test_acc = model.evaluate(X_test, y_test, verbose=0)
print(f"\nTest accuracy: {test_acc:.4f}")

# ---------------------------
# 6. Save the model (Keras and TFLite)
# ---------------------------
# Create models directory if it doesn't exist
os.makedirs('models', exist_ok=True)

# Save Keras model
model.save('models/har_model.h5')
print("Keras model saved to models/har_model.h5")

# Convert to TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()
with open('models/har_model.tflite', 'wb') as f:
    f.write(tflite_model)
print("TFLite model saved to models/har_model.tflite")

# Optional: Quantized version (smaller size)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_quant_model = converter.convert()
with open('models/har_model_quant.tflite', 'wb') as f:
    f.write(tflite_quant_model)
print("Quantized TFLite model saved to models/har_model_quant.tflite")

# Save class labels for later use
labels = ['Walking', 'Jogging', 'Upstairs', 'Downstairs', 'Sitting', 'Standing', 'Laying']
with open('models/labels.json', 'w') as f:
    json.dump(labels, f)
print("Labels saved to models/labels.json")