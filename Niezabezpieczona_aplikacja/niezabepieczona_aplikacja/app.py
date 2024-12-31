from flask import Flask, jsonify, request
import sqlite3
import logging

app = Flask(__name__)

# Set up logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

def get_db():
    """Connect to the SQLite database."""
    conn = sqlite3.connect('database.db')
    conn.row_factory = sqlite3.Row
    return conn

@app.route('/api/data', methods=['GET'])
def get_data():
    """Retrieve data from the database."""
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM data')
    rows = cursor.fetchall()
    conn.close()
    
    # Return plain data, as HTTPS will handle encryption automatically
    response_data = [{'id': row['id'], 'message': row['message']} for row in rows]
    
    logger.debug(f"Returned {len(response_data)} rows.")
    return jsonify(response_data)

@app.route('/api/data', methods=['POST'])
def save_data():
    """Save data into the database."""
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
    app.run(host='0.0.0.0', port=5000)
    #app.run(host='0.0.0.0', port=5000, ssl_context=('cert.pem', 'key.pem'))
