import numpy as np
import os
from scipy import signal

def load_uci_raw(data_path):
    """Load UCI HAR dataset from train/test folders."""
    def load_files(subset):
        acc_x = np.loadtxt(os.path.join(data_path, subset, 'Inertial Signals',
                                         'total_acc_x_'+subset+'.txt'))
        acc_y = np.loadtxt(os.path.join(data_path, subset, 'Inertial Signals',
                                         'total_acc_y_'+subset+'.txt'))
        acc_z = np.loadtxt(os.path.join(data_path, subset, 'Inertial Signals',
                                         'total_acc_z_'+subset+'.txt'))
        labels = np.loadtxt(os.path.join(data_path, subset, 'y_'+subset+'.txt'))
        # Stack axes: shape (n_windows, 128, 3)
        data = np.stack([acc_x, acc_y, acc_z], axis=-1)
        return data, labels
    X_train, y_train = load_files('train')
    X_test, y_test = load_files('test')
    X = np.vstack([X_train, X_test])
    y = np.concatenate([y_train, y_test])
    return X, y

def normalize_window(window):
    mean = window.mean(axis=0, keepdims=True)
    std = window.std(axis=0, keepdims=True)
    std[std == 0] = 1.0
    return (window - mean) / std

def map_uci_activity(act):
    # UCI labels: 1 WALKING, 2 WALKING_UPSTAIRS, 3 WALKING_DOWNSTAIRS,
    # 4 SITTING, 5 STANDING, 6 LAYING
    mapping = {
        1: 0,  # Walking
        2: 2,  # Upstairs
        3: 3,  # Downstairs
        4: 4,  # Sitting
        5: 5,  # Standing
        6: 6,  # Laying
    }
    return mapping.get(act, -1)

def process_uci(data_path, target_fs=20, window_size=40):
    """Resample UCI windows to target frequency and fixed window size."""
    X, y = load_uci_raw(data_path)
    original_fs = 50
    duration = X.shape[1] / original_fs  # 128/50 = 2.56 sec
    new_length = int(duration * target_fs)  # ~51 samples
    windows = []
    labels = []
    for i in range(len(X)):
        # Resample each axis
        resampled = np.array([signal.resample(X[i, :, j], new_length) for j in range(3)]).T
        # Now we have length new_length (~51). Adjust to exactly window_size (40)
        if new_length >= window_size:
            # Take central part
            start = (new_length - window_size) // 2
            window = resampled[start:start+window_size]
        else:
            # Pad with zeros
            pad = window_size - new_length
            window = np.pad(resampled, ((0, pad), (0, 0)), mode='constant')
        # Normalize
        window = normalize_window(window)
        label = map_uci_activity(y[i])
        if label != -1:
            windows.append(window)
            labels.append(label)
    return np.array(windows), np.array(labels)
