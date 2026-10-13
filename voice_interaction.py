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
