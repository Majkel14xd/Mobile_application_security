from flask import Flask, jsonify, request
import sqlite3
import logging

app = Flask(__name__)

# Set up logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Zmienna do przechowywania tokenu
temp_token = None

def is_valid_user_agent():
    user_agent = request.headers.get('User-Agent')
    if not user_agent or "Dart" not in user_agent:
        logger.warning(f"Invalid User-Agent: {user_agent}")
        return False
    return True

def get_db():
    conn = sqlite3.connect('database.db')
    conn.row_factory = sqlite3.Row
    return conn

@app.route('/api/data', methods=['GET'])
def get_data():
    global temp_token  
    # Pobierz token z nagłówka Authorization
    token = request.headers.get('Authorization')
    if is_valid_user_agent():
        temp_token = token

    if not temp_token:
        return jsonify({"error": "Token missing"}), 400
    
    # Sprawdź, czy token jest prawidłowy
    if not temp_token.startswith('Bearer '):
        return jsonify({"error": "Token format is invalid. Expected 'Bearer <token>'"}), 400
    
    temp_token = temp_token.split(' ')[1]  # Wyciągnięcie tokenu po "Bearer"

    if not temp_token:
        return jsonify({"error": "Unauthorized"}), 401

    # Zapisz token w zmiennej tymczasowej (np. w przypadku aplikacji Flutter)
   

    # Jeśli token jest poprawny, kontynuuj pobieranie danych
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM data')
    rows = cursor.fetchall()
    conn.close()

    response_data = [{'id': row['id'], 'message': row['message']} for row in rows]
    
    logger.debug(f"Returned {len(response_data)} rows.")
    return jsonify(response_data)

@app.route('/api/data', methods=['POST'])
def save_data():
    global temp_token  # Użyj zmiennej globalnej do przechowywania tokenu

    # Pobierz token z nagłówka Authorization
    token = request.headers.get('Authorization')
    if is_valid_user_agent():
        temp_token = token

    if not temp_token:
        return jsonify({"error": "Token missing"}), 400
    
    if not temp_token.startswith('Bearer '):
        return jsonify({"error": "Token format is invalid. Expected 'Bearer <token>'"}), 400

    temp_token = temp_token.split(' ')[1]  # Wyciągnięcie tokenu po "Bearer"

    if not temp_token:
        return jsonify({"error": "Unauthorized"}), 401


    plain_data = request.json.get('data')
    if not plain_data:
        return jsonify({"error": "No data provided"}), 400

    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('INSERT INTO data (message) VALUES (?)', (plain_data,))
    conn.commit()
    conn.close()

    logger.info("Data saved successfully!")
    return jsonify({"message": "Data saved successfully!"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, ssl_context=('cert.pem', 'private_key.pem'))
