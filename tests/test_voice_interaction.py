import pytest

from voice_interaction import SpeechTranscriptionError, parse_voice_command, transcribe_audio


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
