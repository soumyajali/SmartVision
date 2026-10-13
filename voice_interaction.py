"""Speech transcription and command parsing for the Streamlit voice assistant."""

from dataclasses import dataclass
from io import BytesIO
import re
from typing import Sequence

import speech_recognition as sr


@dataclass(frozen=True)
class VoiceCommand:
    action: str
    value: str = ""


class SpeechTranscriptionError(Exception):
    """Raised when an audio recording cannot be transcribed."""


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
        "Voice Assistant accepts recorded questions and commands. It can answer about detections, navigate dashboard pages, toggle voice announcements or object tracking, and reset announcements. Browser speech synthesis reads answers aloud. Speech recognition sends recordings to Google's online service.",
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
    """Answer questions about documented app features; return None for other questions."""
    normalized = " ".join(re.sub(r"[^a-z0-9 ]", " ", question.lower()).split())
    if not normalized:
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
    """Map a spoken command to a supported action; otherwise treat it as a question."""
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
