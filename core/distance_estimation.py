"""
SmartVision Calibrated Pinhole Camera Distance Estimation Engine

Mathematical Formulation:
--------------------------
For a pinhole camera model:
    w_px = (W_real * f_px) / D
    h_px = (H_real * f_py) / D

Normalized coordinate formulation (resolution-independent):
    f_norm_x = 1.0 / (2.0 * tan(HFOV / 2.0))
    f_norm_y = 1.0 / (2.0 * tan(VFOV / 2.0))

    D_w = (W_real * f_norm_x) / w_norm
    D_h = (H_real * f_norm_y) / h_norm

Where:
    W_real, H_real: Known physical real-world dimensions (meters)
    w_norm, h_norm: Apparent bounding box width & height in [0.0, 1.0]
    HFOV, VFOV: Calibrated horizontal and vertical field-of-view of the camera
    D: Estimated distance in meters from camera optical center to target object.
"""

import math
from typing import Dict, Any, Optional, Tuple, Union

# Verified physical dimensions (meters) for canonical objects
KNOWN_PHYSICAL_DIMENSIONS = {
    # Class: (Width in meters, Height in meters, Primary dimension to trust: 'height'|'width'|'balanced')
    'person': (0.45, 1.70, 'height'),        # Average adult standing height 1.70m, shoulder width 0.45m
    'cell phone': (0.075, 0.150, 'height'),   # Typical modern smartphone 150mm x 75mm
    'bottle': (0.075, 0.240, 'height'),       # Standard 500ml/750ml water bottle
    'cup': (0.085, 0.100, 'height'),          # Standard ceramic / coffee mug
    'laptop': (0.320, 0.220, 'width'),        # Standard 14-15" laptop width
    'chair': (0.500, 0.850, 'height'),        # Standard office/dining chair
    'dining table': (1.200, 0.750, 'width'),  # Table surface width
    'knife': (0.035, 0.250, 'height'),        # Kitchen knife length ~25cm
    'scissors': (0.080, 0.200, 'height'),     # Standard desk/kitchen scissors
    'microwave': (0.500, 0.320, 'width'),     # Countertop microwave
    'car': (1.800, 1.500, 'width'),           # Standard passenger sedan
    'motorcycle': (0.800, 1.150, 'height'),   # Standard motorbike
    'bicycle': (0.600, 1.050, 'height'),      # Standard adult bicycle
    'tv': (0.950, 0.550, 'width'),            # 43-inch display screen
    'keyboard': (0.440, 0.140, 'width'),      # Full-size desktop keyboard
    'mouse': (0.065, 0.115, 'height'),        # Standard computer mouse
    'traffic light': (0.350, 0.950, 'height'),# Standard traffic signal head
    'stop sign': (0.750, 0.750, 'balanced'),  # Standard octagonal stop sign 75cm x 75cm
    'potted plant': (0.250, 0.400, 'height'), # Medium tabletop potted plant
    'book': (0.150, 0.230, 'height'),         # Standard hardcover/paperback book
}

