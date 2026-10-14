# SmartVision Automated Dataset Collection & YOLOv8 Model Training Guide

This guide documents the end-to-end automated pipeline implemented for the **SmartVision AI** ecosystem. It automates dataset discovery, authenticated batch downloads, multi-format annotation conversion, data validation, leak-free splitting, YOLOv8 training, test evaluation, baseline comparison, and model export.

---

## 📌 Architecture Overview

```
                                  ┌─────────────────────────────┐
                                  │   Desktop / Local Datasets  │
                                  │ (/Users/sowmya/Desktop/...) │
                                  └──────────────┬──────────────┘
                                                 │
┌───────────────────────────┐                    ▼                    ┌───────────────────────────┐
│ Kaggle Datasets Discovery │ ──────▶ Annotation Converters ◀────── │  Hugging Face Hub Search  │
│  (Paginated Search & API) │         (VOC XML / COCO / YOLO)         │ (Open Source Repositories)│
└───────────────────────────┘                    │                    └───────────────────────────┘
                                                 ▼
                                ┌─────────────────────────────────┐
                                │   Validation & Deduplication    │
                                │ (MD5/dHash, Bounds, Leak-Free)  │
                                └────────────────┬────────────────┘
                                                 │
                                                 ▼
                                ┌─────────────────────────────────┐
                                │  Standardized YOLOv8 Dataset    │
                                │ (70% Train, 20% Val, 10% Test)  │
                                └────────────────┬────────────────┘
                                                 │
                                                 ▼
                                ┌─────────────────────────────────┐
                                │    YOLOv8 Fine-Tuning Engine    │
                                │  (MPS / CUDA / CPU Auto-Detect) │
                                └────────────────┬────────────────┘
                                                 │
                                                 ▼
                                ┌─────────────────────────────────┐
                                │   Benchmark & Baseline Delta    │
                                │   (Untouched Held-Out Test Set) │
                                └────────────────┬────────────────┘
                                                 │
                                                 ▼
                                ┌─────────────────────────────────┐
                                │ Production Weights & Exports    │
                                │ (smartvision_best.pt / ONNX)    │
                                └─────────────────────────────────┘
```

---

## 🛠️ Components & File Structure

| Component | Path | Description |
| :--- | :--- | :--- |
| **Unified CLI Orchestrator** | `scripts/dataset_pipeline.py` | Command-line interface for `--discover`, `--download`, `--prepare`, `--train`, `--evaluate`, `--export`, `--sample-test`, `--rollback`. |
| **Annotation Converters** | `scripts/annotation_converters.py` | Multi-format parser for Pascal VOC XML, COCO JSON, and YOLO `.txt`, with synonym taxonomy mapping and deduplication. |
| **Discovery & Downloader** | `scripts/kaggle_hf_discovery.py` | Paginated search for Kaggle and Hugging Face with storage headroom limits, retries, and duplicate detection. |
| **Model Trainer Suite** | `scripts/model_trainer.py` | YOLOv8 training, test-split benchmarking, empirical comparison against baseline (`SmartVision_v3.pt`), and ONNX/TFLite export. |
| **Pipeline Configuration** | `config/pipeline_config.yaml` | Central configuration defining search queries, storage thresholds, canonical taxonomy, and hyperparameters. |
| **Colab GPU Notebook** | `SmartVision_Colab_Training.ipynb` | Ready-to-run Jupyter notebook for high-speed GPU fine-tuning (NVIDIA T4 / A100). |
| **Web Dashboard Tab** | `app.py` (`AutoML & Dataset Pipeline`) | Interactive UI in Streamlit for monitoring datasets, running downloads, local training, and one-click rollback. |

---

## 🔑 Kaggle Authentication Setup

To enable authenticated Kaggle downloads without exposing credentials in code or Git:

### Option A: Environment Variables (Recommended)
Add to your `~/.zshrc` or set in your terminal:
```bash
export KAGGLE_API_TOKEN="your_token_here"
# or
export KAGGLE_USERNAME="your_username"
export KAGGLE_KEY="your_api_key"
```

