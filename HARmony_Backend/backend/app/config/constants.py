"""
Constants for HAR model: activity labels, normalization params, intensity mapping.
"""

# Expected input: 128 timesteps × 9 features [x, y, z, gx, gy, gz, tx, ty, tz]
EXPECTED_WINDOW_SIZE = 128
EXPECTED_FEATURE_DIM = 9

# Normalization (per-feature mean/std); replace with real values if known
DEFAULT_FEATURE_MEAN = [0.0] * EXPECTED_FEATURE_DIM
DEFAULT_FEATURE_STD = [1.0] * EXPECTED_FEATURE_DIM

# Activity labels (canonical)
ACTIVITY_LABELS = [
    "WALKING",
    "WALKING_UPSTAIRS",
    "WALKING_DOWNSTAIRS",
    "SITTING",
    "STANDING",
    "LAYING",
]

# Movement intensity per activity
ACTIVITY_INTENSITY_MAP = {
    "WALKING": "MEDIUM",
    "WALKING_UPSTAIRS": "HIGH",
    "WALKING_DOWNSTAIRS": "HIGH",
    "SITTING": "LOW",
    "STANDING": "LOW",
    "LAYING": "LOW",
}


def get_intensity_for_activity(activity: str) -> str:
    if not activity:
        return "LOW"
    key = activity.upper()
    return ACTIVITY_INTENSITY_MAP.get(key, "MEDIUM")


def get_energy_level(active_minutes: float) -> str:
    if active_minutes >= 180:
        return "HIGH"
    if active_minutes >= 90:
        return "MODERATE"
    return "LOW"
