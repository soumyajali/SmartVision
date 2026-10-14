# SmartVision Dataset Acquisition & Inventory Report

**Free Disk Space Available**: 17.47 GB

## 1. Source Repositories & Download Status

| Repository ID | Source Type | License | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| `smartvision_local` | local | MIT | **AVAILABLE** | 527 internal SmartVision video frames & danger test samples |
| `huggingface_quickstart_coco` | huggingface | CC-BY-4.0 | **DOWNLOADED** | Dataset already cached at /Users/sowmya/Desktop/SmartVision-main/datasets/raw_downloads/huggingface_quickstart_coco. |
| `coco_official_coco128` | http | CC-BY-4.0 | **SKIPPED/UNAVAILABLE** | HTTP download failed: <urlopen error [Errno 54] Connection reset by peer> |
| `kaggle_cv_competition` | kaggle | Kaggle Competition Data License | **SKIPPED/UNAVAILABLE** | Kaggle authentication credentials not found in ~/.kaggle/kaggle.json. To enable: 1. Go to https://www.kaggle.com/settings -> Click 'Create New Token'. 2. Place 'kaggle.json' into ~/.kaggle/kaggle.json. 3. Run 'chmod 600 ~/.kaggle/kaggle.json'. |
| `open_images_v7` | gsutil_http | CC-BY-2.0 | **SKIPPED/UNAVAILABLE** | Skipped download due to storage limits: Required 50 GB, but only 17.5 GB available. Use targeted category subset downloads or external cloud storage. |
| `objects365` | objects365_portal | CC-BY-4.0 (Non-commercial / Academic) | **SKIPPED/UNAVAILABLE** | Skipped download due to storage limits: Required 350 GB, but only 17.5 GB available. Use targeted category subset downloads or external cloud storage. |

## 2. Combined Dataset Split Statistics

| Split | Images | Valid Images | Labels | Instances | Integrity Rate |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `train` | 527 | 527 | 527 | 1608 | 100.0% |
| `val` | 146 | 146 | 146 | 411 | 100.0% |
| `test` | 57 | 57 | 57 | 86 | 100.0% |

## 3. Data Integrity & Validation Checks

- **Total Images Checked**: 730
- **Corrupted Images**: 0
- **Total Labels Checked**: 730
- **Empty Labels**: 0
- **Missing Labels**: 0
- **Invalid Bounding Boxes**: 0
- **Duplicate Images Detected**: 1
- **Total Valid Ground Truth Instances**: 2105

## 4. Class Distribution (Top 25 Categories)

| Class ID | Class Name | Instance Count | Status |
| :--- | :--- | :--- | :--- |
| 0 | `person` | 524 | Active & Populated |
| 9 | `traffic light` | 116 | Active & Populated |
| 2 | `car` | 99 | Active & Populated |
| 33 | `kite` | 75 | Active & Populated |
| 14 | `bird` | 68 | Active & Populated |
| 7 | `truck` | 67 | Active & Populated |
| 41 | `cup` | 63 | Active & Populated |
| 17 | `horse` | 58 | Active & Populated |
| 39 | `bottle` | 58 | Active & Populated |
| 56 | `chair` | 54 | Active & Populated |
| 20 | `elephant` | 53 | Active & Populated |
| 19 | `cow` | 49 | Active & Populated |
| 16 | `dog` | 47 | Active & Populated |
| 51 | `carrot` | 47 | Active & Populated |
| 4 | `airplane` | 43 | Active & Populated |
| 3 | `motorcycle` | 41 | Active & Populated |
| 55 | `cake` | 38 | Active & Populated |
| 8 | `boat` | 37 | Active & Populated |
| 13 | `bench` | 36 | Active & Populated |
| 53 | `pizza` | 35 | Active & Populated |
| 11 | `stop sign` | 34 | Active & Populated |
| 58 | `potted plant` | 34 | Active & Populated |
| 45 | `bowl` | 32 | Active & Populated |
| 37 | `surfboard` | 30 | Active & Populated |
| 15 | `cat` | 29 | Active & Populated |

*Populated Active Ground Truth Categories in Dataset*: **73 / 80 COCO Classes** (all 80 preserved in YOLO head)*

