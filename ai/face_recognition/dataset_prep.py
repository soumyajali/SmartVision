import os
import argparse
from pathlib import Path
from PIL import Image
import torchvision.transforms as transforms

def prepare_dataset(source_dir, output_dir, img_size=(112, 112)):
    """
    Simulates preparing a Face Recognition dataset (like CASIA-WebFace or VGGFace2).
    In a real scenario, this would use MTCNN/RetinaFace to detect, crop, and align faces
    based on 5 landmarks before saving them as 112x112 RGB images.
    """
    print(f"Preparing dataset from {source_dir} to {output_dir}...")
    source = Path(source_dir)
    dest = Path(output_dir)
    dest.mkdir(parents=True, exist_ok=True)

    transform = transforms.Compose([
        transforms.Resize(img_size),
        transforms.CenterCrop(img_size)
    ])

    count = 0
    if not source.exists():
        print(f"Source directory {source_dir} not found. Please download a dataset first.")
        return

    for person_dir in source.iterdir():
        if not person_dir.is_dir():
            continue
        
        person_dest = dest / person_dir.name
        person_dest.mkdir(exist_ok=True)
        
        for img_file in person_dir.glob("*.jpg"):
            try:
                img = Image.open(img_file).convert('RGB')
                # Simulated alignment: just resize and crop
                aligned_img = transform(img)
                aligned_img.save(person_dest / img_file.name)
                count += 1
            except Exception as e:
                print(f"Error processing {img_file}: {e}")

    print(f"Dataset preparation complete. Processed {count} images.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Prepare Face Recognition Dataset")
    parser.add_argument("--source", type=str, default="./raw_dataset", help="Path to raw dataset")
    parser.add_argument("--output", type=str, default="./aligned_dataset", help="Path to aligned output")
    args = parser.parse_args()
    
    prepare_dataset(args.source, args.output)
