# Smart Vision – Real-Time Object Detection

This repository now contains the initial Flutter foundation for a mobile real-time object detection app using YOLOv8 and TensorFlow Lite.

## Project Structure

- `app/` – Flutter mobile application code
- `ai/` – Python scripts for model training and export
- `docs/` – project documentation

## Current Foundation

The Flutter scaffold includes:
- Material 3 themed app entry point
- Splash screen
- Bottom navigation home flow
- Placeholder camera, search, history, stats, and settings screens
- AI, camera, model, and database service stubs
- Asset layout for the TensorFlow Lite model and labels file

## Next Phases

1. Integrate the live camera preview
2. Add TensorFlow Lite model loading and inference
3. Render bounding boxes and confidence overlays
4. Add voice announcements and SQLite history storage
5. Finalize the polished UI and package the project

## Notes

The current environment does not have the Flutter SDK on PATH, so this scaffold is prepared for a machine with Flutter installed to build and run the app locally.
