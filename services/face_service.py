import hashlib
import os
import re
import shutil
import subprocess
import tempfile
from pathlib import Path
from urllib.error import URLError
from urllib.request import urlopen

import cv2


FACE_MATCH_THRESHOLD = 0.363
FACE_MATCH_MARGIN = 0.05
MIN_FACE_SIZE = 16
MAX_DETECTION_DIMENSION = 640

FACE_MODELS = {
    "yunet": (
        "face_detection_yunet_2023mar.onnx",
        "https://github.com/opencv/opencv_zoo/raw/refs/heads/main/"
        "models/face_detection_yunet/face_detection_yunet_2023mar.onnx",
        "8f2383e4dd3cfbb4553ea8718107fc0423210dc964f9f4280604804ed2552fa4",
    ),
    "sface": (
        "face_recognition_sface_2021dec.onnx",
        "https://github.com/opencv/opencv_zoo/raw/refs/heads/main/"
        "models/face_recognition_sface/face_recognition_sface_2021dec.onnx",
        "0ba9fbfa01b5270c96627c4ef784da859931e02f04419c829e83484087c34e79",
    ),
}


def _sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as model_file:
        for block in iter(lambda: model_file.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _ensure_model(model_dir, model_config):
    filename, url, expected_hash = model_config
    model_path = model_dir / filename
    if model_path.is_file() and _sha256(model_path) == expected_hash:
        return str(model_path)

    model_dir.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{filename}.", suffix=".download", dir=model_dir
    )
    os.close(descriptor)
    temporary_path = Path(temporary_name)
    try:
        curl_path = shutil.which("curl.exe") if os.name == "nt" else None
        if curl_path:
            result = subprocess.run(
                [
                    curl_path,
                    "--location",
                    "--fail",
                    "--silent",
                    "--show-error",
                    "--max-time",
                    "300",
                    "--output",
                    str(temporary_path),
                    url,
                ],
                capture_output=True,
                text=True,
                timeout=310,
                check=False,
            )
            if result.returncode:
                raise RuntimeError(
                    f"Could not download face model {filename}: "
                    f"{result.stderr.strip() or 'curl failed'}"
                )
        else:
            with urlopen(url, timeout=300) as response, temporary_path.open(
                "wb"
            ) as output:
                shutil.copyfileobj(response, output)
        if _sha256(temporary_path) != expected_hash:
            raise RuntimeError(
                f"Downloaded face model {filename} failed its SHA-256 check."
            )
        os.replace(temporary_path, model_path)
    except (OSError, URLError, subprocess.TimeoutExpired) as error:
        raise RuntimeError(
            f"Could not download the required face-recognition model {filename}. "
            f"Check your internet connection and retry; the model cache is {model_dir}."
        ) from error
    finally:
        temporary_path.unlink(missing_ok=True)

    return str(model_path)


