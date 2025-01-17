import base64

# Zakodowane dane (nazwa klucza i wartość)
key_encoded = "VGhpcyBpcyB0aGUga2V5IGZvciBhIHNlY3VyZSBzdG9yYWdlIEFFUyBLZXkK"
value_encoded = (
    "HcquUUyI/aRxkxyBntriO+vXL6qnLeK8zSmCASOsvp8p5afmLfAHpsDlRDBPx8cNc1ZoI/lQX5xG"
    "hxTVRyMJBvBH+wQTgsgHVKfWLuPG5mmmxJy3zTR2Ag3df2IHbgBs9OQnb30E2w+TVCuPjHCPO/jZ"
    "6gItjB1YO7MUqBPiY4exdMxGdZY7XECOyG25yheRQChL7q6POmQ7nhtm7r1E/mmiuNfhX0RbeqdD"
    "5KF40Jqu84qElwf2XgwH3RdCmlptqLhLa1CoKfi2/VWwYbFV/y31rO/uK1sGotph0kMsIjHncjmh"
    "0n29k6EZl4pLTWlTsQqzVu2XYb7u4J5LEG31bw=="
)

# Dekodowanie nazwy klucza
key_decoded = base64.b64decode(key_encoded).decode("utf-8")
print("Odczytana nazwa klucza:", key_decoded)

# Dekodowanie wartości
value_decoded = base64.b64decode(value_encoded).decode("utf-8", errors="ignore")
print("Odczytana wartość:", value_decoded)
