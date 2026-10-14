import cv2
import numpy as np

from core_utils import compare_person_appearance, get_person_appearance_descriptor, scale_bbox


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


def test_person_appearance_tolerates_changed_vertical_pose():
    reference = make_person_image([(20, 30, 180), (30, 160, 30), (180, 40, 20)])
    side_view = make_person_image([(30, 160, 30), (180, 40, 20), (20, 30, 180)])

    score = compare_person_appearance(
        get_person_appearance_descriptor(reference),
        get_person_appearance_descriptor(side_view),
    )

    assert score > 0.8


def test_person_appearance_rejects_different_clothing_colors():
    reference = make_person_image([(20, 30, 180)] * 3)
    different_person = make_person_image([(180, 40, 20)] * 3)

    score = compare_person_appearance(
        get_person_appearance_descriptor(reference),
        get_person_appearance_descriptor(different_person),
    )

    assert score < 0.2


def test_person_appearance_handles_empty_input():
    assert get_person_appearance_descriptor(np.empty((0, 0, 3), dtype=np.uint8)) is None
    assert compare_person_appearance(None, None) == 0.0


def test_full_resolution_person_box_scales_to_review_preview():
    person_box = (600, 225, 1200, 900)

    preview_box = scale_bbox(person_box, (1080, 1920, 3), (640, 480))

    assert preview_box == (200, 100, 400, 400)


def test_person_box_scaling_clips_to_preview_bounds():
    preview_box = scale_bbox((-20, 0, 2000, 1200), (1080, 1920, 3), (640, 480))

    assert preview_box == (0, 0, 640, 480)
