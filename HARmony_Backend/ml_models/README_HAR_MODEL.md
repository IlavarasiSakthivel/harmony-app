# WISDM HAR model for HARmony Backend

## Recommended model (easy to integrate)

Use the **WISDM-based 2D CNN** from this repo:

- **Repository:** [aakashratha1006/Human-Activity-Recognition](https://github.com/aakashratha1006/Human-Activity-Recognition)
- **Model file:** `model.h5` (Keras weights only)
- **Download:** Clone the repo or download the file:
  - Direct link to raw file:  
    `https://github.com/aakashratha1006/Human-Activity-Recognition/raw/main/model.h5`
  - Or: `git clone https://github.com/aakashratha1006/Human-Activity-Recognition.git` then copy `model.h5` into this folder (`ml_models/`).

## Where to put the file

Place **one** of the following in this directory (`ml_models/`):

| File | Description |
|------|--------------|
| `model.h5` | Weights from aakashratha1006 (recommended). Backend builds the same architecture and loads these weights. |
| `har_model.h5` or `har_model.keras` | Full Keras model (architecture + weights). Use if you export a full model elsewhere. |

## Input expected by the API

- **Length:** 240 floats (80 timesteps × 3 axes: x, y, z).
- **Format:** One window of accelerometer data, e.g.  
  `[x0, y0, z0, x1, y1, z1, … , x79, y79, z79]`.
- **Optional:** If the app sends 300 floats (100×3), the backend uses the first 240.

## Activities (WISDM labels)

The model predicts one of:  
`Walking`, `Jogging`, `Upstairs`, `Downstairs`, `Sitting`, `Standing`.

## Optional: scaler for better accuracy

The model was trained on StandardScaler-normalized data. If you have a scaler fit on the WISDM training set, save it as:

- `har_scaler_wisdm.pkl` (sklearn `StandardScaler` via `joblib`)

and place it in `ml_models/`. If this file is missing, the backend uses per-window standardization (zero mean, unit variance) for the 80×3 window.
