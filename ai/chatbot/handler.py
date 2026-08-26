from .models import SceneContext, ChatQuery, ChatResponse
from .intents import parse_intent

class ChatbotHandler:
    def handle_query(self, request: ChatQuery) -> ChatResponse:
        intent, params = parse_intent(request.query)
        context = request.context
        
        if not context:
            return ChatResponse(response="I don't have enough information from the current camera scene to answer that.", intent=intent)
            
        if intent == "count_object":
            target = params.get("target")
            count = context.counts.get(target, 0)
            return ChatResponse(response=f"I can see {count} {target}s.", intent=intent)
            
        elif intent == "describe_scene":
            visible = [f"{count} {obj}" for obj, count in context.counts.items()]
            if not visible:
                return ChatResponse(response="I don't see anything notable right now.", intent=intent)
            return ChatResponse(response="I see " + ", ".join(visible) + ".", intent=intent)
            
        elif intent == "search_object":
            target = params.get("target")
            if target in context.counts and context.counts[target] > 0:
                return ChatResponse(response=f"Yes, I see a {target}.", intent=intent)
            return ChatResponse(response=f"No, I don't see a {target}.", intent=intent)
            
        elif intent == "recognize_person":
            if context.faces:
                names = [f["name"] for f in context.faces if f.get("name")]
                if names:
                    return ChatResponse(response=f"I recognize {', '.join(names)}.", intent=intent)
            return ChatResponse(response="I don't recognize anyone right now.", intent=intent)
            
        elif intent == "read_ocr":
            if context.ocr:
                texts = [t["text"] for t in context.ocr if t.get("text")]
                if texts:
                    return ChatResponse(response=f"The text says: {', '.join(texts)}.", intent=intent)
            return ChatResponse(response="I haven't detected any text recently.", intent=intent)
            
        else:
            return ChatResponse(response="I don't have enough information from the current camera scene to answer that.", intent="unknown")