### Option B: Token File
1. Go to [https://www.kaggle.com/settings](https://www.kaggle.com/settings).
2. Under **API**, click **Create New Token** (downloads `kaggle.json`).
3. Place in your home directory:
   ```bash
   mkdir -p ~/.kaggle
   mv ~/Downloads/kaggle.json ~/.kaggle/
   chmod 600 ~/.kaggle/kaggle.json
   ```

*Note: Public benchmark datasets (COCO-128, Hugging Face Hub, and local Desktop datasets) run out-of-the-box without requiring Kaggle credentials.*

---

## 💻 Command-Line Interface (CLI) Usage

Both `python3` and `python` are supported:

### 1. View Available Options
```bash
python3 scripts/dataset_pipeline.py --help
```

### 2. Integration & Dry-Run Tests
Simulate actions without modifying files or downloading large archives:
```bash
python3 scripts/dataset_pipeline.py --sample-test
python3 scripts/dataset_pipeline.py --dry-run --prepare
```

### 3. Discover Datasets
Search Kaggle and Hugging Face and catalog results into `datasets/manifest.json`:
```bash
python3 scripts/dataset_pipeline.py --discover
```

### 4. Batch Download Datasets
Download top cataloged datasets respecting size and storage headroom limits:
```bash
python3 scripts/dataset_pipeline.py --download
```

### 5. Validate, Convert Annotations, & Create Splits
Converts VOC XML, COCO JSON, and YOLO annotations from `datasets/raw_downloads/`, `smart vision detection/`, and `/Users/sowmya/Desktop/datasets/` into `datasets/custom_objects/`:
```bash
python3 scripts/dataset_pipeline.py --prepare
```

### 6. Fine-Tune YOLOv8
Train the model on the prepared multi-class dataset (supports `--epochs` override):
```bash
python3 scripts/dataset_pipeline.py --train --epochs 5
```

### 7. Evaluate on Untouched Test Split & Compare with Baseline
```bash
python3 scripts/dataset_pipeline.py --evaluate
```

### 8. Export Production Model (ONNX & TFLite)
```bash
python3 scripts/dataset_pipeline.py --export
```

### 9. Rollback to Previous Working Model
Restores the `.bak` backup model if a newly trained model regresses:
```bash
python3 scripts/dataset_pipeline.py --rollback
```

### 10. Run Entire Pipeline End-to-End
```bash
python3 scripts/dataset_pipeline.py --all
```

---

## ☁️ Training with Google Colab GPU

For long training runs (20–50 epochs) on heavy multi-class datasets without straining laptop battery:
1. Open [Google Colab](https://colab.research.google.com).
2. Upload `SmartVision_Colab_Training.ipynb` (or download directly from the Streamlit **AutoML Hub** tab).
3. Under **Runtime** > **Change runtime type**, select **T4 GPU**.
4. Run all cells. The notebook will automatically fine-tune YOLOv8 and trigger a browser download for the resulting `smartvision_best.pt` and `smartvision_best.onnx` models.

---

## 🎯 Bug Fixes Applied to Core Inference

1. **Face Service False Attribution Bug**:
   - *Problem*: `services/face_service.py` had a fallback to full-frame face detection when a detected bounding box had no face. This caused backpacks, luggage, and non-face boxes to be stamped with the user's face name ("mee").
   - *Fix*: Removed full-frame fallback in `FaceService.recognize()`. Face labels are now only applied when a face is physically located inside the detected bounding box.

2. **Class-Agnostic NMS Suppression**:
   - *Problem*: `app.py` passed `agnostic_nms=True`, causing overlapping bounding boxes of different classes (e.g. a person holding or wearing a backpack) to suppress each other.
   - *Fix*: Updated to `agnostic_nms=False`. Both the person and the backpack/objects they carry are now simultaneously localized.

3. **Open-Vocabulary (YOLO-World) Categories**:
   - *Problem*: `yolov8s-world.pt` did not include `backpack`, `bag`, `handbag`, `laptop`, or classroom objects in its class list.
   - *Fix*: Expanded `load_world_model()` default classes and added an interactive text input in the UI so users can query any real-world objects in natural language.
