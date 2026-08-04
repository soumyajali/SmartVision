"""
Utils module for Smart Vision AI
Contains performance monitoring, OCR, QR scanner, AI assistant, reports, and video recording
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from core_utils import (
    PerformanceMonitor, OCRReader, QRBarcodeScanner,
    AIAssistant, ReportGenerator
)
from .recorder import VideoRecorder, get_video_recorder

__all__ = [
    'PerformanceMonitor', 'OCRReader', 'QRBarcodeScanner',
    'AIAssistant', 'ReportGenerator', 'VideoRecorder', 'get_video_recorder'
]
