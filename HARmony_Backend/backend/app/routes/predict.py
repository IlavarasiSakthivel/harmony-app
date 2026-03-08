from flask import Blueprint, request, jsonify

from app.services.model_service import predict as run_predict, is_loaded

bp = Blueprint("predict", __name__)


@bp.route("/predict", methods=["POST"])
def predict():
    data = request.get_json() or {}
    sensor_data = data.get("sensor_data")
    if sensor_data is None:
        return jsonify({"success": False, "error": "Missing sensor_data"}), 400
    if not is_loaded():
        return jsonify({"success": False, "error": "Model not loaded"}), 503
    try:
        out = run_predict(sensor_data)
        return jsonify({
            "success": True,
            "prediction": {
                "activity": out["activity"],
                "confidence": out["confidence"],
                "probabilities": out["probabilities"],
                "inference_time_ms": out.get("inference_time_ms"),
                "movement_intensity": out["movement_intensity"],
                "energy_level": out["energy_level"],
            },
        })
    except ValueError as e:
        return jsonify({"success": False, "error": str(e)}), 400
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500
