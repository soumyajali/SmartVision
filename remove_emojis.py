import re

def remove_emojis(text):
    # Regex for common emoji ranges
    emoji_pattern = re.compile(
        "["
        u"\U0001f600-\U0001f64f"  # emoticons
        u"\U0001f300-\U0001f5ff"  # symbols & pictographs
        u"\U0001f680-\U0001f6ff"  # transport & map symbols
        u"\U0001f1e0-\U0001f1ff"  # flags (iOS)
        u"\U00002702-\U000027b0"
        u"\U000024C2-\U0001F251"
        u"\U0001F900-\U0001FAFF"  # supplemental symbols
        u"\u2600-\u26ff"          # miscellaneous symbols
        u"\u2700-\u27bf"          # dingbats
        u"\u2300-\u23ff"          # miscellaneous technical
        u"\u2B50"                 # star
        u"\uFE0F"                 # variation selector (often appended to emojis)
        "]+", flags=re.UNICODE)
    return emoji_pattern.sub(r'', text)

with open("app.py", "r", encoding="utf-8") as f:
    content = f.read()

cleaned = remove_emojis(content)
# Clean up multiple spaces that might result from removing emojis
cleaned = cleaned.replace('  ', ' ')

with open("app.py", "w", encoding="utf-8") as f:
    f.write(cleaned)

print("Removed emojis from app.py")
