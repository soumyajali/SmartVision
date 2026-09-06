import re

with open("app.py", "r", encoding="utf-8") as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    # Fix radio button array strings
    line = re.sub(r'^\s*"\s+(.*?)",?\s*$', lambda m: line.replace('" ' + m.group(1), '"' + m.group(1)), line)
    # Fix if statements
    line = re.sub(r'if page (==|in) \[?"\s+(.*?)"', lambda m: line.replace('" ' + m.group(2), '"' + m.group(2)), line)
    line = re.sub(r'elif page == "\s+(.*?)"', lambda m: line.replace('" ' + m.group(1), '"' + m.group(1)), line)
    new_lines.append(line)

with open("app.py", "w", encoding="utf-8") as f:
    f.writelines(new_lines)
