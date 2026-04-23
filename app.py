from flask import Flask, request, jsonify
import joblib

app = Flask(__name__)

# Load model
model = joblib.load("category_model.pkl")
vectorizer = joblib.load("vectorizer.pkl")


def rule_based_category(text):
    t = text.lower()

    if "zomato" in t or "swiggy" in t:
        return "Food"
    if "uber" in t or "ola" in t:
        return "Travel"
    if "electricity" in t or "bill" in t:
        return "Bills"
    if "amazon" in t or "flipkart" in t:
        return "Shopping"

    return None


def detect_type(text):
    t = text.lower()

    if "credited" in t or "received" in t:
        return "credit"
    elif "debited" in t or "spent" in t or "paid" in t:
        return "debit"
    return "unknown"


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"}), 200


@app.route("/predict", methods=["POST"])
def predict():
    data = request.get_json(silent=True) or {}
    text = str(data.get("sms", "")).strip()

    if not text:
        return jsonify({"error": "Missing sms field"}), 400

    # Rule-based first
    rule = rule_based_category(text)

    if rule:
        category = rule
    else:
        vec = vectorizer.transform([text])
        category = model.predict(vec)[0]

    tx_type = detect_type(text)

    return jsonify({
        "category": category,
        "type": tx_type
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, threaded=True)
