import os

from dotenv import load_dotenv
from flask import Flask
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy


db = SQLAlchemy()


def _normalize_database_url(database_url: str) -> str:
    if database_url.startswith("postgres://"):
        return database_url.replace("postgres://", "postgresql://", 1)
    return database_url


def create_app():
    app = Flask(__name__)
    CORS(app)

    basedir = os.path.abspath(os.path.dirname(__file__))
    project_root = os.path.abspath(os.path.join(basedir, "..", ".."))
    backend_root = os.path.abspath(os.path.join(basedir, ".."))

    # Load env from project root first, then backend-local override.
    load_dotenv(os.path.join(project_root, ".env"))
    load_dotenv(os.path.join(backend_root, ".env"), override=True)

    instance_path = os.path.join(backend_root, "instance")
    os.makedirs(instance_path, exist_ok=True)

    default_sqlite = f"sqlite:///{os.path.join(instance_path, 'harmony.db')}"
    database_url = os.environ.get("DATABASE_URL", default_sqlite)

    app.config["SQLALCHEMY_DATABASE_URI"] = _normalize_database_url(database_url)
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
    app.config["SECRET_KEY"] = os.environ.get("SECRET_KEY", "harmony-secret-key")
    app.config["MODEL_PATH"] = os.environ.get(
        "MODEL_PATH", os.path.join(project_root, "ml_models")
    )

    db.init_app(app)

    with app.app_context():
        db.create_all()

    # Register blueprints
    from app.routes import export, insights, predict, sessions, stats

    app.register_blueprint(predict.bp, url_prefix="/api")
    app.register_blueprint(sessions.bp, url_prefix="/api")
    app.register_blueprint(stats.bp, url_prefix="/api")
    app.register_blueprint(insights.bp, url_prefix="/api")
    app.register_blueprint(export.bp, url_prefix="/api")

    # Load model once at startup
    from app.services.model_service import init_model

    init_model(app)

    return app
