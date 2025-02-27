from flask import Flask, jsonify, request
import sqlite3
import logging

app = Flask(__name__)

# logi
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# globalna zmienna na token
saved_token = None


def is_dart_user_agent():
    """Sprawdza, czy żądanie pochodzi z aplikacji Dart."""
    user_agent = request.headers.get("User-Agent")
    return user_agent == "Dart/3.6 (dart:io)"


def get_token():
    """Pobiera token z nagłówka Authorization."""
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        return None
    return auth_header.split(" ")[1]


def get_db():
    """Zwraca połączenie z bazą danych SQLite."""
    conn = sqlite3.connect("database.db")
    conn.row_factory = sqlite3.Row
    return conn


@app.route("/api/data", methods=["GET"])
def get_data():
    global saved_token

    token = get_token()
    if not token:
        return jsonify({"error": "Token missing or invalid"}), 400

    # sprawdzenie czy zadanie idzie z darta
    if is_dart_user_agent():
        if saved_token is None:
            saved_token = token
            logger.info("Token zapisany z aplikacji Dart.")
        elif token != saved_token:
            saved_token = token  # aktualizacja tokenu
            logger.info("Token zaktualizowany z aplikacji Dart.")

    # zgodnosc tokenu
    if token != saved_token:
        return jsonify({"error": "Unauthorized. Invalid token."}), 401

    # pobieranie danych z bazy
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM data")
    rows = cursor.fetchall()
    conn.close()

    response_data = [{"id": row["id"], "message": row["message"]} for row in rows]
    logger.debug(f"Returned {len(response_data)} rows.")
    return jsonify(response_data)


@app.route("/api/data", methods=["POST"])
def save_data():
    global saved_token

    token = get_token()
    if not token:
        return jsonify({"error": "Token missing or invalid"}), 400

    # sprawdzenie czy zadanie idzie z darta
    if is_dart_user_agent():
        if saved_token is None:
            saved_token = token
            logger.info("Token zapisany z aplikacji Dart.")
        elif token != saved_token:
            saved_token = token  # aktualizacja tokenu
            logger.info("Token zaktualizowany z aplikacji Dart.")

    # zgodnosc tokenu
    if token != saved_token:
        return jsonify({"error": "Unauthorized. Invalid token."}), 401

    # pobieranie danych z zadania
    plain_data = request.json.get("note")
    if not plain_data:
        return jsonify({"error": "No data provided"}), 400

    # zapis w bazie
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("INSERT INTO data (message) VALUES (?)", (plain_data,))
    conn.commit()
    conn.close()

    logger.info("Data saved successfully!")
    return jsonify({"message": "Data saved successfully!"})


@app.route("/api/data/<string:note>", methods=["DELETE"])
def delete_data(note):
    global saved_token

    token = get_token()
    if not token:
        return jsonify({"error": "Token missing or invalid"}), 400

    if is_dart_user_agent():
        if saved_token is None:
            saved_token = token
            logger.info("Token zapisany z aplikacji Dart.")
        elif token != saved_token:
            saved_token = token  # aktualizacja tokenu
            logger.info("Token zaktualizowany z aplikacji Dart.")

    if token != saved_token:
        return jsonify({"error": "Unauthorized. Invalid token."}), 401

    # usuniecie notatki po tresci/id
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM data WHERE message = ?", (note,))
    conn.commit()

    if cursor.rowcount == 0:
        conn.close()
        return jsonify({"error": "Note not found"}), 404

    conn.close()
    logger.info(f"Data with note '{note}' deleted successfully!")
    return jsonify({"message": f"Data with note '{note}' deleted successfully!"})


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=5000,
        ssl_context=("Certs/cert.pem", "Certs/private_key.pem"),
        debug=True,
    )
