import time
from typing import Dict, List, Set, Any

class ObjectTracker:
    """
    Manages state for tracked objects over time to enable 
    reliable counting and event detection (like disappearance).
    """
    def __init__(self, disappearance_grace_period: float = 2.0):
        self.active_tracks: Dict[int, Dict[str, Any]] = {}
        self.unique_objects_seen: Set[int] = set()
        self.disappearance_grace_period = disappearance_grace_period
        
    def update(self, current_detections: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Updates tracking state with current frame's detections.
        Expected input format per detection: 
        {'id': int, 'class_id': int, 'object_name': str, 'confidence': float, 'bbox': list}
        """
        current_time = time.time()
        current_ids = set()
        
        # Update existing tracks or add new ones
        for det in current_detections:
            if 'id' not in det:
                continue
                
            track_id = int(det['id'])
            current_ids.add(track_id)
            
            if track_id not in self.active_tracks:
                # New object
                self.active_tracks[track_id] = {
                    'id': track_id,
                    'class_id': det.get('class_id'),
                    'object_name': det.get('object_name'),
                    'first_seen': current_time,
                    'last_seen': current_time,
                    'last_confidence': det.get('confidence'),
                    'last_bbox': det.get('bbox'),
                    'status': 'active'
                }
                self.unique_objects_seen.add(track_id)
            else:
                # Existing object
                track = self.active_tracks[track_id]
                track['last_seen'] = current_time
                track['last_confidence'] = det.get('confidence')
                track['last_bbox'] = det.get('bbox')
                track['status'] = 'active'
                
        # Check for disappeared objects
        disappeared_ids = []
        for track_id, track in self.active_tracks.items():
            if track_id not in current_ids:
                if current_time - track['last_seen'] > self.disappearance_grace_period:
                    track['status'] = 'lost'
                    disappeared_ids.append(track_id)
                else:
                    track['status'] = 'missing_temporarily'
                    
        # Remove completely lost objects from active tracking after grace period
        # They remain in unique_objects_seen for total counting
        for track_id in disappeared_ids:
            del self.active_tracks[track_id]
            
        return current_detections

    def get_current_counts(self) -> Dict[str, int]:
        """Returns the count of currently visible/active objects by class."""
        counts = {}
        for track in self.active_tracks.values():
            if track['status'] == 'active':
                name = track['object_name']
                counts[name] = counts.get(name, 0) + 1
        return counts
        
    def get_total_unique_counts(self) -> int:
        """Returns the total number of unique objects observed."""
        return len(self.unique_objects_seen)

    def is_object_disappeared(self, track_id: int) -> bool:
        """Checks if a previously known object is now lost."""
        return track_id in self.unique_objects_seen and track_id not in self.active_tracks
