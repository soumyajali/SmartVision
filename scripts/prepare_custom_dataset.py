"""
SmartVision Dataset Builder & Validator
Constructs a unified, validated dataset under datasets/custom_objects/
with train (70%), val (20%), and untouched test (10%) splits.
Maps custom annotations to standard COCO 80 classes to ensure zero class fragmentation.
"""

import os
import shutil
import glob
import random
from PIL import Image

random.seed(42)

COCO_80_NAMES = [
    'person', 'bicycle', 'car', 'motorcycle', 'airplane', 'bus', 'train', 'truck', 'boat', 'traffic light',
    'fire hydrant', 'stop sign', 'parking meter', 'bench', 'bird', 'cat', 'dog', 'horse', 'sheep', 'cow',
    'elephant', 'bear', 'zebra', 'giraffe', 'backpack', 'umbrella', 'handbag', 'tie', 'suitcase', 'frisbee',
    'skis', 'snowboard', 'sports ball', 'kite', 'baseball bat', 'baseball glove', 'skateboard', 'surfboard',
    'tennis racket', 'bottle', 'wine glass', 'cup', 'fork', 'knife', 'spoon', 'bowl', 'banana', 'apple',
    'sandwich', 'orange', 'broccoli', 'carrot', 'hot dog', 'pizza', 'donut', 'cake', 'chair', 'couch',
    'potted plant', 'bed', 'dining table', 'toilet', 'tv', 'laptop', 'mouse', 'remote', 'keyboard', 'cell phone',
    'microwave', 'oven', 'toaster', 'sink', 'refrigerator', 'book', 'clock', 'vase', 'scissors', 'teddy bear',
    'hair drier', 'toothbrush'
]

# Map 25 classes from smart vision detection to official COCO 80 IDs
MAP_25_TO_COCO = {
    0: 56,   # Chair -> chair
    1: 39,   # bottle -> bottle
    2: 15,   # Cat -> cat
    3: 41,   # Cup -> cup
    4: 13,   # Bench -> bench
    5: 17,   # Horse -> horse
    6: 0,    # Person -> person
    7: 59,   # bed -> bed
    8: 7,    # Truck -> truck
    9: 4,    # Airplane -> airplane
    10: 1,   # Cycle -> bicycle
    11: 14,  # Bird -> bird
    12: 3,   # bike -> motorcycle
    13: 5,   # bus -> bus
    14: 58,  # potted plant -> potted plant
    15: 53,  # Pizza -> pizza
    16: 11,  # Stop Signal -> stop sign
    17: 45,  # Bowl -> bowl
    18: 9,   # Traffic Signal -> traffic light
    19: 57,  # couch -> couch
    20: 20,  # elephant -> elephant
    21: 55,  # Cake -> cake
    22: 16,  # dog -> dog
    23: 19,  # cow -> cow
    24: 2,   # Car -> car
}

BASE_DIR = os.path.abspath(os.path.dirname(__file__) + '/..')
OUTPUT_DIR = os.path.join(BASE_DIR, 'datasets', 'custom_objects')

for split in ['train', 'val', 'test']:
    os.makedirs(os.path.join(OUTPUT_DIR, 'images', split), exist_ok=True)
    os.makedirs(os.path.join(OUTPUT_DIR, 'labels', split), exist_ok=True)

# Collect all valid image/label pairs from smart vision detection
source_pairs = []
raw_train_imgs = glob.glob(os.path.join(BASE_DIR, 'smart vision detection', 'train', 'images', '*'))
raw_val_imgs = glob.glob(os.path.join(BASE_DIR, 'smart vision detection', 'valid', 'images', '*'))

for img_path in raw_train_imgs + raw_val_imgs:
    base = os.path.splitext(os.path.basename(img_path))[0]
    # Check corresponding label
    lbl_dir = os.path.join(os.path.dirname(os.path.dirname(img_path)), 'labels')
    lbl_path = os.path.join(lbl_dir, base + '.txt')
    if os.path.exists(lbl_path):
        source_pairs.append((img_path, lbl_path))

print(f"Found {len(source_pairs)} image-label pairs from smart vision detection source.")

# Shuffle deterministically
random.shuffle(source_pairs)

