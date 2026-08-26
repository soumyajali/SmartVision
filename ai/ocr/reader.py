import easyocr

class OCRReader:
    def __init__(self, languages=['en'], use_gpu=False):
        # Initialize EasyOCR reader
        self.reader = easyocr.Reader(languages, gpu=use_gpu)

    def read_text(self, image):
        """
        Reads text from an image.
        Returns a list of tuples: (bbox, text, prob)
        bbox is [[x1, y1], [x2, y1], [x2, y2], [x1, y2]]
        """
        try:
            return self.reader.readtext(image)
        except Exception as e:
            print(f"EasyOCR Error: {e}")
            return []
