from pathlib import Path

import cv2

from services.face_service import FACE_MATCH_THRESHOLD, FaceService


DATA_DIR = Path(__file__).parent / "data"


def test_recognizes_registered_name_and_preserves_underscores(tmp_path):
    image = cv2.imread(str(DATA_DIR / "face_registered.jpg"))
    service = FaceService(str(tmp_path))

    service.register_face("Mary_Jane", image)

    recognitions = service.recognize_faces(image)
    assert recognitions
    assert recognitions[0][0] == "Mary_Jane"


def test_recognizes_registered_face_in_small_camera_frame(tmp_path):
    image = cv2.imread(str(DATA_DIR / "face_registered.jpg"))
    service = FaceService(str(tmp_path))
    service.register_face("Mary_Jane", image)
    height, width = image.shape[:2]
    small_frame = cv2.resize(image, (64, round(height * 64 / width)))

    recognitions = service.recognize_faces(small_frame)

    assert recognitions
    assert recognitions[0][0] == "Mary_Jane"


def test_unregistered_face_is_not_assigned_registered_identity(tmp_path):
    registered_image = cv2.imread(str(DATA_DIR / "face_registered.jpg"))
    unregistered_image = cv2.imread(str(DATA_DIR / "face_unregistered.jpg"))
    service = FaceService(str(tmp_path))
    service.register_face("Sowmya", registered_image)

    recognitions = service.recognize_faces(unregistered_image)

    assert recognitions
    assert recognitions[0][0] == "Not Registered"


def test_detected_face_is_not_registered_when_registry_is_empty(tmp_path):
    image = cv2.imread(str(DATA_DIR / "face_registered.jpg"))
    service = FaceService(str(tmp_path))

    recognitions = service.recognize_faces(image)

    assert recognitions
    assert recognitions[0][0] == "Not Registered"


def test_extract_face_embeddings_match_the_reference_face_only(tmp_path):
    reference_image = cv2.imread(str(DATA_DIR / "face_registered.jpg"))
    different_image = cv2.imread(str(DATA_DIR / "face_unregistered.jpg"))
    service = FaceService(str(tmp_path))

    reference_faces = service.extract_face_embeddings(reference_image, 1280)
    different_faces = service.extract_face_embeddings(different_image, 1280)

    assert reference_faces
    assert different_faces
    assert service.compare_face_embeddings(
        reference_faces[0][1], reference_faces[0][1]
    ) >= FACE_MATCH_THRESHOLD
    assert service.compare_face_embeddings(
        reference_faces[0][1], different_faces[0][1]
    ) < FACE_MATCH_THRESHOLD
    assert reference_faces[0][0][2] > reference_faces[0][0][0]
    assert reference_faces[0][0][3] > reference_faces[0][0][1]

    distant_face = cv2.resize(reference_image, (120, 90))
    video_frame = cv2.copyMakeBorder(
        distant_face,
        400,
        400,
        900,
        900,
        cv2.BORDER_CONSTANT,
        value=(80, 80, 80),
    )
    video_faces = service.extract_face_embeddings(video_frame, 1280)

    assert video_faces
    assert max(
        service.compare_face_embeddings(reference_faces[0][1], encoding)
        for _, encoding in video_faces
    ) >= FACE_MATCH_THRESHOLD


def test_recognizes_multiple_faces_in_a_single_frame(tmp_path):
    image = cv2.imread(str(DATA_DIR / "face_registered.jpg"))
    service = FaceService(str(tmp_path))
    service.register_face("Sowmya", image)
    two_faces = cv2.hconcat([image, image])

    recognitions = service.recognize_faces(two_faces)

    assert [name for name, _, _ in recognitions].count("Sowmya") == 2
    assert "Not Registered" in [name for name, _, _ in recognitions]


