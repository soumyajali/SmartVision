"""
Voice Assistant Module for Smart Vision AI
Provides offline text-to-speech functionality using pyttsx3
"""

import pyttsx3
import threading
import queue
from typing import Set, Optional


class VoiceAssistant:
    """
    Manages text-to-speech functionality with threading to avoid blocking the main application.
    Tracks announced objects to prevent repetitive announcements.
    """
    
    def __init__(self):
        """Initialize the voice assistant with a message queue and thread."""
        self.message_queue = queue.Queue()
        self.speech_thread = None
        self.thread_running = False
        self.announced_objects: Set[str] = set()
        self.engine: Optional[pyttsx3.Engine] = None
        self._initialize_engine()
        
    def _initialize_engine(self):
        """Initialize the pyttsx3 engine for speech synthesis."""
        try:
            self.engine = pyttsx3.init()
            # Set speech properties for better voice output
            self.engine.setProperty('rate', 150)  # Speed of speech
            self.engine.setProperty('volume', 0.9)  # Volume level (0.0 to 1.0)
        except Exception as e:
            print(f"Warning: Could not initialize voice engine: {e}")
            self.engine = None
    
    def _speech_worker(self):
        """
        Worker thread that processes speech messages from the queue.
        This runs in a separate thread to avoid blocking the Streamlit app.
        """
        while self.thread_running:
            try:
                # Get message from queue with timeout to allow checking thread_running
                message = self.message_queue.get(timeout=0.5)
                if message and self.engine:
                    try:
                        self.engine.say(message)
                        self.engine.runAndWait()
                    except Exception as e:
                        print(f"Error speaking message: {e}")
                self.message_queue.task_done()
            except queue.Empty:
                continue
            except Exception as e:
                print(f"Error in speech worker: {e}")
    
    def start(self):
        """Start the speech worker thread."""
        if not self.thread_running and self.engine:
            self.thread_running = True
            self.speech_thread = threading.Thread(target=self._speech_worker, daemon=True)
            self.speech_thread.start()
    
    def stop(self):
        """Stop the speech worker thread gracefully."""
        self.thread_running = False
        if self.speech_thread:
            self.speech_thread.join(timeout=2.0)
    
    def speak(self, text: str):
        """
        Queue a text message to be spoken.
        
        Args:
            text: The text to speak
        """
        if self.engine:
            self.message_queue.put(text)
    
    def announce_detection(self, object_name: str):
        """
        Announce a newly detected object if it hasn't been announced recently.
        
        Args:
            object_name: Name of the detected object
        """
        # Normalize object name for consistent tracking
        normalized_name = object_name.lower().strip()
        
        # Only announce if this is a new detection
        if normalized_name not in self.announced_objects:
            self.announced_objects.add(normalized_name)
            message = f"{object_name} detected"
            self.speak(message)
    
    def reset_announced_objects(self, current_objects: Set[str]):
        """
        Reset the announced objects based on currently detected objects.
        Objects no longer present will be removed from the announced set.
        
        Args:
            current_objects: Set of currently detected object names
        """
        # Normalize current objects for comparison
        normalized_current = {obj.lower().strip() for obj in current_objects}
        
        # Remove objects that are no longer detected
        self.announced_objects = self.announced_objects.intersection(normalized_current)
    
    def clear_all_announcements(self):
        """Clear all announced objects, forcing all future detections to be announced."""
        self.announced_objects.clear()


# Global voice assistant instance
_voice_assistant: Optional[VoiceAssistant] = None


def get_voice_assistant() -> VoiceAssistant:
    """
    Get or create the global voice assistant instance.
    
    Returns:
        The global VoiceAssistant instance
    """
    global _voice_assistant
    if _voice_assistant is None:
        _voice_assistant = VoiceAssistant()
        _voice_assistant.start()
    return _voice_assistant
