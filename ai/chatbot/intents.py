import re

def parse_intent(query: str):
    query = query.lower()
    
    # 1. Counting Intent
    count_match = re.search(r"how many (\w+)", query) or re.search(r"count (\w+)", query)
    if count_match:
        target = count_match.group(1).rstrip('s')
        return "count_object", {"target": target}
    
    # 2. Scene Description
    if "what do you see" in query or "describe" in query or "visible" in query:
        return "describe_scene", {}
        
    # 3. Object Search
    search_match = re.search(r"do you see a (\w+)", query) or re.search(r"is there a (\w+)", query)
    if search_match:
        target = search_match.group(1).rstrip('s')
        return "search_object", {"target": target}
        
    # 4. Face Recognition
    if "who" in query:
        return "recognize_person", {}
        
    # 5. OCR
    if "text" in query or "read" in query:
        return "read_ocr", {}
        
    return "unknown", {}
