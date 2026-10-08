import numpy as np
import pytest
import time
from core.tracker import ObjectTracker
from core.border_analytics import ZoneManager, LoiteringTimer
from events.alert_manager import AlertManager
from core_utils import (
    AdaptiveEngine, LowLightEnhancer, DistanceEstimator,
    UnknownObjectDetector, AIAssistant, VisionChatbot
)
from ai.face.faiss_store import FAISSStore

def test_object_tracker_and_counting():
    """Tests tracking IDs across consecutive frames and counting logic in ObjectTracker"""
    tracker = ObjectTracker(disappearance_grace_period=0.5)

    # Frame 1: 2 objects (id 1: person, id 2: laptop)
    frame1_detections = [
        {"id": 1, "class_id": 0, "object_name": "person", "confidence": 0.9, "bbox": [10, 10, 50, 50]},
        {"id": 2, "class_id": 1, "object_name": "laptop", "confidence": 0.85, "bbox": [100, 100, 150, 150]}
    ]
    tracker.update(frame1_detections)
    counts1 = tracker.get_current_counts()
    assert counts1.get("person") == 1
    assert counts1.get("laptop") == 1
    assert tracker.get_total_unique_counts() == 2

    # Frame 2: Object 1 moved slightly, Object 2 still present
    frame2_detections = [
        {"id": 1, "class_id": 0, "object_name": "person", "confidence": 0.92, "bbox": [15, 15, 55, 55]},
        {"id": 2, "class_id": 1, "object_name": "laptop", "confidence": 0.84, "bbox": [100, 100, 150, 150]}
    ]
    tracker.update(frame2_detections)
    assert tracker.active_tracks[1]["last_bbox"] == [15, 15, 55, 55]
    assert tracker.get_total_unique_counts() == 2

    # Frame 3: Object 2 disappeared
    frame3_detections = [
        {"id": 1, "class_id": 0, "object_name": "person", "confidence": 0.91, "bbox": [20, 20, 60, 60]}
    ]
    tracker.update(frame3_detections)
    # Wait for grace period to expire
    time.sleep(0.6)
    tracker.update(frame3_detections)
    assert tracker.is_object_disappeared(2) is True
    assert tracker.get_current_counts().get("laptop", 0) == 0

def test_zone_manager_and_loitering():
    """Tests restricted-area entry and loitering trigger in ZoneManager and LoiteringTimer"""
    zm = ZoneManager()
    zm.add_zone("Restricted Zone A", [(0, 0), (100, 0), (100, 100), (0, 100)])

    # Box inside zone
    inside_bbox = (10, 10, 50, 50)
    intrusions = zm.check_intrusion(inside_bbox)
    assert "Restricted Zone A" in intrusions

    # Box outside zone
    outside_bbox = (200, 200, 250, 250)
    assert len(zm.check_intrusion(outside_bbox)) == 0

    # Test loitering timer
    lt = LoiteringTimer(threshold_seconds=0.3)
    track_id = 99
    # First update: inside zone
    alerts = lt.update(track_id, ["Restricted Zone A"])
    assert len(alerts) == 0  # not yet threshold
    time.sleep(0.35)
    # Second update: after threshold
    alerts_after = lt.update(track_id, ["Restricted Zone A"])
    assert "Restricted Zone A" in alerts_after

def test_alert_manager_debounce():
    """Tests alert triggering and cooldown in AlertManager"""
    am = AlertManager(cooldown_seconds=0.5)
    alert1 = am.trigger_alert("Intrusion", "Person", "Person entered restricted area", "critical")
    assert alert1 is not None
    assert alert1["event_type"] == "Intrusion"

    # Immediate second alert for same key should be suppressed by cooldown
    alert2 = am.trigger_alert("Intrusion", "Person", "Person entered restricted area", "critical")
    assert alert2 is None

    # After cooldown, should trigger again
    time.sleep(0.55)
    alert3 = am.trigger_alert("Intrusion", "Person", "Person entered restricted area", "critical")
    assert alert3 is not None

def test_faiss_store():
    """Tests FAISSStore add and similarity search"""
    import tempfile
    idx_path = tempfile.mktemp(suffix=".faiss")
    meta_path = tempfile.mktemp(suffix=".json")

    store = FAISSStore(embedding_dim=128, index_file=idx_path, meta_file=meta_path)
    
    # Create two random normalized embeddings
    v1 = np.random.randn(128).astype(np.float32)
    v1 /= np.linalg.norm(v1)
    
    v2 = np.random.randn(128).astype(np.float32)
    v2 /= np.linalg.norm(v2)

    store.add_embedding(v1, "Alice")
    store.add_embedding(v2, "Bob")

    # Search with v1
    results = store.search(v1, k=1, threshold=0.5)
    assert len(results) > 0
    assert results[0]["name"] == "Alice"
    assert results[0]["confidence"] > 0.99

def test_adaptive_processing():
    """Tests AdaptiveEngine scaling down resolution under high processing time (low FPS)"""
    engine = AdaptiveEngine(target_fps=20)
    dummy_frame = np.zeros((480, 640, 3), dtype=np.uint8)

    # Simulate 15 slow frames (e.g. 0.2s each = 5 FPS, below 20 * 0.8 = 16)
    for _ in range(15):
        scaled = engine.adapt(dummy_frame, processing_time=0.2)
    
    assert engine.current_scale < 1.0
    assert scaled.shape[0] < 480
    assert scaled.shape[1] < 640

def test_low_light_enhancer():
    """Tests LowLightEnhancer CLAHE enhancement"""
    dark_image = np.ones((100, 100, 3), dtype=np.uint8) * 30
    enhanced = LowLightEnhancer.enhance(dark_image)
    assert enhanced.shape == dark_image.shape
    # Enhancing dark image increases contrast / mean in L-channel
    assert enhanced.mean() >= dark_image.mean()

def test_distance_estimator():
    """Tests DistanceEstimator inversely proportional distance"""
    # Large bbox (close object)
    dist_close = DistanceEstimator.estimate([0, 0, 100, 400], img_height=500)
    # Small bbox (far object)
    dist_far = DistanceEstimator.estimate([0, 0, 50, 50], img_height=500)
    assert dist_close < dist_far

def test_unknown_object_detector():
    """Tests UnknownObjectDetector flags low-confidence detections as Unknown"""
    detector = UnknownObjectDetector(confidence_threshold=0.4)
    detections = [
        {"id": 1, "object_name": "person", "confidence": 0.85},
        {"id": 2, "object_name": "bottle", "confidence": 0.25}
    ]
    results = detector.detect(detections)
    assert results[0]["object_name"] == "person"
    assert results[1]["object_name"] == "Unknown Object"
