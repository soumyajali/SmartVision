# Installation Guide

## Prerequisites

- Flutter SDK 3.3+ installed on your machine
- Android Studio or Xcode for device builds
- Python 3.10+ for model export scripts

## Steps

1. Clone the repository.
2. Open the `app/` folder with Flutter.
3. Run `flutter pub get`.
4. Place your exported `model.tflite` and `labels.txt` in the `app/assets/` folder.
5. Build and run the app on Android or iOS.

## Notes

The current workspace environment does not have Flutter installed, so these build steps are intended for the developer machine where the SDK is available.
