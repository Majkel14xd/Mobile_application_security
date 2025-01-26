import base64
from xml.etree import ElementTree as ET

# Twój XML
xml_data = '''<?xml version='1.0' encoding='utf-8' standalone='yes' ?>
<map>
    <string name="flutter.notes">VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3QurO0ABXNyABNqYXZhLnV0aWwuQXJyYXlMaXN0eIHSHZnHYZ0DAAFJAARzaXpleHAAAAACdwQAAAAC&#10;dAAJTm90YXRrYSAxdAAJTm90YXRrYSAyeA==&#10;    </string>
    <string name="flutter.token">9dec88f3-677e-4f22-83ea-de90f67070a8</string>
</map>'''

# Parsowanie XML
root = ET.fromstring(xml_data)

# Pobieranie zakodowanego ciągu base64
encoded_notes = root.find(".//string[@name='flutter.notes']").text

# Dekodowanie base64
decoded_notes = base64.b64decode(encoded_notes)

# Wyświetlanie zdekodowanych danych binarnych
print(decoded_notes)
