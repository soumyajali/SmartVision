"""Speech transcription and command parsing for the Streamlit voice assistant."""

from dataclasses import dataclass
from functools import lru_cache
from io import BytesIO
from pathlib import Path
import re
from typing import Sequence

try:
    import speech_recognition as sr
except ModuleNotFoundError:
    class _SpeechRecognitionFallback:
        """Lightweight fallback for environments without SpeechRecognition installed."""

        class UnknownValueError(Exception):
            pass

        class RequestError(Exception):
            pass

        class AudioSourceError(Exception):
            pass

        class Recognizer:
            def record(self, source):
                return object()

            def recognize_google(self, audio):
                raise _SpeechRecognitionFallback.UnknownValueError()

        class AudioFile:
            def __init__(self, *args, **kwargs):
                pass

            def __enter__(self):
                return self

            def __exit__(self, exc_type, exc_value, traceback):
                return False

    sr = _SpeechRecognitionFallback()


@dataclass(frozen=True)
class VoiceCommand:
    action: str
    value: str = ""


class SpeechTranscriptionError(Exception):
    """Raised when an audio recording cannot be transcribed."""


@lru_cache(maxsize=1)
def _load_intent_model():
    """Load the trained question intent model when its artifact is available."""
    model_path = Path(__file__).resolve().parent / "ai_model" / "chatbot_intent_model.pkl"
    if not model_path.is_file():
        return None
    try:
        import joblib
        return joblib.load(model_path)
    except Exception:
        return None


def _predict_question_intent(question: str) -> str | None:
    model = _load_intent_model()
    if model is None:
        return None
    try:
        return str(model.predict([question])[0])
    except Exception:
        return None


APPLICATION_FEATURES = (
    (
        ("dashboard", "home page", "live detection", "real time detection"),
        "The Dashboard shows live detection status and recent detections, and lets you start camera detection and capture or record results.",
    ),
    (
        ("object detection", "detect objects", "object recognition", "yolo"),
        "Object Detection analyzes an uploaded image or camera capture with YOLO, shows detected objects and confidence scores, and can announce new detections by voice.",
    ),
    (
        ("classification", "classify", "image classification", "mobilenet"),
        "Classification uses the trained MobileNet model to classify an uploaded image.",
    ),
    (
        ("vision chatbot", "chatbot", "ask questions about the scene", "typed questions"),
        "Vision Chatbot answers typed questions about the latest detected objects. Its text answers are also spoken aloud by your browser.",
    ),
    (
        ("voice assistant", "voice control", "voice commands", "voice question", "speech assistant", "voice input"),
        "Voice Assistant accepts recorded questions and commands. It can explain SmartVision features and the latest object-detection or OCR results, navigate dashboard pages, toggle voice announcements or object tracking, and reset announcements. Browser speech synthesis reads answers aloud. Speech recognition sends recordings to Google's online service.",
    ),
    (
        ("ocr", "read text", "text recognition", "translate", "translation", "optical character recognition"),
        "OCR extracts text from uploaded images and can translate the extracted text into a selected language.",
    ),
    (
        ("qr", "qr scanner", "qr code", "barcode", "bar code"),
        "QR Scanner detects QR codes and barcodes in uploaded images and displays their type and decoded contents.",
    ),
    (
        ("face registration", "face recognition", "registered faces", "register face", "facial recognition"),
        "Face Registration stores face samples so the app can recognize registered people in images.",
    ),
    (
        ("analytics", "statistics", "metrics", "3d analytics", "detection charts"),
        "Analytics and 3D Analytics present detection metrics and visual summaries.",
    ),
    (
        ("history", "detection history", "saved detections"),
        "History displays saved detection records from the app's database.",
    ),
    (
        ("video fast review", "search video", "find in video", "video search", "reference image matching"),
        "Video Fast Review scans an uploaded video for a selected object category or a visual match to an uploaded reference image, then reports timestamps.",
    ),
    (
        ("drowsiness", "fatigue", "drowsiness monitor", "driver monitoring"),
        "Drowsiness Monitor analyzes camera or uploaded image input for signs of drowsiness and reports detected incidents.",
    ),
    (
        ("border security", "ibvap", "restricted area", "perimeter", "loitering", "intrusion detection"),
        "Border Security (IBVAP) lets you configure restricted zones and reports intrusions and loitering.",
    ),
    (
        ("object tracking", "tracking objects", "track detections", "tracking"),
        "Object tracking assigns identities to detected objects across frames so the app can follow them over time.",
    ),
    (("3d explorer", "interactive 3d", "model explorer"), 
        "3D Explorer displays an interactive visualization of the vision model pipeline.",
    ),
    (
        ("settings", "preferences", "confidence threshold", "adaptive mode", "search mode"),
        "Settings control voice announcements, confidence threshold, object search, tracking, adaptive processing, and restricted-area options.",
    ),
    (
        ("email alert", "telegram alert", "notifications", "safety alerts", "dangerous object alert", "siren"),
        "Email and Telegram alerts can send notifications for dangerous-object detections when the respective alert service is configured and enabled.",
    ),
)


