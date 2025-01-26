import base64
from xml.etree import ElementTree as ET

# Twój XML
xml_data = '''<?xml version='1.0' encoding='utf-8' standalone='yes' ?>
<map>
   <string name="VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIHNlY3VyZSBzdG9yYWdlCg_token">rvDboOMIwNJyL2Ygi+mdxEjuswlNjH8CqEem4bsjdpPIryVe2fdDVB9+8V8mpQDyjjr1a+3R6TgD&#10;itnfWZ6J6Q==&#10;   
     </string>
</map>'''

# Parsowanie XML
root = ET.fromstring(xml_data)

# Pobieranie zakodowanego ciągu base64 za pomocą odpowiedniego atrybutu 'name'
encoded_notes = root.find(".//string[@name='VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIHNlY3VyZSBzdG9yYWdlCg_token']").text

# Dekodowanie base64
decoded_notes = base64.b64decode(encoded_notes)

# Wyświetlanie zdekodowanych danych binarnych
print(decoded_notes)
