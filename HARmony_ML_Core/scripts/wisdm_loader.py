import pandas as pd
import numpy as np
from scipy import signal

def load_wisdm_raw(filepath):
    """Load raw WISDM data (comma-separated, each line ends with semicolon)."""
    col_names = ['user', 'activity', 'timestamp', 'x', 'y', 'z']
    # Read all columns as strings to allow cleaning
    data = pd.read_csv(filepath,
                       header=None,
                       names=col_names,
                       sep=',',
                       dtype=str,
                       on_bad_lines='skip',
                       engine='python')
    print(f"WISDM raw rows loaded: {len(data)}")
    # Remove trailing semicolon from every column (just in case)
    for col in col_names:
        data[col] = data[col].str.rstrip(';')
    # Convert numeric columns
    num_cols = ['timestamp', 'x', 'y', 'z']
    for col in num_cols:
        data[col] = pd.to_numeric(data[col], errors='coerce')
    # Drop rows where conversion failed
    data.dropna(inplace=True)
    return data

def segment_data(data, window_size, step_size):
    """Convert continuous data into windows."""
    segments = []
    for i in range(0, len(data) - window_size + 1, step_size):
        segments.append(data[i:i+window_size])
    return np.array(segments)

def normalize_window(window):
    """Z-score normalize each channel."""
    mean = window.mean(axis=0, keepdims=True)
    std = window.std(axis=0, keepdims=True)
    std[std == 0] = 1.0
    return (window - mean) / std

def map_wisdm_activity(act):
    mapping = {
        'Walking': 0,
        'Jogging': 1,
        'Upstairs': 2,
        'Downstairs': 3,
        'Sitting': 4,
        'Standing': 5
    }
    return mapping.get(act, -1)

def process_wisdm(filepath, window_size=40, step=20):
    """Main function to process WISDM and return windows and labels."""
    df = load_wisdm_raw(filepath)
    if len(df) == 0:
        print("WARNING: No data loaded from WISDM file.")
        return np.array([]), np.array([])

    windows = []
    labels = []
    for user, group in df.groupby('user'):
        group = group.sort_values('timestamp')
        acc = group[['x', 'y', 'z']].values.astype(np.float32)
        # Segment
        segs = segment_data(acc, window_size, step)
        for i, seg in enumerate(segs):
            start_idx = i * step
            end_idx = start_idx + window_size
            act_series = group.iloc[start_idx:end_idx]['activity']
            if len(act_series) == 0:
                continue
            act = act_series.mode()
            if len(act) == 0:
                continue
            act = act.iloc[0]
            label = map_wisdm_activity(act)
            if label != -1:
                seg_norm = normalize_window(seg)
                windows.append(seg_norm)
                labels.append(label)
    return np.array(windows), np.array(labels)