def answer_application_question(question: str) -> str | None:
    """Answer application or latest-result questions using known app and session data."""
    normalized = " ".join(re.sub(r"[^a-z0-9 ]", " ", question.lower()).split())
    if not normalized:
        return None

    application_io_question = any(
        phrase in normalized
        for phrase in (
            "input and output of this app",
            "input and output of the app",
            "input and output of this application",
            "inputs and outputs",
            "what does this app take as input",
            "what does this application take as input",
            "how does this app work",
            "how does this application work",
        )
    )
    if application_io_question:
        return (
            "SmartVision takes camera captures or uploaded images for object detection, "
            "images or videos for OCR, videos and optional reference images for video "
            "review, and recorded audio for voice questions or commands. Depending on "
            "the feature, it returns labeled objects with confidence scores, recognized "
            "or translated text, video match timestamps, alerts, and written or spoken "
            "assistant answers. Results describe the submitted input and selected feature."
        )

    scene_question = any(
        phrase in normalized
        for phrase in (
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
    )
    ocr_question = any(
        phrase in normalized
        for phrase in (
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
    )
    if scene_question or ocr_question:
        return None

    for terms, description in APPLICATION_FEATURES:
        if any(term in normalized for term in terms):
            return description

    application_question = any(
        phrase in normalized
        for phrase in (
            "this application",
            "this app",
            "the application",
            "the app",
            "what can you do",
            "what features",
            "available features",
            "application features",
            "app features",
            "features of this application",
            "features of the app",
            "features this application",
            "features this app",
            "features in this app",
            "features in the app",
            "features of this app",
            "features of the application",
            "what are the features",
            "list the features",
            "tell me the features",
            "what does this do",
            "what does the app do",
            "what does this application do",
            "different features",
            "different different features",
            "what can this application do",
            "what can this app do",
            "explain the application",
            "explain this app",
        )
    )
    if application_question:
        return (
            "SmartVision can detect and classify objects, answer questions about detections, "
            "read and translate text with OCR, scan QR codes and barcodes, recognize registered "
            "faces, review videos, monitor drowsiness, and report restricted-area intrusions. "
            "It also includes analytics, history, 3D visualizations, alerts, and voice controls. "
            "Ask me about any feature for more details."
        )
    return None


def answer_scene_question(
    question: str,
    detections: Sequence[dict] | None = None,
    ocr_text: str = "",
) -> str | None:
    """Describe the latest detection and OCR output without guessing beyond the results."""
    normalized = " ".join(re.sub(r"[^a-z0-9 ]", " ", question.lower()).split())
    scene_question = any(
        phrase in normalized
        for phrase in (
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
            "describe this",
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
    )
    ocr_question = any(
        phrase in normalized
        for phrase in (
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
    )
    if not scene_question and not ocr_question:
        # Use the trained intent model to recognize paraphrases beyond the
        # explicit examples while preserving exact phrase matching as fallback.
        visual_terms = (
            "image", "photo", "picture", "scene", "camera", "input", "output",
            "result", "detect", "see", "shown", "ocr", "text", "read",
        )
        if any(term in normalized for term in visual_terms):
            intent = _predict_question_intent(normalized)
            scene_question = intent == "describe"
            ocr_question = intent == "ocr"
    if not scene_question and not ocr_question:
        return None

    detected_items: dict[str, list[float]] = {}
    for detection in detections or ():
        if not isinstance(detection, dict):
            continue
        name = str(detection.get("object_name", detection.get("label", ""))).strip()
        if not name:
            continue
        try:
            confidence = float(detection.get("confidence", 0))
        except (TypeError, ValueError):
            confidence = 0
        detected_items.setdefault(name, []).append(confidence)

    recognized_text = ocr_text.strip()
    if ocr_question:
        if recognized_text:
            return f"The latest OCR output reads: {recognized_text[:1200]}"
        return (
            "There is no OCR text result available yet. Open the OCR page, run text "
            "extraction on an image or video, and then ask me to read or explain the result."
        )

    if not detected_items and not recognized_text:
        return (
            "I don't have a recent image-analysis result to describe yet. Open Object "
            "Detection and analyze an image, or run OCR to extract visible text, then "
            "ask me to explain the result."
        )

    parts = []
    if detected_items:
        descriptions = []
        for name, confidences in detected_items.items():
            count = len(confidences)
            confidence = sum(confidences) / count
            descriptions.append(
                f"{count} {name}{'s' if count != 1 else ''} "
                f"(average detection confidence {confidence:.0%})"
            )
        parts.append("The latest object-detection output recognized " + ", ".join(descriptions) + ".")
    else:
        parts.append("The latest object-detection output contains no recorded objects.")

    if recognized_text:
        parts.append(f'The latest OCR output reads: "{recognized_text[:1200]}".')
    parts.append(
        "This is based on detected labels and OCR text, not direct understanding of "
        "the full image pixels. It cannot confirm actions or events not represented in these results."
    )
    return " ".join(parts)


def transcribe_audio(audio_bytes: bytes) -> str:
    """Transcribe a WAV recording using Google's online speech recognition."""
    recognizer = sr.Recognizer()
    try:
        with sr.AudioFile(BytesIO(audio_bytes)) as source:
            audio = recognizer.record(source)
        return recognizer.recognize_google(audio)
    except sr.UnknownValueError as exc:
        raise SpeechTranscriptionError(
            "I couldn't understand that recording. Please speak clearly and try again."
        ) from exc
    except sr.RequestError as exc:
        raise SpeechTranscriptionError(
            f"Speech recognition is unavailable right now: {exc}"
        ) from exc
    except (sr.AudioSourceError, ValueError) as exc:
        raise SpeechTranscriptionError(
            f"The recording could not be read: {exc}"
        ) from exc


def parse_voice_command(
    transcript: str,
    navigation_pages: Sequence[str],
) -> VoiceCommand:
    """Map typed or spoken input to an action; otherwise treat it as a question."""
    normalized = re.sub(r"[^a-z0-9 ]", " ", transcript.lower())
    normalized = " ".join(normalized.split())

    commands = {
        "enable voice announcements": VoiceCommand("announcements", "on"),
        "turn on voice announcements": VoiceCommand("announcements", "on"),
        "disable voice announcements": VoiceCommand("announcements", "off"),
        "turn off voice announcements": VoiceCommand("announcements", "off"),
        "enable object tracking": VoiceCommand("tracking", "on"),
        "start object tracking": VoiceCommand("tracking", "on"),
        "disable object tracking": VoiceCommand("tracking", "off"),
        "stop object tracking": VoiceCommand("tracking", "off"),
        "reset voice announcements": VoiceCommand("reset_announcements"),
        "clear voice announcements": VoiceCommand("reset_announcements"),
    }
    if normalized in commands:
        return commands[normalized]

    navigation_text = normalized
    for prefix in ("open ", "go to ", "navigate to ", "take me to "):
        if navigation_text.startswith(prefix):
            navigation_text = navigation_text[len(prefix):]
            break
    else:
        return VoiceCommand("question", transcript.strip())

    for page in navigation_pages:
        if navigation_text == page.lower():
            return VoiceCommand("navigate", page)

    return VoiceCommand("unknown")
