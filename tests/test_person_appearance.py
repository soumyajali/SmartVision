import cv2
import numpy as np

from core_utils import (
    compare_person_appearance,
    face_landmarks_to_location,
    get_person_appearance_descriptor,
    scale_bbox,
    select_best_person_match,
)


def make_person_image(colors):
    image = np.zeros((120, 60, 3), dtype=np.uint8)
    for index, color in enumerate(colors):
        image[index * 40:(index + 1) * 40, 8:52] = color
    return image


def test_person_appearance_matches_same_clothing_at_different_scales():
    reference = make_person_image([(20, 30, 180), (30, 160, 30), (180, 40, 20)])
    candidate = cv2.resize(reference, (30, 60), interpolation=cv2.INTER_AREA)

    score = compare_person_appearance(
        get_person_appearance_descriptor(reference),
        get_person_appearance_descriptor(candidate),
    )

    assert score > 0.9


def test_person_appearance_tolerates_reversed_vertical_regions():
    reference = make_person_image([(20, 30, 180), (30, 160, 30), (180, 40, 20)])
    turned_pose = make_person_image([(180, 40, 20), (30, 160, 30), (20, 30, 180)])

    score = compare_person_appearance(
        get_person_appearance_descriptor(reference),
        get_person_appearance_descriptor(turned_pose),
    )

    assert score > 0.8


def test_person_appearance_rejects_different_clothing_colors():
    reference = make_person_image([(20, 30, 180)] * 3)
    different_clothing = make_person_image([(180, 40, 20)] * 3)

    score = compare_person_appearance(
        get_person_appearance_descriptor(reference),
        get_person_appearance_descriptor(different_clothing),
    )

    assert score < 0.2


def test_person_appearance_handles_empty_input():
    assert get_person_appearance_descriptor(np.empty((0, 0, 3), dtype=np.uint8)) is None
    assert compare_person_appearance(None, None) == 0.0


def test_face_landmarks_convert_to_padded_face_recognition_box():
    landmarks = np.asarray([[0.2, 0.3], [0.4, 0.6]], dtype=np.float32)

    location = face_landmarks_to_location(landmarks, (100, 200, 3), padding=0.2)

    assert location == (24, 88, 66, 32)


def test_face_landmark_box_clips_at_image_edges():
    landmarks = np.asarray([[0.0, 0.0], [0.2, 0.2]], dtype=np.float32)

    location = face_landmarks_to_location(landmarks, (100, 200, 3), padding=0.5)

    assert location == (0, 60, 30, 0)


def test_invalid_face_landmarks_do_not_create_a_box():
    assert face_landmarks_to_location([], (100, 200, 3)) is None
    assert face_landmarks_to_location([[0.2, 0.2], [0.2, 0.2]], (100, 200, 3)) is None


def test_full_resolution_person_box_scales_to_review_preview():
    person_box = (600, 225, 1200, 900)

    preview_box = scale_bbox(person_box, (1080, 1920, 3), (640, 480))

    assert preview_box == (200, 100, 400, 400)


def test_person_box_scaling_clips_to_preview_bounds():
    preview_box = scale_bbox((-20, 0, 2000, 1200), (1080, 1920, 3), (640, 480))

    assert preview_box == (0, 0, 640, 480)


def test_face_match_is_preferred_over_higher_scoring_appearance_match():
    face_match = {"match_type": "face", "sim": 0.72}
    appearance_match = {"match_type": "appearance", "sim": 0.95}

    assert select_best_person_match([appearance_match, face_match]) is face_match


def test_highest_similarity_face_match_is_selected():
    weaker_face_match = {"match_type": "face", "sim": 0.72}
    stronger_face_match = {"match_type": "face", "sim": 0.89}

    assert select_best_person_match([weaker_face_match, stronger_face_match]) is stronger_face_match


def test_non_face_match_is_rejected_when_no_face_match_exists():
    appearance_match = {"match_type": "appearance", "sim": 0.61}

    try:
        select_best_person_match([appearance_match])
    except ValueError as exc:
        assert str(exc) == "At least one face match is required."
    else:
        raise AssertionError("A non-face match must not be selected as a person match.")
