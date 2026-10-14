import os
import random
import joblib
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import SGDClassifier
from sklearn.pipeline import make_pipeline


SCENE_QUESTION_EXAMPLES = (
    "what do you see",
    "what can you see",
    "what is in",
    "what s in",
    "what is happening",
    "explain the scenario",
    "explain this scenario",
    "explain scenario",
    "describe the scene",
    "describe scenario",
    "describe the input",
    "describe input",
    "describe the output",
    "describe output",
    "explain the input",
    "explain input",
    "explain the output",
    "explain output",
    "explain this image",
    "what does this image show",
    "what is shown",
    "what does this result mean",
    "what does the output mean",
    "input and output",
    "input output",
    "what did it detect",
    "what has been detected",
    "detection result",
    "detection output",
    "explain the output",
    "explain this output",
    "interpret the output",
    "explain the results",
    "explain these results",
    "interpret these results",
    "analyze this input",
    "what is the input",
    "what is the output",
)

OCR_QUESTION_EXAMPLES = (
    "what did ocr read",
    "what does ocr say",
    "what does ocr show",
    "ocr result",
    "what is the ocr result",
    "what did it read",
    "recognized text",
    "extracted text",
    "what text was read",
    "what text is visible",
    "read the text",
)


def generate_dataset():
    data = []
    
    # 1. COUNT INTENT
    count_templates = [
        "how many {obj} do you see",
        "how many {obj} are there",
        "count the {obj}",
        "what is the number of {obj}",
        "can you count {obj}",
        "are there any {obj}",
        "tell me how many {obj} you spot",
        "number of {obj}"
    ]
    objects = ["people", "cats", "dogs", "cars", "bottles", "chairs", "laptops", "phones", "books", "cups", "potted plants"]
    for obj in objects:
        for template in count_templates:
            for _ in range(50):
                # Add some variations with punctuation and slight noise
                text = template.format(obj=obj)
                if random.random() > 0.5:
                    text += "?"
                data.append((text, "count"))
    
    # 2. DESCRIBE INTENT
    describe_templates = [
        "what do you see",
        "describe the scene",
        "what is in front of you",
        "tell me what you see",
        "what is this",
        "can you describe this",
        "what objects are visible",
        "what is happening here",
        "describe what is in the camera",
        "show me what you found",
        "identify the objects"
    ]
    for template in describe_templates:
        for _ in range(200):
            text = template
            if random.random() > 0.5:
                text += "?"
            data.append((text, "describe"))

    # Seed the classifier with the question patterns handled by the assistants.
    for phrase in SCENE_QUESTION_EXAMPLES:
        for _ in range(50):
            prefix = random.choice(("", "please ", "can you "))
            suffix = random.choice(("", "?", " please?"))
            data.append((f"{prefix}{phrase}{suffix}", "describe"))
    for phrase in OCR_QUESTION_EXAMPLES:
        for _ in range(50):
            prefix = random.choice(("", "please ", "can you "))
            suffix = random.choice(("", "?", " please?"))
            data.append((f"{prefix}{phrase}{suffix}", "ocr"))

    # 3. LOCATE INTENT
    locate_templates = [
        "where is the {obj}",
        "where can i find the {obj}",
        "locate the {obj}",
        "can you find the {obj}",
        "what is the location of the {obj}",
        "show me where the {obj} is",
        "is the {obj} on the left or right",
        "point out the {obj}"
    ]
    for obj in objects:
        for template in locate_templates:
            for _ in range(50):
                text = template.format(obj=obj)
                if random.random() > 0.5:
                    text += "?"
                data.append((text, "locate"))

    # 4. SAFETY INTENT
    safety_templates = [
        "is it safe",
        "are there any dangers",
        "do you see any dangerous objects",
        "is there a threat",
        "is the scene safe",
        "check for weapons",
        "is there a knife or gun",
        "any hazards",
        "is this safe"
    ]
    for template in safety_templates:
        for _ in range(200):
            text = template
            if random.random() > 0.5:
                text += "?"
            data.append((text, "safety"))
            
    # 5. UNKNOWN/GENERAL
    general_templates = [
        "hello", "hi", "hey", "who are you", "what is your name", 
        "what is this app", "how does this work", "wht is this app",
        "what can you do", "help", "what are you doing", 
        "what r u doing", "wt r u doing", "what u doing", 
        "sup", "what's up", "how are you", "doing what"
    ]
    for template in general_templates:
        for _ in range(100):
            data.append((template, "general"))
            
    random.shuffle(data)
    X, y = zip(*data)
    return list(X), list(y)

def train():
    print("Generating synthetic dataset of thousands of chats...")
    X, y = generate_dataset()
    print(f"Dataset size: {len(X)} samples.")
    
    print("Training intent classifier (TF-IDF + SGD)...")
    model = make_pipeline(
        TfidfVectorizer(ngram_range=(1, 3)),
        SGDClassifier(loss='log_loss', max_iter=1000, tol=1e-3, random_state=42)
    )
    
    model.fit(X, y)
    print("Training complete! Accuracy on training set:", model.score(X, y))
    
    os.makedirs("ai_model", exist_ok=True)
    model_path = "ai_model/chatbot_intent_model.pkl"
    joblib.dump(model, model_path)
    print(f"Model saved to {model_path}")

if __name__ == "__main__":
    train()
