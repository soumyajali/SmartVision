import easyocr

class OCRReader:
    def __init__(self, languages=['en'], use_gpu=False):
        self.reader = None
        try:
            self.reader = easyocr.Reader(languages, gpu=use_gpu, download_enabled=False)
        except Exception as e:
            print(f"Warning: OCR model unavailable in offline mode: {e}")
            self.reader = None

    def read_text(self, image, rotation_info=[90, 180, 270]):
        """
        Reads text from an image with multi-angle rotation awareness (0°, 90°, 180°, 270°).
        Returns a list of tuples: (bbox, text, prob)
        bbox is [[x1, y1], [x2, y1], [x2, y2], [x1, y2]]
        """
        if self.reader is None:
            return []
        try:
            return self.reader.readtext(image, rotation_info=rotation_info)
        except Exception as e:
            print(f"EasyOCR Error: {e}")
            return []
