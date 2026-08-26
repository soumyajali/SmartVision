# Smart Vision Architecture

## Overview

Smart Vision is designed as a Flutter mobile application using a layered architecture:

1. UI Layer
   - Splash and Home navigation screens
   - Detection, history, stats, and settings views
2. Camera Layer
   - Camera lifecycle management
   - Flash and zoom controls
3. AI Layer
   - TensorFlow Lite inference service
   - YOLOv8 model runtime integration
4. Data Layer
   - SQLite detection history persistence
   - Search and analytics support

## Planned Execution Pipeline

- Capture camera frames
- Run inference through the TensorFlow Lite model
- Decode model predictions into bounding boxes and labels
- Announce recognized objects with text-to-speech
- Store detected results in SQLite for history and stats
