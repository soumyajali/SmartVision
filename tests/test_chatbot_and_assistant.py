"""
Verification test for Smart Vision Multimodal Assistant & Chatbot
Validates ChatGPT and Gemini-level conversational intelligence,
scene understanding, multi-turn dialogue, safety analysis, and FastAPI integration.
"""

import os
import sys
import requests

# Ensure project root in sys.path
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

from core_utils import VisionChatbot, AIAssistant
from ai.chatbot.smart_assistant import SmartVisionAssistant, get_smart_assistant

passed = 0
total = 0

def check(name, condition, info=""):
    global passed, total
    total += 1
    if condition:
        passed += 1
        print(f"  [PASS] {name} | {info}")
    else:
        print(f"  [FAIL] {name} | {info}")

def run_tests():
    print("=" * 70)
    print("TESTING SMARTVISION ASSISTANT & CHATBOT (CHATGPT & GEMINI CAPABILITIES)")
    print("=" * 70)

    # 1. Direct SmartVisionAssistant Tests
    print("\n--- 1. SmartVisionAssistant Intelligence Engine ---")
    assistant = SmartVisionAssistant()
    
    # 1.1 Greeting
    ans_greet = assistant.ask("Hello! Who are you and what can you do?")
    check("Greeting & Identity Response", "SmartVision AI" in ans_greet and len(ans_greet) > 80, f"Length: {len(ans_greet)}")

    # 1.2 Scene Awareness with Knife & Tomatoes
    sample_dets = [
        {"object_name": "knife", "confidence": 0.92, "bbox": [100, 150, 200, 300]},
        {"object_name": "tomato", "confidence": 0.65, "bbox": [350, 200, 420, 280]},
        {"object_name": "tomato", "confidence": 0.58, "bbox": [430, 210, 500, 290]}
    ]
    ans_scene = assistant.ask("What do you see right now?", context_detections=sample_dets)
    check("Scene Description Accuracy", "knife" in ans_scene.lower() and "tomato" in ans_scene.lower(), f"Scene summary generated: {ans_scene[:70]}...")

    # 1.3 Safety Analysis
    ans_hazard = assistant.ask("Is there any hazard or danger here?", context_detections=sample_dets)
    check("Safety Hazard Warning", "knife" in ans_hazard.lower() and ("alert" in ans_hazard.lower() or "safety" in ans_hazard.lower()), f"Alert generated: {ans_hazard[:70]}...")

    # 1.4 Culinary & Recipe Suggestion
    ans_recipe = assistant.ask("What can I cook with these ingredients?", context_detections=sample_dets)
    check("Culinary / Recipe Suggestions", any(w in ans_recipe.lower() for w in ["salsa", "bruschetta", "pasta", "culinary", "recipe"]), f"Recipe generated: {ans_recipe[:70]}...")

    # 1.5 Object Counting
    ans_count = assistant.ask("How many tomatoes are there?", context_detections=sample_dets)
    check("Object Count Accuracy", "2" in ans_count or "two" in ans_count.lower(), f"Count response: {ans_count}")

    # 1.6 Deep Technical Architecture Explanation
    ans_tech = assistant.ask("Explain how YOLOv8 object detection works")
    check("YOLOv8 Architecture Explanation", "backbone" in ans_tech.lower() and "head" in ans_tech.lower(), f"Tech explanation: {ans_tech[:70]}...")

    # 1.7 OCR Scene Reading
    ans_ocr = assistant.ask("Read the text in the scene", ocr_text="Smart Vision AI Project v2.0")
    check("OCR Scene Reading", "Smart Vision AI Project v2.0" in ans_ocr, f"OCR response: {ans_ocr[:70]}...")

    # 1.8 Natural Human Dialogue Flow (User's specific sequence: hi -> how r u -> hmm -> ok)
    print("\n--- 1.8 Natural Human Dialogue Flow (hi -> how r u -> hmm -> ok) ---")
    c_assistant = SmartVisionAssistant()
    
    r_hi = c_assistant.ask("hi")
    check("Dialogue 'hi'", "hello" in r_hi.lower() or "connect" in r_hi.lower() or "help" in r_hi.lower() or "hey" in r_hi.lower(), f"Reply: {r_hi[:60]}")
    check("No canned template on 'hi'", "i understand your query" not in r_hi.lower())

    r_hru = c_assistant.ask("how r u")
    check("Dialogue 'how r u'", "doing" in r_hru.lower() or "great" in r_hru.lower() or "well" in r_hru.lower(), f"Reply: {r_hru[:60]}")
    check("No canned template on 'how r u'", "i understand your query" not in r_hru.lower())

    r_hmm = c_assistant.ask("hmm")
    check("Dialogue 'hmm'", "thinking" in r_hmm.lower() or "mind" in r_hmm.lower() or "time" in r_hmm.lower(), f"Reply: {r_hmm[:60]}")
    check("No canned template on 'hmm'", "i understand your query" not in r_hmm.lower())

    r_ok = c_assistant.ask("ok")
    check("Dialogue 'ok'", "sounds good" in r_ok.lower() or "explore" in r_ok.lower() or "great" in r_ok.lower() or "awesome" in r_ok.lower(), f"Reply: {r_ok[:60]}")
    check("No canned template on 'ok'", "i understand your query" not in r_ok.lower())

    # Verify that all 4 replies are distinct and unique
    replies = [r_hi, r_hru, r_hmm, r_ok]
    check("All 4 replies are distinct and dynamic", len(set(replies)) == 4, f"Unique replies: {len(set(replies))}/4")

    # 1.9 Conversation History Memory
    check("Multi-turn History Tracking", len(assistant.history) >= 14, f"Messages in history: {len(assistant.history)}")

    # 2. VisionChatbot Wrapper in core_utils
    print("\n--- 2. core_utils.VisionChatbot Integration ---")
    chatbot = VisionChatbot()
    bot_ans = chatbot.ask("What do you see?", context_detections=[{"object_name": "person", "confidence": 0.95}])
    check("VisionChatbot Delegation", "person" in bot_ans.lower(), f"Bot answer: {bot_ans[:65]}...")
    
    chatbot.clear_history()
    check("VisionChatbot Clear History", len(chatbot.history) == 0, f"History length: {len(chatbot.history)}")

    # 3. AIAssistant Dynamic Knowledge
    print("\n--- 3. core_utils.AIAssistant Object Insights ---")
    ai_asst = AIAssistant()
    knife_info = ai_asst.get_object_info("knife")
    check("AIAssistant Knife Safety Info", "caution" in knife_info['safety'].lower() or "sharp" in knife_info['description'].lower(), f"Safety: {knife_info['safety'][:60]}")
    knife_rec = ai_asst.get_recommendation("knife")
    check("AIAssistant Knife Recommendation", "knife" in knife_rec.lower() and "blade" in knife_rec.lower(), f"Rec: {knife_rec}")

    # 4. FastAPI /chatbot/query Endpoint
    print("\n--- 4. FastAPI Backend /chatbot/query Integration ---")
    try:
        resp = requests.post("http://localhost:8000/chatbot/query", json={
            "query": "What do you see in the kitchen?",
            "context": {
                "detections": [
                    {"object_name": "knife", "confidence": 0.91},
                    {"object_name": "tomato", "confidence": 0.60}
                ]
            }
        }, timeout=8)
        if resp.status_code == 200:
            data = resp.json()
            r_text = data.get("response", "")
            check("FastAPI Chatbot Endpoint Status 200", True, f"Response: {r_text[:70]}...")
            check("FastAPI Chatbot Vision Context Awareness", "knife" in r_text.lower(), f"Context recognized: {r_text[:60]}")
        else:
            check("FastAPI Chatbot Endpoint Status 200", False, f"Status code: {resp.status_code}")
    except Exception as e:
        check("FastAPI Chatbot Endpoint Connection", False, str(e))

    print("\n" + "=" * 70)
    print(f"ASSISTANT VERIFICATION SUMMARY: {passed}/{total} TESTS PASSED ({passed/total*100:.1f}%)")
    print("=" * 70)
    return passed == total

if __name__ == "__main__":
    success = run_tests()
    sys.exit(0 if success else 1)
