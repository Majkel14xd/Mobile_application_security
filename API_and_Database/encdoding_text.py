import base64
import json

# Zakodowany ciąg w Base64
encoded_string = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3QurO0ABXNyABNqYXZhLnV0aWwuQXJyYXlMaXN0eIHSHZnHYZ0DAAFJAARzaXpleHAAAAABdwQAAAAB\ndAANZHNhZGFzZHNhZGFzZHg="
encoded_string = encoded_string.replace("\n", "")  # Usuń znak nowej linii

# Dekodowanie Base64
decoded_bytes = base64.b64decode(encoded_string)

# Wyodrębnienie części tekstowej i próba konwersji do JSON
try:
    # Konwersja bajtów na tekst
    text_part = decoded_bytes.decode("utf-8", errors="ignore")
    print("Dekodowany tekst:", text_part)

    # Przykładowy JSON - dopasowanie danych ręcznie (jeśli struktura pozwala)
    example_json = {
        "message": "This is the prefix for a list.",
        "data": "dsadasdsadasd"
    }
    print("Przykładowy JSON:", json.dumps(example_json, indent=4))
except Exception as e:
    print("Błąd:", e)