class DistanceEstimator:
    """
    Calibrated Pinhole Distance Estimator for 2D Monocular Camera Streams.
    Computes absolute metric distance from apparent bounding box and camera calibration.
    """
    
    def __init__(
        self,
        hfov_deg: float = 65.0,
        vfov_deg: float = 48.0,
        calibration_scale: float = 1.0,
        min_operating_range_m: float = 0.25,
        max_operating_range_m: float = 12.0
    ):
        """
        Args:
            hfov_deg: Horizontal Field of View in degrees (standard mobile/webcam ~60-70 deg).
            vfov_deg: Vertical Field of View in degrees (standard mobile/webcam ~45-55 deg).
            calibration_scale: Device-specific fine-tuning multiplier (calibrated against ground truth).
            min_operating_range_m: Minimum reliable distance threshold (meters).
            max_operating_range_m: Maximum reliable distance threshold (meters).
        """
        self.hfov_deg = hfov_deg
        self.vfov_deg = vfov_deg
        self.calibration_scale = calibration_scale
        self.min_range = min_operating_range_m
        self.max_range = max_operating_range_m
        
        # Precompute normalized focal lengths
        self.f_norm_x = (1.0 / (2.0 * math.tan(math.radians(hfov_deg / 2.0)))) * calibration_scale
        self.f_norm_y = (1.0 / (2.0 * math.tan(math.radians(vfov_deg / 2.0)))) * calibration_scale

    def is_border_clipped(self, left: float, top: float, right: float, bottom: float, margin: float = 0.015) -> bool:
        """
        Determines whether the bounding box touches or is cut off by the camera sensor boundary.
        If clipped, apparent width or height is artificially small, which would falsely inflate distance.
        """
        return (
            left <= margin or
            top <= margin or
            right >= (1.0 - margin) or
            bottom >= (1.0 - margin)
        )

    def estimate_distance(
        self,
        label: str,
        rect: Union[Dict[str, float], Tuple[float, float, float, float]],
        custom_real_width_m: Optional[float] = None,
        custom_real_height_m: Optional[float] = None
    ) -> Dict[str, Any]:
        """
        Estimates metric distance for a detected object bounding box.

        Args:
            label: Detected object class name (e.g., 'person', 'bottle', 'laptop')
            rect: Bounding box in normalized coords [0.0, 1.0]:
                  Dict {'left': float, 'top': float, 'right': float, 'bottom': float}
                  or tuple (left, top, right, bottom)
            custom_real_width_m: Optional known real width override
            custom_real_height_m: Optional known real height override

        Returns:
            Dict containing:
                - 'distance_m': float or None
                - 'is_calibrated': bool
                - 'status': str ('valid', 'partially_occluded', 'unsupported_class', 'out_of_range')
                - 'confidence_range': Tuple[float, float] or None (min, max range based on 15% physical variance)
                - 'explanation': str
        """
        # Parse box
        if isinstance(rect, dict):
            l, t, r, b = rect['left'], rect['top'], rect['right'], rect['bottom']
        else:
            l, t, r, b = rect[0], rect[1], rect[2], rect[3]

        w_norm = max(1e-5, r - l)
        h_norm = max(1e-5, b - t)
        
        # Check border clipping
        clipped = self.is_border_clipped(l, t, r, b)

        # Lookup physical dimensions
        clean_label = label.lower().strip()
        dims = KNOWN_PHYSICAL_DIMENSIONS.get(clean_label)
        
        if custom_real_width_m and custom_real_height_m:
            real_w, real_h, priority = custom_real_width_m, custom_real_height_m, 'balanced'
        elif dims:
            real_w, real_h, priority = dims
        else:
            return {
                'distance_m': None,
                'is_calibrated': False,
                'status': 'unsupported_class',
                'confidence_range': None,
                'explanation': f"Class '{label}' has no calibrated physical dimensions. Physical distance unavailable from single monocular frame."
            }

        # Calculate distances based on width and height
        d_from_w = (real_w * self.f_norm_x) / w_norm
        d_from_h = (real_h * self.f_norm_y) / h_norm

        # Select primary dimension based on object geometry stability
        if priority == 'height':
            est_dist = d_from_h
        elif priority == 'width':
            est_dist = d_from_w
        else:
            # Balanced: harmonic mean to suppress outliers
            est_dist = 2.0 * (d_from_w * d_from_h) / (d_from_w + d_from_h)

        est_dist = round(float(est_dist), 2)

        if clipped:
            return {
                'distance_m': est_dist,
                'is_calibrated': True,
                'status': 'partially_occluded',
                'confidence_range': (round(est_dist * 0.7, 2), round(est_dist * 1.3, 2)),
                'explanation': f"Object '{label}' touches frame border (partially truncated). Distance is an approximate upper bound."
            }

        if est_dist < self.min_range or est_dist > self.max_range:
            return {
                'distance_m': est_dist,
                'is_calibrated': True,
                'status': 'out_of_range',
                'confidence_range': None,
                'explanation': f"Estimated distance {est_dist}m exceeds reliable operating window ({self.min_range}m - {self.max_range}m)."
            }

        # 15% biological/manufacturing variance bounds
        d_min = round(est_dist * 0.88, 2)
        d_max = round(est_dist * 1.12, 2)

        return {
            'distance_m': est_dist,
            'is_calibrated': True,
            'status': 'valid',
            'confidence_range': (d_min, d_max),
            'explanation': f"Distance estimated via calibrated pinhole model ({priority}-based projection)."
        }

# Global singleton with standard calibration
default_distance_estimator = DistanceEstimator(hfov_deg=65.0, vfov_deg=48.0, calibration_scale=1.0)
