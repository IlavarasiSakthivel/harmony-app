import numpy as np
import os
import sys
sys.path.append(os.path.dirname(__file__))
from wisdm_loader import process_wisdm
from uci_loader import process_uci

def main():
    wisdm_path = 'data/WISDM_ar_latest/WISDM_ar_v1.1_raw.txt'
    uci_path = 'data/UCI HAR Dataset/UCI HAR Dataset'
    output_dir = 'processed_data'
    os.makedirs(output_dir, exist_ok=True)

    print("Processing WISDM...")
    X_w, y_w = process_wisdm(wisdm_path, window_size=40, step=20)
    print(f"WISDM: {X_w.shape[0]} windows")

    print("Processing UCI HAR...")
    X_u, y_u = process_uci(uci_path, target_fs=20, window_size=40)
    print(f"UCI: {X_u.shape[0]} windows")

    # Check if both datasets have data before stacking
    if X_w.shape[0] == 0:
        print("WARNING: No WISDM windows. Using only UCI data.")
        X = X_u
        y = y_u
    elif X_u.shape[0] == 0:
        print("WARNING: No UCI windows. Using only WISDM data.")
        X = X_w
        y = y_w
    else:
        X = np.vstack([X_w, X_u])
        y = np.concatenate([y_w, y_u])

    print(f"Total windows: {X.shape[0]}, classes: {np.unique(y)}")

    np.save(os.path.join(output_dir, 'X.npy'), X)
    np.save(os.path.join(output_dir, 'y.npy'), y)
    print("Saved to processed_data/")

if __name__ == '__main__':
    main()