class FaceService:
    def __init__(self, faces_dir="known_faces"):
        self.faces_dir = faces_dir
        os.makedirs(self.faces_dir, exist_ok=True)
        self.face_detector = None
        self.face_recognizer = None
        self.label_map = {}
        self.person_embeddings = {}
        self.is_trained = False
        self.recognition_history = {}

        cache_root = Path(
            os.environ.get("LOCALAPPDATA", str(Path.home() / ".cache"))
        )
        model_dir = cache_root / "SmartVision" / "face_models"
        if not hasattr(cv2, "FaceDetectorYN_create") or not hasattr(
            cv2, "FaceRecognizerSF_create"
        ):
            raise RuntimeError(
                "Face recognition requires an OpenCV build with YuNet and SFace support."
            )

        try:
            yunet_path = _ensure_model(model_dir, FACE_MODELS["yunet"])
            sface_path = _ensure_model(model_dir, FACE_MODELS["sface"])
            self.face_detector = cv2.FaceDetectorYN_create(
                yunet_path, "", (320, 320), 0.7, 0.3, 5000
            )
            self.face_recognizer = cv2.FaceRecognizerSF_create(sface_path, "")
        except Exception as exc:  # pragma: no cover - offline environment fallback
            print(
                "Warning: Face recognition models are unavailable. "
                f"Falling back to offline-safe mode: {exc}"
            )
            self.face_detector = None
            self.face_recognizer = None
            return

        self.train_model()

    def _prepare_frame(self, frame):
        if frame is None or frame.size == 0:
            return None
        if len(frame.shape) == 2:
            return cv2.cvtColor(frame, cv2.COLOR_GRAY2BGR)
        if frame.shape[2] == 4:
            return cv2.cvtColor(frame, cv2.COLOR_BGRA2BGR)
        return frame

    def is_available(self):
        return self.face_detector is not None and self.face_recognizer is not None

    def _detect_faces(self, frame, max_detection_dimension=MAX_DETECTION_DIMENSION):
        if not self.is_available():
            return self._prepare_frame(frame), []

        if max_detection_dimension <= 0:
            raise ValueError("Maximum face detection dimension must be positive.")

        image = self._prepare_frame(frame)
        if image is None:
            return image, []

        height, width = image.shape[:2]
        scale = min(1.0, max_detection_dimension / max(height, width))
        detector_image = (
            image
            if scale == 1.0
            else cv2.resize(
                image,
                (max(1, round(width * scale)), max(1, round(height * scale))),
                interpolation=cv2.INTER_AREA,
            )
        )
        detector_height, detector_width = detector_image.shape[:2]
        self.face_detector.setInputSize((detector_width, detector_height))
        _, detections = self.face_detector.detect(detector_image)
        if detections is None:
            return image, []

        if scale != 1.0:
            detections = detections.copy()
            detections[:, :14] /= scale
        faces = [
            detection
            for detection in detections
            if detection[2] >= MIN_FACE_SIZE and detection[3] >= MIN_FACE_SIZE
        ]
        return image, faces

    def _embedding(self, image, detection):
        aligned_face = self.face_recognizer.alignCrop(image, detection)
        return self.face_recognizer.feature(aligned_face).reshape(-1)

    def extract_face_embeddings(
        self, frame, max_detection_dimension=MAX_DETECTION_DIMENSION
    ):
        """Return face boxes and SFace embeddings for a frame."""
        image, detections = self._detect_faces(frame, max_detection_dimension)
        if image is None:
            return []

        candidates = []
        for detection in sorted(
            detections, key=lambda face: face[2] * face[3], reverse=True
        ):
            x, y, width, height = detection[:4]
            box = (
                int(round(x)),
                int(round(y)),
                int(round(x + width)),
                int(round(y + height)),
            )
            candidates.append((box, self._embedding(image, detection)))
        return candidates

    def compare_face_embeddings(self, first, second):
        """Return the cosine similarity between two SFace embeddings."""
        if not self.is_available():
            raise RuntimeError("Face recognition is unavailable.")

        return float(
            self.face_recognizer.match(
                first.reshape(1, -1),
                second.reshape(1, -1),
                cv2.FaceRecognizerSF_FR_COSINE,
            )
        )

    def train_model(self):
        if not self.is_available():
            self.label_map = {}
            self.person_embeddings = {}
            self.is_trained = False
            self.recognition_history.clear()
            return

        self.label_map = {}
        self.person_embeddings = {}

        for filename in sorted(os.listdir(self.faces_dir)):
            if not filename.lower().endswith((".png", ".jpg", ".jpeg")):
                continue
            name = re.sub(r"_\d+$", "", os.path.splitext(filename)[0])
            filepath = os.path.join(self.faces_dir, filename)
            image = cv2.imread(filepath)
            if image is None:
                continue

            image, detections = self._detect_faces(image)
            if not detections:
                continue
            largest_face = max(detections, key=lambda face: face[2] * face[3])
            self.person_embeddings.setdefault(name, []).append(
                self._embedding(image, largest_face)
            )

        self.label_map = {
            label_id: name
            for label_id, name in enumerate(sorted(self.person_embeddings))
        }
        self.is_trained = bool(self.person_embeddings)
        self.recognition_history.clear()

    def register_face(self, name, image):
        """Save a face image and rebuild the identity embedding gallery."""
        if not self.is_available():
            raise RuntimeError(
                "Face recognition is unavailable because the required model files could not be downloaded."
            )

        prepared_image, detections = self._detect_faces(image)
        if not detections:
            raise ValueError("No clear face was detected in the registration photo.")

        existing_numbers = [
            int(match.group(1))
            for filename in os.listdir(self.faces_dir)
            if (
                match := re.fullmatch(
                    re.escape(name) + r"_(\d+)\.(?:png|jpe?g)",
                    filename,
                    re.IGNORECASE,
                )
            )
        ]
        count = max(existing_numbers, default=-1) + 1
        filepath = os.path.join(self.faces_dir, f"{name}_{count}.jpg")

        if not cv2.imwrite(filepath, prepared_image):
            raise OSError(f"Could not save the registration photo to {filepath}.")
        self.train_model()
        return filepath

    def delete_face(self, name):
        """Delete all registered images for one person and rebuild the gallery."""
        deleted_files = []
        for filename in os.listdir(self.faces_dir):
            stem, extension = os.path.splitext(filename)
            registered_name = re.sub(r"_\d+$", "", stem)
            if (
                extension.lower() in (".png", ".jpg", ".jpeg")
                and registered_name == name
            ):
                filepath = os.path.join(self.faces_dir, filename)
                os.remove(filepath)
                deleted_files.append(filepath)

        if deleted_files:
            self.train_model()
        return deleted_files

    def recognize_faces(
        self, frame, threshold=FACE_MATCH_THRESHOLD, min_margin=FACE_MATCH_MARGIN
    ):
        """Return registered identities only for strong, unambiguous SFace matches."""
        if not self.is_available():
            return []

        image, detections = self._detect_faces(frame)
        if image is None:
            return []

        recognitions = []
        detections = sorted(
            detections, key=lambda face: face[2] * face[3], reverse=True
        )
        for detection in detections:
            embedding = self._embedding(image, detection)
            scores = sorted(
                (
                    max(
                        float(
                            self.face_recognizer.match(
                                embedding.reshape(1, -1),
                                known_embedding.reshape(1, -1),
                                cv2.FaceRecognizerSF_FR_COSINE,
                            )
                        )
                        for known_embedding in known_embeddings
                    ),
                    name,
                )
                for name, known_embeddings in self.person_embeddings.items()
            )
            scores.reverse()

            similarity = scores[0][0] if scores else 0.0
            clearly_best = len(scores) == 1 or (
                len(scores) > 1 and similarity - scores[1][0] >= min_margin
            )
            name = (
                scores[0][1]
                if scores and similarity >= threshold and clearly_best
                else "Not Registered"
            )
            x, y, width, height = detection[:4]
            recognitions.append(
                (
                    name,
                    similarity,
                    (
                        int(round(x)),
                        int(round(y)),
                        int(round(width)),
                        int(round(height)),
                    ),
                )
            )

        return recognitions

    def recognize(
        self,
        frame,
        person_box=None,
        track_id=None,
        threshold=FACE_MATCH_THRESHOLD,
        required_hits=3,
    ):
        """Recognize a face in a person crop, optionally requiring consistent track hits."""
        if not self.is_available():
            return None

        if person_box is not None:
            x1, y1, x2, y2 = (int(value) for value in person_box)
            height, width = frame.shape[:2]
            x1, y1 = max(0, x1), max(0, y1)
            x2, y2 = min(width, x2), min(height, y2)
            frame = frame[y1:y2, x1:x2]

        recognitions = self.recognize_faces(frame, threshold=threshold)
        if not recognitions:
            if track_id is not None:
                self.recognition_history.pop(track_id, None)
            return None

        name = recognitions[0][0]
        if name == "Not Registered":
            if track_id is not None:
                self.recognition_history.pop(track_id, None)
            return None
        if track_id is None:
            return name

        history = self.recognition_history.setdefault(track_id, [])
        history.append(name)
        del history[:-required_hits * 2]
        return name if history.count(name) >= required_hits else None

    def recognize_face_details(
        self, frame, threshold=FACE_MATCH_THRESHOLD, min_margin=FACE_MATCH_MARGIN
    ):
        """Return the best face as (name, cosine similarity, bounding box)."""
        if not self.is_available():
            return None, None, None

        recognitions = self.recognize_faces(frame, threshold, min_margin)
        if recognitions:
            return recognitions[0]
        return None, None, None