def test_recognizes_each_registered_person_in_a_multi_person_test_image(tmp_path):
    images = [
        cv2.imread(str(DATA_DIR / "face_registered.jpg")),
        cv2.imread(str(DATA_DIR / "face_unregistered.jpg")),
    ]
    service = FaceService(str(tmp_path))
    face_crops = []

    for name, image in zip(("Alice", "Bob"), images):
        prepared_image, detections = service._detect_faces(image)
        largest_face = max(detections, key=lambda face: face[2] * face[3])
        x, y, width, height = map(int, largest_face[:4])
        padding = int(0.15 * max(width, height))
        face_crop = prepared_image[
            max(0, y - padding):min(prepared_image.shape[0], y + height + padding),
            max(0, x - padding):min(prepared_image.shape[1], x + width + padding),
        ]
        face_crops.append(cv2.resize(face_crop, (240, 240)))
        service.register_face(name, image)

    multi_person_image = cv2.copyMakeBorder(
        cv2.hconcat(face_crops),
        10,
        10,
        10,
        10,
        cv2.BORDER_CONSTANT,
        value=(255, 255, 255),
    )

    recognitions = service.recognize_faces(multi_person_image)

    assert {name for name, _, _ in recognitions} == {"Alice", "Bob"}


def test_recognizes_registered_face_after_scene_lighting_and_clothing_change(tmp_path):
    image = cv2.imread(str(DATA_DIR / "face_registered.jpg"))
    service = FaceService(str(tmp_path))
    service.register_face("Sowmya", image)

    height, width = image.shape[:2]
    transform = cv2.getRotationMatrix2D((width / 2, height / 2), 12, 1.0)
    changed_scene = cv2.warpAffine(
        image,
        transform,
        (width, height),
        borderValue=(90, 90, 90),
    )
    changed_scene = cv2.convertScaleAbs(changed_scene, alpha=0.75, beta=25)
    cv2.rectangle(changed_scene, (0, 405), (width, height), (35, 80, 170), -1)

    recognitions = service.recognize_faces(changed_scene)

    assert recognitions
    assert recognitions[0][0] == "Sowmya"


def test_deleting_person_removes_all_samples_and_retrains(tmp_path):
    image = cv2.imread(str(DATA_DIR / "face_registered.jpg"))
    service = FaceService(str(tmp_path))
    service.register_face("Mary_Jane", image)
    service.register_face("Mary_Jane", image)
    service.register_face("Sowmya", image)

    deleted_files = service.delete_face("Mary_Jane")

    assert len(deleted_files) == 2
    assert not list(tmp_path.glob("Mary_Jane_*.jpg"))
    assert list(tmp_path.glob("Sowmya_*.jpg"))
    assert set(service.label_map.values()) == {"Sowmya"}
    assert service.recognize_face_details(image)[0] == "Sowmya"
    assert service.delete_face("Mary_Jane") == []


def test_does_not_assign_another_person_for_a_weak_match(tmp_path):
    registered_image = cv2.imread(str(DATA_DIR / "face_unregistered.jpg"))
    different_person_image = cv2.imread(str(DATA_DIR / "face_registered.jpg"))
    service = FaceService(str(tmp_path))
    service.register_face("Ruchi", different_person_image)

    recognitions = service.recognize_faces(registered_image)

    assert recognitions
    assert recognitions[0][0] == "Not Registered"


def test_ambiguous_match_between_identities_is_not_registered(tmp_path):
    image = cv2.imread(str(DATA_DIR / "face_registered.jpg"))
    service = FaceService(str(tmp_path))
    service.register_face("Sowmya", image)
    service.register_face("Ruchi", image)

    recognitions = service.recognize_faces(image)

    assert recognitions
    assert recognitions[0][0] == "Not Registered"


def test_registration_requires_a_detectable_face(tmp_path):
    service = FaceService(str(tmp_path))
    image = cv2.imread(str(DATA_DIR / "text_image.png"))

    try:
        service.register_face("Sowmya", image)
    except ValueError as error:
        assert "No clear face" in str(error)
    else:
        raise AssertionError("Registration should reject an image without a face.")

    assert not list(tmp_path.iterdir())
