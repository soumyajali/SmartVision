import cv2
from ultralytics import YOLO

def main():
    print("Loading YOLOv8 PyTorch model...")
    # Load the standard PyTorch YOLOv8 model (downloads automatically)
    model = YOLO('yolov8n.pt', task='detect')
    
    print("Opening system camera...")
    cap = cv2.VideoCapture(0)
    
    if not cap.isOpened():
        print("Error: Could not open camera.")
        return

    print("Camera opened. Press 'q' in the window to quit.")
    while True:
        ret, frame = cap.read()
        if not ret:
            print("Failed to grab frame")
            break
            
        # Run inference and track objects
        results = model.track(frame, persist=True, verbose=False)
        
        # Visualize the results on the frame
        annotated_frame = results[0].plot()
        
        # Display the annotated frame
        cv2.imshow("YOLOv8 Real-Time Detection", annotated_frame)
        
        # Break the loop if 'q' is pressed
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()
