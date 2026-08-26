import numpy as np

class OCRProcessor:
    def __init__(self, confidence_threshold=0.5):
        self.confidence_threshold = confidence_threshold

    def process_results(self, raw_results, image_width, image_height):
        """
        Processes EasyOCR output.
        Filters by confidence and normalizes bounding boxes.
        """
        processed = []
        for bbox, text, prob in raw_results:
            if prob < self.confidence_threshold:
                continue

            # EasyOCR returns a list of 4 points: [[x1, y1], [x2, y1], [x2, y2], [x1, y2]]
            # We extract top-left and bottom-right
            xs = [p[0] for p in bbox]
            ys = [p[1] for p in bbox]
            
            x1 = min(xs)
            y1 = min(ys)
            x2 = max(xs)
            y2 = max(ys)

            # Normalize coordinates
            norm_x1 = max(0.0, float(x1) / image_width)
            norm_y1 = max(0.0, float(y1) / image_height)
            norm_x2 = min(1.0, float(x2) / image_width)
            norm_y2 = min(1.0, float(y2) / image_height)

            processed.append({
                "text": text,
                "confidence": float(prob),
                "bbox": {
                    "x1": norm_x1,
                    "y1": norm_y1,
                    "x2": norm_x2,
                    "y2": norm_y2
                }
            })
            
        return processed
