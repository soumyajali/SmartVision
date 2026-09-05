import time
from typing import List, Tuple, Dict
from shapely.geometry import Point, Polygon
import cv2
import numpy as np

class ZoneManager:
    def __init__(self):
        # Dictionary of zones. Key: zone name, Value: Polygon object
        self.zones: Dict[str, Polygon] = {}
        # Keep track of raw coordinates for drawing
        self.zone_coords: Dict[str, List[Tuple[int, int]]] = {}

    def add_zone(self, name: str, coordinates: List[Tuple[int, int]]):
        """Add a virtual perimeter zone."""
        if len(coordinates) >= 3:
            self.zones[name] = Polygon(coordinates)
            self.zone_coords[name] = coordinates

    def remove_zone(self, name: str):
        """Remove a virtual perimeter zone."""
        if name in self.zones:
            del self.zones[name]
        if name in self.zone_coords:
            del self.zone_coords[name]

    def check_intrusion(self, bbox: Tuple[int, int, int, int], zone_name: str = None) -> List[str]:
        """
        Check if the center of a bounding box is inside any zone.
        Returns a list of zone names the object has intruded.
        """
        x1, y1, x2, y2 = bbox
        center = Point((x1 + x2) / 2.0, (y1 + y2) / 2.0)
        
        intruded_zones = []
        zones_to_check = [zone_name] if zone_name and zone_name in self.zones else self.zones.keys()
        
        for name in zones_to_check:
            if self.zones[name].contains(center):
                intruded_zones.append(name)
                
        return intruded_zones

    def draw_zones(self, frame: np.ndarray, active_intrusions: List[str] = None):
        """Draw configured zones on the image frame."""
        if active_intrusions is None:
            active_intrusions = []
            
        for name, coords in self.zone_coords.items():
            pts = np.array(coords, np.int32)
            pts = pts.reshape((-1, 1, 2))
            
            # Use red if there is an active intrusion in this zone, otherwise use green
            color = (0, 0, 255) if name in active_intrusions else (0, 255, 0)
            thickness = 3 if name in active_intrusions else 2
            
            cv2.polylines(frame, [pts], isClosed=True, color=color, thickness=thickness)
            
            # Add zone label
            cv2.putText(frame, name, (coords[0][0], max(0, coords[0][1] - 10)), 
                        cv2.FONT_HERSHEY_SIMPLEX, 0.6, color, 2)
        return frame


class LoiteringTimer:
    def __init__(self, threshold_seconds: float = 10.0):
        self.threshold_seconds = threshold_seconds
        # track_id -> {zone_name: entry_time}
        self.entry_times: Dict[int, Dict[str, float]] = {}
        # track_id -> [alerted_zones] to prevent spamming
        self.alerted: Dict[int, List[str]] = {}

    def update(self, track_id: int, intruded_zones: List[str]) -> List[str]:
        """
        Update the presence of a tracked object in zones.
        Returns a list of zone names where loitering was detected in this tick.
        """
        current_time = time.time()
        new_alerts = []
        
        if track_id not in self.entry_times:
            self.entry_times[track_id] = {}
        if track_id not in self.alerted:
            self.alerted[track_id] = []
            
        # Register new zone entries
        for zone in intruded_zones:
            if zone not in self.entry_times[track_id]:
                self.entry_times[track_id][zone] = current_time
                
            # Check for loitering
            time_in_zone = current_time - self.entry_times[track_id][zone]
            if time_in_zone >= self.threshold_seconds and zone not in self.alerted[track_id]:
                new_alerts.append(zone)
                self.alerted[track_id].append(zone)
                
        # Remove zones the object has exited
        exited_zones = [z for z in self.entry_times[track_id].keys() if z not in intruded_zones]
        for z in exited_zones:
            del self.entry_times[track_id][z]
            if z in self.alerted[track_id]:
                self.alerted[track_id].remove(z)
                
        return new_alerts

    def remove_track(self, track_id: int):
        if track_id in self.entry_times:
            del self.entry_times[track_id]
        if track_id in self.alerted:
            del self.alerted[track_id]
