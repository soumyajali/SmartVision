"""
Video Recorder Module for Smart Vision AI
Handles live video recording with annotations
"""

import cv2
import os
from datetime import datetime
from typing import Optional, List
import numpy as np


class VideoRecorder:
    """
    Handles video recording with annotations (bounding boxes, labels, confidence, timestamps).
    """
    
    def __init__(self, output_dir: str = "recordings"):
        """
        Initialize the video recorder.
        
        Args:
            output_dir: Directory to save recorded videos
        """
        self.output_dir = output_dir
        os.makedirs(output_dir, exist_ok=True)
        self.recording = False
        self.video_writer: Optional[cv2.VideoWriter] = None
        self.current_file: Optional[str] = None
        self.frame_count = 0
        self.fps = 30
        self.frame_size = (640, 480)
    
    def start_recording(self, frame_size: tuple = (640, 480), fps: int = 30) -> str:
        """
        Start recording a new video.
        
        Args:
            frame_size: Size of video frames (width, height)
            fps: Frames per second for the video
            
        Returns:
            Path to the video file being recorded
        """
        if self.recording:
            print("Already recording")
            return self.current_file or ""
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"recording_{timestamp}.mp4"
        self.current_file = os.path.join(self.output_dir, filename)
        
        # Initialize video writer
        fourcc = cv2.VideoWriter_fourcc(*'mp4v')
        self.video_writer = cv2.VideoWriter(self.current_file, fourcc, fps, frame_size)
        self.frame_size = frame_size
        self.fps = fps
        self.frame_count = 0
        self.recording = True
        
        print(f"Started recording to {self.current_file}")
        return self.current_file
    
    def add_frame(self, frame: np.ndarray) -> bool:
        """
        Add a frame to the current recording.
        
        Args:
            frame: Frame to add (numpy array)
            
        Returns:
            True if frame added successfully, False otherwise
        """
        if not self.recording or self.video_writer is None:
            return False
        
        try:
            # Resize frame if needed
            if frame.shape[:2][::-1] != self.frame_size:
                frame = cv2.resize(frame, self.frame_size)
            
            self.video_writer.write(frame)
            self.frame_count += 1
            return True
        except Exception as e:
            print(f"Error adding frame: {e}")
            return False
    
    def add_annotated_frame(self, frame: np.ndarray, detections: List[dict]) -> bool:
        """
        Add an annotated frame with bounding boxes, labels, and confidence.
        
        Args:
            frame: Original frame
            detections: List of detection dictionaries with keys:
                       - bbox: [x1, y1, x2, y2]
                       - label: str
                       - confidence: float
            
        Returns:
            True if frame added successfully
        """
        # Create a copy of the frame for annotation
        annotated_frame = frame.copy()
        
        # Add annotations
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        cv2.putText(annotated_frame, timestamp, (10, 30), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
        
        for detection in detections:
            bbox = detection.get('bbox', [0, 0, 0, 0])
            label = detection.get('label', '')
            confidence = detection.get('confidence', 0.0)
            
            x1, y1, x2, y2 = map(int, bbox)
            
            # Draw bounding box
            cv2.rectangle(annotated_frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
            
            # Draw label with confidence
            label_text = f"{label}: {confidence:.2f}"
            cv2.putText(annotated_frame, label_text, (x1, y1 - 10),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)
        
        return self.add_frame(annotated_frame)
    
    def stop_recording(self) -> Optional[str]:
        """
        Stop the current recording and save the video.
        
        Returns:
            Path to the saved video file, or None if no recording was active
        """
        if not self.recording or self.video_writer is None:
            return None
        
        self.video_writer.release()
        self.recording = False
        print(f"Stopped recording. Saved {self.frame_count} frames to {self.current_file}")
        
        saved_file = self.current_file
        self.current_file = None
        self.video_writer = None
        
        return saved_file
    
    def is_recording(self) -> bool:
        """
        Check if currently recording.
        
        Returns:
            True if recording, False otherwise
        """
        return self.recording
    
    def get_frame_count(self) -> int:
        """
        Get the number of frames recorded in the current session.
        
        Returns:
            Number of frames recorded
        """
        return self.frame_count
    
    def get_current_file(self) -> Optional[str]:
        """
        Get the current video file path.
        
        Returns:
            Path to current video file, or None if not recording
        """
        return self.current_file
    
    def cancel_recording(self):
        """
        Cancel the current recording without saving.
        """
        if self.recording and self.video_writer is not None:
            self.video_writer.release()
            if self.current_file and os.path.exists(self.current_file):
                os.remove(self.current_file)
        
        self.recording = False
        self.current_file = None
        self.video_writer = None
        self.frame_count = 0
        print("Recording cancelled")


# Global video recorder instance
_video_recorder: Optional[VideoRecorder] = None


def get_video_recorder() -> VideoRecorder:
    """
    Get or create the global video recorder instance.
    
    Returns:
        The global VideoRecorder instance
    """
    global _video_recorder
    if _video_recorder is None:
        _video_recorder = VideoRecorder()
    return _video_recorder
