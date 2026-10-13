import pytest

from voice_interaction import (
    SpeechTranscriptionError,
    answer_application_question,
    parse_voice_command,
    transcribe_audio,
)


PAGES = ["Dashboard", "Settings", "Voice Assistant"]


@pytest.mark.parametrize(
    ("transcript", "action", "value"),
    [
        ("turn on voice announcements", "announcements", "on"),
        ("disable object tracking", "tracking", "off"),
        ("clear voice announcements", "reset_announcements", ""),
        ("take me to settings", "navigate", "Settings"),
        ("open voice assistant", "navigate", "Voice Assistant"),
        ("what do you see right now?", "question", "what do you see right now?"),
    ],
)
def test_parse_voice_command(transcript, action, value):
    command = parse_voice_command(transcript, PAGES)

    assert command.action == action
    assert command.value == value


def test_unrecognized_navigation_is_not_treated_as_a_question():
    command = parse_voice_command("open a page that does not exist", PAGES)

    assert command.action == "unknown"


@pytest.mark.parametrize(
    ("question", "expected_text"),
    [
        ("What features does this application have?", "detect and classify objects"),
        ("What are the features in the app?", "detect and classify objects"),
        ("What different different features will do in the application?", "detect and classify objects"),
        ("What does this app do?", "detect and classify objects"),
        ("What does object detection do?", "Object Detection analyzes"),
        ("Tell me what QR scanner does", "QR Scanner detects QR codes"),
        ("What is the use of barcode scanning?", "QR Scanner detects QR codes"),
        ("What does face registration do?", "Face Registration stores face samples"),
        ("How does tracking work?", "Object tracking assigns identities"),
        ("Tell me about the OCR feature", "extracts text"),
        ("How does video fast review work?", "scans an uploaded video"),
        ("What does the voice assistant do?", "accepts recorded questions and commands"),
    ],
)
def test_application_feature_questions(question, expected_text):
    answer = answer_application_question(question)

    assert answer is not None
    assert expected_text in answer


def test_scene_questions_are_left_for_the_vision_chatbot():
    assert answer_application_question("What objects are in this image?") is None


def test_transcription_surfaces_unreadable_recording(monkeypatch):
    import voice_interaction

    class FakeAudioFile:
        def __init__(self, audio_bytes):
            self.audio_bytes = audio_bytes

        def __enter__(self):
            return self

        def __exit__(self, exc_type, exc_value, traceback):
            return False

    class FakeRecognizer:
        def record(self, source):
            return object()

        def recognize_google(self, audio):
            raise voice_interaction.sr.UnknownValueError()

    monkeypatch.setattr(voice_interaction.sr, "Recognizer", FakeRecognizer)
    monkeypatch.setattr(voice_interaction.sr, "AudioFile", FakeAudioFile)

    with pytest.raises(SpeechTranscriptionError, match="couldn't understand"):
        transcribe_audio(b"valid-wave-is-mocked")