# Add project benchmark images
# Project specific annotations using COCO classes:
extra_samples = [
    {
        'img': os.path.join(BASE_DIR, 'test_danger_image.png'),
        'boxes': [
            (76, 0.45, 0.50, 0.35, 0.40), # scissors
            (41, 0.85, 0.65, 0.20, 0.35)  # cup
        ],
        'split': 'test'
    },
    {
        'img': os.path.join(BASE_DIR, 'test_image.png'),
        'boxes': [
            (15, 0.25, 0.60, 0.35, 0.45), # cat
            (41, 0.70, 0.70, 0.15, 0.25), # cup
            (0,  0.50, 0.40, 0.30, 0.60), # person
            (56, 0.80, 0.50, 0.25, 0.50)  # chair
        ],
        'split': 'test'
    },
    {
        'img': os.path.join(BASE_DIR, 'frame_sample.jpg'),
        'boxes': [
            (2, 0.48, 0.72, 0.30, 0.28), # car
            (2, 0.15, 0.68, 0.22, 0.20), # car
            (0, 0.88, 0.65, 0.10, 0.25)  # person
        ],
        'split': 'test'
    },
    {
        'img': os.path.join(BASE_DIR, 'p0.jpg'),
        'boxes': [
            (0, 0.30, 0.45, 0.25, 0.65), # person
            (0, 0.65, 0.50, 0.28, 0.70)  # person
        ],
        'split': 'val'
    }
]

# Split 70% train, 20% val, 10% test
n_total = len(source_pairs)
n_train = int(n_total * 0.70)
n_val = int(n_total * 0.20)
splits = {
    'train': source_pairs[:n_train],
    'val': source_pairs[n_train:n_train + n_val],
    'test': source_pairs[n_train + n_val:]
}

def validate_box(cid, xc, yc, w, h):
    if not (0 <= cid < 80):
        return False
    if not (0.0 <= xc <= 1.0 and 0.0 <= yc <= 1.0):
        return False
    if not (0.0 < w <= 1.0 and 0.0 < h <= 1.0):
        return False
    return True

validated_counts = {'train': 0, 'val': 0, 'test': 0}
instance_counts = {'train': 0, 'val': 0, 'test': 0}
corrupted_images = 0

for split, pairs in splits.items():
    for img_p, lbl_p in pairs:
        # Check image validity
        try:
            with Image.open(img_p) as im:
                im.verify()
        except Exception:
            corrupted_images += 1
            continue

        # Convert label lines to COCO IDs
        valid_lines = []
        with open(lbl_p, 'r') as f:
            for line in f:
                parts = line.strip().split()
                if len(parts) == 5:
                    old_cid = int(parts[0])
                    coco_cid = MAP_25_TO_COCO.get(old_cid, None)
                    if coco_cid is not None:
                        xc, yc, w, h = map(float, parts[1:])
                        # Clip coordinates to [0, 1] to prevent rounding overflow
                        xc = max(0.0, min(1.0, xc))
                        yc = max(0.0, min(1.0, yc))
                        w = max(0.001, min(1.0, w))
                        h = max(0.001, min(1.0, h))
                        if validate_box(coco_cid, xc, yc, w, h):
                            valid_lines.append(f"{coco_cid} {xc:.6f} {yc:.6f} {w:.6f} {h:.6f}")

        if valid_lines:
            base_name = os.path.basename(img_p)
            dst_img = os.path.join(OUTPUT_DIR, 'images', split, base_name)
            dst_lbl = os.path.join(OUTPUT_DIR, 'labels', split, os.path.splitext(base_name)[0] + '.txt')

            shutil.copy2(img_p, dst_img)
            with open(dst_lbl, 'w') as f:
                f.write('\n'.join(valid_lines) + '\n')

            validated_counts[split] += 1
            instance_counts[split] += len(valid_lines)

# Process extra benchmark samples
for item in extra_samples:
    img_p = item['img']
    if os.path.exists(img_p):
        split = item['split']
        base_name = os.path.basename(img_p)
        dst_img = os.path.join(OUTPUT_DIR, 'images', split, base_name)
        dst_lbl = os.path.join(OUTPUT_DIR, 'labels', split, os.path.splitext(base_name)[0] + '.txt')
        shutil.copy2(img_p, dst_img)
        lines = [f"{cid} {xc:.6f} {yc:.6f} {w:.6f} {h:.6f}" for cid, xc, yc, w, h in item['boxes']]
        with open(dst_lbl, 'w') as f:
            f.write('\n'.join(lines) + '\n')
        validated_counts[split] += 1
        instance_counts[split] += len(lines)

# Write data.yaml
data_yaml_content = f"""# SmartVision Custom Objects Dataset
path: {OUTPUT_DIR}
train: images/train
val: images/val
test: images/test

nc: 80
names: {COCO_80_NAMES}
"""

with open(os.path.join(OUTPUT_DIR, 'data.yaml'), 'w') as f:
    f.write(data_yaml_content)

print("\n" + "="*50)
print("DATASET CREATION REPORT")
print("="*50)
print(f"Output Path: {OUTPUT_DIR}")
print(f"Corrupted images excluded: {corrupted_images}")
for split in ['train', 'val', 'test']:
    print(f"  {split.upper():5s} -> Images: {validated_counts[split]:3d} | Instances: {instance_counts[split]:4d}")
print("data.yaml successfully generated with 80 standard classes.")
