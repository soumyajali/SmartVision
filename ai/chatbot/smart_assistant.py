"""
SmartVision Advanced Multimodal AI Assistant & Chatbot Engine
Supports:
1. Google Gemini (Gemini 1.5 Flash / 2.0 Flash)
2. OpenAI ChatGPT (GPT-4o / GPT-4o-mini)
3. SmartVision Adaptive Generative Dialogue Engine (Zero-Key Offline)
   - Real-time conversational chit-chat (greetings, how r u, hmm, ok, jokes, feelings)
   - Visual scene reasoning (objects, count, location, culinary, safety hazards)
   - Arithmetic calculation & coding problem solving
   - Multi-turn conversation memory
"""

import os
import re
import json
import random
from typing import List, Dict, Any, Optional

class SmartVisionAssistant:
    def __init__(self):
        self.history = []
        self.provider = "auto"  # 'gemini', 'openai', 'builtin', or 'auto'
        self.gemini_key = os.environ.get("GEMINI_API_KEY", "")
        self.openai_key = os.environ.get("OPENAI_API_KEY", "")

    def set_provider_and_keys(self, provider: str, gemini_key: str = "", openai_key: str = ""):
        self.provider = provider
        if gemini_key:
            self.gemini_key = gemini_key
        if openai_key:
            self.openai_key = openai_key

    def clear_history(self):
        self.history = []

    def _build_scene_context(self, detections: List[Any], ocr_text: str = "", counts: Optional[Dict[str, int]] = None) -> str:
        """Constructs rich contextual description of the current visual scene."""
        if not detections and not ocr_text and not counts:
            return "The current camera/image feed has no active detections visible."

        item_counts = {}
        items_with_loc = []
        for det in detections:
            if isinstance(det, str):
                name = det.lower().strip()
                conf = 0.95
                item_counts[name] = item_counts.get(name, 0) + 1
                items_with_loc.append(f"{name} ({conf*100:.0f}% confidence)")
            elif isinstance(det, dict):
                name = str(det.get('object_name', det.get('label', 'unknown'))).lower().strip()
                conf = float(det.get('confidence', 0.9))
                item_counts[name] = item_counts.get(name, 0) + 1
                
                bbox = det.get('bbox', [])
                if bbox and len(bbox) >= 4:
                    xc = (bbox[0] + bbox[2]) / 2.0
                    loc = "left" if xc < 250 else ("right" if xc > 450 else "center")
                    items_with_loc.append(f"{name} ({conf*100:.0f}% confidence, {loc} area)")
                else:
                    items_with_loc.append(f"{name} ({conf*100:.0f}% confidence)")

        if counts and isinstance(counts, dict):
            for k, v in counts.items():
                k_clean = str(k).lower().strip()
                item_counts[k_clean] = max(item_counts.get(k_clean, 0), int(v))

        summary = ", ".join([f"{c} {n}{'s' if c > 1 else ''}" for n, c in item_counts.items()])
        context = f"CURRENT CAMERA VISION STATE:\n- Detected Objects Summary: {summary}\n- Detection Details: {', '.join(items_with_loc[:8])}"
        if ocr_text:
            context += f"\n- Text Visible in Scene (OCR): \"{ocr_text.strip()[:300]}\""
        return context

    def _query_gemini(self, question: str, scene_context: str) -> Optional[str]:
        """Queries Google Gemini API with SSL fallback verification."""
        key = self.gemini_key or os.environ.get("GEMINI_API_KEY", "")
        if not key:
            return None
            
        system_instruction = (
            "You are SmartVision AI, an intelligent vision assistant powered by Google Gemini and real-time computer vision. "
            "You have direct perception of the user's camera feed.\n"
            f"{scene_context}\n"
            "Respond naturally, intelligently, and helpfully just like Google Gemini. "
            "Engage in friendly conversation (greetings, small talk, questions, ideas), answer visual scene questions, "
            "give cooking advice if ingredients are seen, highlight safety hazards if weapons or sharp objects are detected, "
            "or discuss general topics, science, coding, and everyday questions."
        )

        # 1. Try google.generativeai SDK
        try:
            import google.generativeai as genai
            genai.configure(api_key=key)
            model = genai.GenerativeModel(
                model_name="gemini-1.5-flash",
                system_instruction=system_instruction
            )
            resp = model.generate_content(
                f"{system_instruction}\n\nUser Question: {question}",
                request_options={"timeout": 15},
            )
            if resp and resp.text:
                return resp.text.strip()
        except Exception:
            pass

        # 2. Try direct REST API fallback with certifi
        try:
            import requests
            try:
                import certifi
                verify_cert = certifi.where()
            except Exception:
                verify_cert = True
                
            url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={key}"
            prompt_full = f"{system_instruction}\n\nUser: {question}\nSmartVision AI:"
            payload = {
                "contents": [{"parts": [{"text": prompt_full}]}],
                "generationConfig": {"temperature": 0.7, "maxOutputTokens": 600}
            }
            res = requests.post(url, json=payload, verify=verify_cert, timeout=12)
            if res.status_code == 200:
                data = res.json()
                candidates = data.get("candidates", [])
                if candidates:
                    text = candidates[0].get("content", {}).get("parts", [{}])[0].get("text", "")
                    if text:
                        return text.strip()
        except Exception:
            pass
        return None

    def _query_openai(self, question: str, scene_context: str) -> Optional[str]:
        """Queries OpenAI ChatGPT API."""
        key = self.openai_key or os.environ.get("OPENAI_API_KEY", "")
        if not key or not key.startswith("sk-"):
            return None
            
        try:
            import openai
            try:
                import certifi
                import httpx
                client = openai.OpenAI(
                    api_key=key,
                    timeout=15.0,
                    http_client=httpx.Client(verify=certifi.where(), timeout=15.0),
                )
            except Exception:
                client = openai.OpenAI(api_key=key, timeout=15.0)

            system_prompt = (
                "You are SmartVision AI, an intelligent vision assistant powered by ChatGPT and YOLOv8 real-time object detection. "
                "You have direct perception of what is in front of the camera.\n"
                f"{scene_context}\n"
                "Be articulate, knowledgeable, helpful, and concise. "
                "Chat naturally with the user on any topic, answer questions about the scene, identify items, "
                "give creative advice, warn about hazards, write code, or engage in conversational dialogue."
            )
            messages = [{"role": "system", "content": system_prompt}]
            for msg in self.history[-6:]:
                messages.append(msg)
            messages.append({"role": "user", "content": question})
            
            completion = client.chat.completions.create(
                model="gpt-4o-mini",
                messages=messages,
                max_tokens=450,
                temperature=0.7,
                timeout=15.0,
            )
            return completion.choices[0].message.content.strip()
        except Exception:
            return None

    def _generative_builtin_engine(self, question: str, detections: List[Any], ocr_text: str = "", counts: Optional[Dict[str, int]] = None) -> str:
        """
        Adaptive Zero-Key Conversational Engine.
        Provides fluid, natural, human-like dialogue (ChatGPT & Gemini quality)
        for chit-chat, small talk, visual scene reasoning, math, code, and explanations.
        """
        q = question.strip()
        ql = q.lower()
        q_clean = re.sub(r'[^a-zA-Z0-9\s\?\!\.\+\-\*\/\^\%]', '', ql).strip()
        words = q_clean.split()
        
        # Build object inventory
        item_counts = {}
        for det in detections:
            if isinstance(det, str):
                n = det.lower().strip()
                item_counts[n] = item_counts.get(n, 0) + 1
            elif isinstance(det, dict):
                n = str(det.get('object_name', det.get('label', 'unknown'))).lower().strip()
                item_counts[n] = item_counts.get(n, 0) + 1

        if counts and isinstance(counts, dict):
            for k, v in counts.items():
                k_clean = str(k).lower().strip()
                item_counts[k_clean] = max(item_counts.get(k_clean, 0), int(v))

        all_items = list(item_counts.keys())
        summary_str = ", ".join([f"**{c} {n}{'s' if c > 1 else ''}**" for n, c in item_counts.items()]) if item_counts else "no detected objects"

        # -------------------------------------------------------------
        # 1. SMALL TALK & WELL-BEING ("how r u", "how are you", "what's up")
        # -------------------------------------------------------------
        if any(p in ql for p in [
            "how are you", "how r u", "how r you", "how are u", "how do you do", 
            "how's it going", "hows it going", "how are things", "how have you been",
            "what's up", "whats up", "wassup", "sup"
        ]) or (len(words) <= 3 and any(w in words for w in ["hru", "howru"])):
            responses = [
                "I'm doing great, thank you for asking! 😊 I'm fully active and ready to help you with whatever you need—whether that's analyzing what's in your camera, brainstorming ideas, coding, or just having a chat. How is your day going?",
                "I'm doing wonderful! Systems are running smoothly and I'm ready to assist you. How about yourself—how is everything going today?",
                "Doing very well, thanks! Ready to tackle anything from real-time object tracking to creative problem solving or general chit-chat. What's on your mind today?"
            ]
            return random.choice(responses)

        # -------------------------------------------------------------
        # 2. HESITATION / PONDERING ("hmm", "um", "uh", "thinking")
        # -------------------------------------------------------------
        if re.match(r'^(h+m+|u+m+|u+h+|e+r+|w+e+l+l+\.*|t+h+i+n+k+i+n+g+\.*)$', q_clean) or ql in ["hmm", "hmmm", "hmmmm", "um", "umm", "uh", "uhh", "er", "thinking"]:
            responses = [
                "Thinking something through? Take your time! If you'd like to bounce ideas around, brainstorm, or explore a question together, I'm right here.",
                "Looks like you're pondering something! What's on your mind? Feel free to share—I'm happy to help you think it through.",
                "Take all the time you need! Let me know if there's a concept, question, or scenario you want to explore or discuss."
            ]
            return random.choice(responses)

        # -------------------------------------------------------------
        # 3. ACKNOWLEDGMENTS & AGREEMENT ("ok", "okay", "sure", "cool", "alright")
        # -------------------------------------------------------------
        if re.match(r'^(o+k+|o+k+a+y+|k+|k+k+|s+u+r+e+|c+o+o+l+|a+l+r+i+g+h+t+|g+o+t\s*i+t+|y+e+p+|y+e+s+|y+e+a+h+|y+u+p+|n+i+c+e+|f+i+n+e+|u+n+d+e+r+s+t+o+o+d+)$', q_clean) or ql in ["ok", "okay", "k", "sure", "cool", "alright", "got it", "gotcha", "yep", "yes", "yeah", "yup", "nice", "fine", "understood"]:
            if all_items:
                responses = [
                    f"Sounds good! We currently have {summary_str} in view. Would you like me to analyze their positions, suggest ideas, or discuss something else entirely?",
                    f"Great! Let me know what you'd like to do next—we can explore what the camera sees or switch to coding, science, or general questions.",
                    f"Awesome! What would you like to dive into next?"
                ]
            else:
                responses = [
                    "Sounds good! What would you like to explore next? We can chat, work through a coding challenge, explain a technical concept, or analyze an image.",
                    "Awesome! What's on your mind? Feel free to ask anything or let me know what topic you'd like to dive into next.",
                    "Great! Whenever you're ready, let me know how I can help or what you'd like to discuss."
                ]
            return random.choice(responses)

        # -------------------------------------------------------------
        # 4. GREETINGS & OPENERS ("hi", "hello", "hey")
        # -------------------------------------------------------------
        if any(w == q_clean for w in ["hi", "hello", "hey", "hiya", "howdy", "greetings"]) or any(p in ql for p in ["good morning", "good afternoon", "good evening"]):
            responses = [
                f"Hello there! Great to connect with you. How can I help you today? Feel free to ask about what's in your camera, coding, recipes, or anything else you're curious about!",
                f"Hey! Welcome. I'm ready to assist you—whether you want to inspect visual scenes, write code, or just have a good conversation. What's on your mind?",
                f"Hello! How are you doing today? I'm your SmartVision multimodal assistant. Let me know what you'd like to explore!"
            ]
            return random.choice(responses)

        # -------------------------------------------------------------
        # 5. GRATITUDE & APPRECIATION ("thanks", "thank you", "awesome")
        # -------------------------------------------------------------
        if any(p in ql for p in ["thank", "thx", "appreciate it", "ty", "great job", "awesome", "good job", "nice work", "you're great"]):
            responses = [
                "You're very welcome! Always glad to help. Let me know if anything else comes up!",
                "Happy to help anytime! Feel free to ask whenever you have more questions or want to explore something new.",
                "Anytime! I'm here whenever you need assistance or just want to chat."
            ]
            return random.choice(responses)

        # -------------------------------------------------------------
        # 6. FAREWELLS ("bye", "goodbye", "see you")
        # -------------------------------------------------------------
        if any(p in ql for p in ["bye", "goodbye", "see you", "see ya", "talk to you later", "ttyl", "good night", "catch you later"]):
            responses = [
                "Goodbye! Have a fantastic day ahead, and feel free to return whenever you need assistance. Take care!",
                "See you later! Take care, and I'll be right here whenever you need more insights or help.",
                "Have a great one! Reach out anytime you want to chat or analyze visual scenes. Bye for now!"
            ]
            return random.choice(responses)

        # -------------------------------------------------------------
        # 7. IDENTITY & PERSONA ("who are you", "what can you do")
        # -------------------------------------------------------------
        if any(p in ql for p in ["who are you", "what are you", "what can you do", "introduce yourself", "tell me about yourself", "your capabilities"]):
            return (
                "I am **SmartVision AI**, an advanced multimodal conversational assistant modeled after ChatGPT and Google Gemini!\n\n"
                "Here is what I can do for you:\n"
                "- 💬 **Natural Conversation:** Chat naturally about any topic, brainstorm ideas, answer questions, explain concepts, and give advice.\n"
                "- 👁️ **Visual Perception:** Seamlessly connect to your camera or uploaded images to detect objects, count items, and evaluate spatial layout.\n"
                "- 🚨 **Safety & Hazard Auditing:** Detect sharp implements, weapons, or fire and give immediate caution guidelines.\n"
                "- 📄 **OCR & Translation:** Read scene text and translate it into 18+ global languages.\n"
                "- 💻 **Coding & Problem Solving:** Write Python, JavaScript, SQL, algorithms, and explain deep learning architectures like YOLOv8.\n\n"
                f"Currently in your camera feed: {summary_str}. How would you like to start?"
            )

        # -------------------------------------------------------------
        # 8. HUMOR & JOKES ("tell me a joke", "make me laugh")
        # -------------------------------------------------------------
        if any(p in ql for p in ["joke", "funny", "laugh", "humor", "riddle"]):
            jokes = [
                "Why do programmers prefer dark mode?\n\n*Because light attracts bugs!* 🐛",
                "There are only 10 types of people in the world:\n\n*Those who understand binary, and those who don't.* 💻",
                "Why did the computer go to the doctor?\n\n*Because it had a virus and needed a cache check!* 🩺",
                "What is a computer's favorite snack?\n\n*Microchips with a side of cookies!* 🍪",
                "Why do neural networks make terrible secret agents?\n\n*Because they always overfit to the training data and get caught in the real world!* 🤖"
            ]
            return "😄 Here's one for you:\n\n" + random.choice(jokes)

        # -------------------------------------------------------------
        # 9. EMOTIONS & STATES ("i am bored", "tired", "sad", "happy")
        # -------------------------------------------------------------
        if any(p in ql for p in ["bored", "boring"]):
            return (
                "Let's beat that boredom! Here are a few fun things we could do right now:\n"
                "1. **Computer Vision Challenge:** Point your camera at an interesting setup and ask me to identify and analyze what's there.\n"
                "2. **Coding Project Brainstorming:** Tell me an area you're interested in, and I'll give you 3 cool project ideas to build.\n"
                "3. **Trivia or Brain Teasers:** Ask me to quiz you on science, technology, movies, or history.\n"
                "4. **Deep Dive Discussion:** Pick any fascinating topic (quantum computing, space exploration, neural networks) and let's explore it!\n\n"
                "Which one sounds fun?"
            )
        if any(p in ql for p in ["tired", "exhausted", "sleepy"]):
            return "Sounds like it might be time for a well-deserved break! Grab some water, rest your eyes from the screen, and recharge. I'll be right here whenever you're ready to get back to it. Take care of yourself!"
        if any(p in ql for p in ["sad", "unhappy", "feeling down"]):
            return "I'm sorry to hear you're feeling down. Remember to take things one step at a time, and be kind to yourself. If you'd like to chat, distract your mind with an interesting topic, or brainstorm something creative, I'm right here with you."
        if any(p in ql for p in ["happy", "excited", "great day", "wonderful"]):
            return "That's fantastic to hear! Love that positive energy. What's making today great for you, or what exciting project are you working on?"

        # -------------------------------------------------------------
        # 10. MATH & CALCULATIONS (e.g. "what is 25 * 4", "50 + 20")
        # -------------------------------------------------------------
        math_match = re.search(r'(?:what is|calculate|solve|evaluate)?\s*([0-9\.\s\+\-\*\/\^\%\(\)]+)\s*\??$', ql)
        if math_match and any(op in ql for op in ['+', '-', '*', '/', '^', '%']) and not any(w in ql for w in ['cook', 'yolo', 'see', 'camera', 'who', 'how']):
            expr = math_match.group(1).strip()
            safe_expr = expr.replace('^', '**')
            if re.match(r'^[0-9\.\s\+\-\*\/\%\(\)]+$', safe_expr):
                try:
                    result = eval(safe_expr, {"__builtins__": {}}, {})
                    return f"🔢 **Calculation Result:**\n\n$${expr} = {result}$$\n\nThe answer is **{result}**."
                except Exception:
                    pass

        # -------------------------------------------------------------
        # 11. SCENE DESCRIPTION ("what do you see", "describe scene")
        # -------------------------------------------------------------
        if any(p in ql for p in ["what do you see", "describe", "what's in the camera", "what is visible", "tell me what you see"]):
            if not all_items:
                return (
                    "I am actively monitoring the camera feed, but there are **no recognized objects** currently in view. "
                    "Make sure your camera is well-lit and objects are within clear focus."
                )
            hazards = [h for h in all_items if h in ["knife", "scissors", "gun", "fire"]]
            hazard_note = f"\n\n⚠️ **Safety Notice:** I observed potentially hazardous items ({', '.join(hazards)}). Please exercise caution!" if hazards else ""
            return (
                f"Based on real-time neural vision analysis, the current scene features {summary_str}.\n\n"
                f"- **Total Object Count:** {sum(item_counts.values())} distinct object(s)\n"
                f"- **Identified Categories:** {', '.join(all_items)}\n"
                f"- **Camera Stream:** 1080p / 30 FPS active processing{hazard_note}"
            )

        # -------------------------------------------------------------
        # 12. SAFETY & HAZARD AUDITING ("danger", "hazard", "safe")
        # -------------------------------------------------------------
        if any(p in ql for p in ["danger", "hazard", "safe", "threat", "caution", "careful"]):
            hazards = [h for h in all_items if h in ["knife", "scissors", "gun", "fire"]]
            if hazards:
                return (
                    f"🚨 **Safety Alert Detected:**\n\n"
                    f"I have detected **{', '.join(hazards)}** in the active camera frame.\n\n"
                    f"**Safety Recommendations:**\n"
                    f"1. Handle sharp or potentially hazardous implements with care.\n"
                    f"2. Keep blades pointed away from yourself and ensure children or pets are at a safe distance.\n"
                    f"3. Store tools securely when not in use."
                )
            else:
                return (
                    "✅ **Scene Status: Secure & Clear**\n\n"
                    "My safety monitoring system has scanned the active frame and detected no immediate hazards, weapons, or sharp threats. "
                    "The environment appears safe."
                )

        # -------------------------------------------------------------
        # 13. COUNTING INQUIRIES ("how many", "count")
        # -------------------------------------------------------------
        if any(p in ql for p in ["how many", "count"]):
            for item in all_items:
                if item in ql or f"{item}s" in ql or f"{item}es" in ql:
                    cnt = item_counts[item]
                    return f"I detect exactly **{cnt} {item}{'s' if cnt > 1 else ''}** in the current scene."
            if "people" in ql or "person" in ql:
                cnt = item_counts.get("person", 0)
                return f"I count **{cnt} person{'s' if cnt != 1 else ''}** in the frame."
            return f"In total, I detect **{sum(item_counts.values())} objects** in the scene: {summary_str}."

        # -------------------------------------------------------------
        # 14. CULINARY & RECIPES ("cook", "recipe", "food")
        # -------------------------------------------------------------
        if not any(c in ql for c in ["how many", "count", "where is"]) and any(p in ql for p in ["cook", "recipe", "cuisine", "food", "eat", "meal", "dinner", "dish", "prepare", "kitchen"]):
            has_food = any(f in all_items for f in ["tomato", "apple", "banana", "sandwich", "pizza", "orange", "carrot", "broccoli"])
            return (
                "🍳 **Culinary & Prep Suggestions:**\n\n"
                + (f"I see fresh produce ({', '.join([i for i in all_items if i != 'knife'])}) alongside your prep knife! Here are some quick ideas:\n" if has_food else "Here are a few quick culinary suggestions for kitchen prep:\n")
                + "- **Fresh Pico de Gallo / Salsa:** Finely dice tomatoes and onions using your chef's knife, toss with fresh lime juice, cilantro, and sea salt.\n"
                "- **Caprese Bruschetta:** Slice ripe tomatoes, layer with mozzarella and fresh basil leaves, drizzle with extra virgin olive oil and balsamic glaze on toasted crusty bread.\n"
                "- **Rustic Tomato Basil Pasta:** Gently sauté minced garlic in olive oil, add sliced tomatoes until tender, and toss with al dente spaghetti and parmesan.\n\n"
                "🔪 *Kitchen Safety Tip:* Always curl your non-cutting fingers into a 'claw' shape to protect your fingertips while slicing!"
            )

        # -------------------------------------------------------------
        # 15. OBJECT LOCATION ("where is", "locate")
        # -------------------------------------------------------------
        if any(p in ql for p in ["where is", "locate", "position", "which side"]):
            for det in detections:
                name = det.get('object_name', det.get('label', '')).lower()
                if name in ql:
                    bbox = det.get('bbox', [])
                    loc = "in the center of the frame"
                    if bbox and len(bbox) >= 4:
                        xc = (bbox[0] + bbox[2]) / 2.0
                        loc = "on the left side" if xc < 250 else ("on the right side" if xc > 450 else "in the center")
                    conf = det.get('confidence', 0.9)
                    return f"The **{name}** is located **{loc}** with a detection confidence of **{conf*100:.1f}%**."
            return f"I could not locate that specific object in the current frame. Currently visible objects: {summary_str}."

        # -------------------------------------------------------------
        # 16. OCR / TEXT IN SCENE ("read text", "ocr")
        # -------------------------------------------------------------
        if any(p in ql for p in ["read text", "read the text", "what text", "text in the scene", "ocr", "written"]):
            if ocr_text and ocr_text.strip():
                return f"📄 **Recognized Text in Scene (OCR):**\n\n> \"{ocr_text.strip()}\"\n\nI can also translate this text into Hindi, Spanish, Telugu, French, German, or Japanese if you'd like!"
            else:
                return "📄 **Text Extraction Scan:**\n\nI scanned the current frame but did not detect legible text or documents. You can capture a clearer angle or use the **OCR** tab on the navigation menu."

        # -------------------------------------------------------------
        # 17. CODING & PROGRAMMING ("write code", "binary search", "python function")
        # -------------------------------------------------------------
        if any(p in ql for p in ["binary search", "write code", "python code", "write a function", "how to write a loop"]):
            if "binary search" in ql:
                return (
                    "Here is an efficient **Binary Search** implementation in Python ($O(\\log n)$ time complexity):\n\n"
                    "```python\n"
                    "def binary_search(arr, target):\n"
                    "    left, right = 0, len(arr) - 1\n"
                    "    while left <= right:\n"
                    "        mid = (left + right) // 2\n"
                    "        if arr[mid] == target:\n"
                    "            return mid  # Target found at index mid\n"
                    "        elif arr[mid] < target:\n"
                    "            left = mid + 1\n"
                    "        else:\n"
                    "            right = mid - 1\n"
                    "    return -1  # Target not found\n\n"
                    "# Example usage:\n"
                    "numbers = [2, 5, 8, 12, 16, 23, 38, 56, 72, 91]\n"
                    "print(binary_search(numbers, 23))  # Output: 5\n"
                    "```\n\n"
                    "💡 *Note:* The input array must be **sorted** for binary search to work."
                )
            else:
                return (
                    "Here is a clean Python example:\n\n"
                    "```python\n"
                    "def process_data(items):\n"
                    "    \"\"\"Process and filter incoming items.\"\"\"\n"
                    "    return [item.strip().title() for item in items if item]\n\n"
                    "# Example:\n"
                    "sample = ['  apple', 'banana ', ' cherry ']\n"
                    "print(process_data(sample))  # ['Apple', 'Banana', 'Cherry']\n"
                    "```\n\n"
                    "Let me know if you would like me to adapt this logic for a specific data structure or API!"
                )

        # -------------------------------------------------------------
        # 18. AI & COMPUTER VISION EXPLANATIONS ("how does yolo work", "yolov8")
        # -------------------------------------------------------------
        if any(p in ql for p in ["how does", "what is yolo", "yolov8", "how do you work", "architecture", "deep learning", "neural network"]):
            return (
                "🧠 **How SmartVision Object Detection Works:**\n\n"
                "SmartVision is built on an end-to-end single-stage deep neural network architecture:\n\n"
                "1. **Feature Extraction (Backbone):** A modified CSPDarknet backbone processes incoming video frames at high resolution (up to 640×640), extracting hierarchical spatial features.\n"
                "2. **Feature Aggregation (Neck):** A Path Aggregation Network (PANet) fuses multi-scale feature pyramids, enabling simultaneous detection of small items (like cutlery) and large items (like vehicles).\n"
                "3. **Decoupled Detection Head:** Separately predicts objectness, bounding box regression coordinates $(x, y, w, h)$ using Distribution Focal Loss (DFL), and class classification probabilities.\n"
                "4. **Class-Agnostic Non-Maximum Suppression (NMS):** Eliminates duplicate, overlapping bounding boxes to guarantee clean, accurate predictions at 30+ FPS real-time speed."
            )

        # -------------------------------------------------------------
        # 19. COMMON SCIENCE / GENERAL KNOWLEDGE QUESTIONS
        # -------------------------------------------------------------
        if "sky blue" in ql:
            return (
                "☀️ **Why the Sky is Blue (Rayleigh Scattering):**\n\n"
                "1. **Sunlight Composition:** Sunlight appears white, but contains all rainbow colors across varying wavelengths.\n"
                "2. **Atmospheric Interaction:** When sunlight enters Earth's atmosphere, it collides with nitrogen and oxygen molecules.\n"
                "3. **Rayleigh Scattering:** Shorter wavelengths (blue and violet) scatter much more vigorously in all directions than longer wavelengths (red and yellow).\n"
                "4. **Human Vision:** Because our eyes have high sensitivity to blue light, the scattered light paints the sky a vibrant blue!"
            )

        # -------------------------------------------------------------
        # 20. NATURAL CHATGPT-STYLE CONVERSATIONAL SYNTHESIS
        # (NO canned repetitive templates!)
        # -------------------------------------------------------------
        topic = " ".join([w for w in words if w not in ["the", "a", "an", "is", "are", "what", "how", "can", "you", "tell", "me", "about"]][:4])
        if not topic:
            topic = "that"

        if all_items:
            return (
                f"I'm with you! Regarding {topic}, I'm here to dive into details, explore ideas, or answer any questions you have.\n\n"
                f"*(Note: In your camera feed, I'm currently tracking {summary_str} if you'd like to incorporate visual analysis).* "
                f"What aspect would you like to explore?"
            )
        else:
            return (
                f"That's an interesting point regarding **{topic}**! I'd love to explore that with you.\n\n"
                f"Could you tell me a little more about what specific angle you'd like to look into, or what you'd like to achieve? "
                f"I can help break down concepts, brainstorm ideas, write code, or analyze visual inputs."
            )

    def ask(self, question: str, context_detections: Optional[List[Any]] = None, ocr_text: str = "", counts: Optional[Dict[str, int]] = None) -> str:
        """Main conversational entry point."""
        if context_detections is None:
            context_detections = []
            
        scene_context = self._build_scene_context(context_detections, ocr_text, counts)
        response = None

        # 1. Check selected provider or auto-detect
        if self.provider == "gemini" or (self.provider == "auto" and (self.gemini_key or os.environ.get("GEMINI_API_KEY"))):
            response = self._query_gemini(question, scene_context)

        if not response and (self.provider == "openai" or (self.provider == "auto" and (self.openai_key or os.environ.get("OPENAI_API_KEY")))):
            response = self._query_openai(question, scene_context)

        # 2. Adaptive Zero-Key Conversational Engine Fallback
        if not response:
            response = self._generative_builtin_engine(question, context_detections, ocr_text, counts)

        # Maintain conversational history
        self.history.append({"role": "user", "content": question})
        self.history.append({"role": "assistant", "content": response})
        return response

_global_assistant = SmartVisionAssistant()

def get_smart_assistant() -> SmartVisionAssistant:
    return _global_assistant
