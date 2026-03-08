import os
from datetime import timedelta

from dotenv import load_dotenv


BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
PROJECT_ROOT = os.path.abspath(os.path.join(BASE_DIR, ".."))

# Load project .env by default
load_dotenv(os.path.join(PROJECT_ROOT, ".env"))


def _normalized_database_url() -> str:
    raw = os.getenv("DATABASE_URL", f"sqlite:///{os.path.join(BASE_DIR, 'harmony.db')}")
    if raw.startswith("postgres://"):
        return raw.replace("postgres://", "postgresql://", 1)
    return raw


class BaseConfig:
    """Base configuration shared across environments."""

    # Core
    SECRET_KEY = os.getenv("SECRET_KEY", "harmony-secret-key")
    DEBUG = False
    TESTING = False

    # Database
    SQLALCHEMY_DATABASE_URI = _normalized_database_url()
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # CORS
    CORS_ORIGINS = os.getenv("CORS_ORIGINS", "*").split(",")

    # Model / ML
    MODEL_DIR = os.getenv(
        "MODEL_DIR",
        os.getenv("MODEL_PATH", os.path.join(PROJECT_ROOT, "ml_models")),
    )

    # Sessions / security
    PERMANENT_SESSION_LIFETIME = timedelta(days=7)

    # Misc
    JSON_SORT_KEYS = False


class DevelopmentConfig(BaseConfig):
    DEBUG = True


class ProductionConfig(BaseConfig):
    DEBUG = False


class TestingConfig(BaseConfig):
    TESTING = True
    SQLALCHEMY_DATABASE_URI = "sqlite:///:memory:"


config_by_name = {
    "development": DevelopmentConfig,
    "production": ProductionConfig,
    "testing": TestingConfig,
}


def get_config():
    """Return the appropriate config class based on FLASK_ENV."""
    env = os.getenv("FLASK_ENV", "development").lower()
    return config_by_name.get(env, DevelopmentConfig)
