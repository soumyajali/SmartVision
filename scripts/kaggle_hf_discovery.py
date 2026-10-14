"""
SmartVision Dataset Discovery & Automated Downloader Suite
Discovers and downloads object detection datasets from Kaggle and Hugging Face.
Supports:
- Paginated Kaggle search with official Kaggle API
- Hugging Face datasets discovery
- Storage limit & dataset size constraints
- Retry logic with exponential backoff
- Progress reporting and manifest persistence
- Public fallback downloads when credentials are not configured
"""

import os
import sys
import time
import json
import shutil
import zipfile
import urllib.request
from typing import Dict, Any, List, Tuple, Optional

def get_free_disk_space_gb(path: str = ".") -> float:
    """Returns free disk space in Gigabytes for the specified path."""
    try:
        stat = os.statvfs(path)
        return (stat.f_bavail * stat.f_frsize) / (1024 ** 3)
    except Exception:
        return 10.0

class DatasetDiscoverySuite:
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.discovery_cfg = config.get("discovery", {})
        self.limits_cfg = config.get("download_limits", {})
        self.raw_dir = config.get("dataset_preparation", {}).get("raw_dir", "datasets/raw_downloads")
        self.manifest_path = config.get("dataset_preparation", {}).get("manifest_path", "datasets/manifest.json")
        os.makedirs(self.raw_dir, exist_ok=True)
        os.makedirs(os.path.dirname(self.manifest_path), exist_ok=True)

    def check_kaggle_auth(self) -> Tuple[bool, str]:
        """Checks if Kaggle authentication credentials are present without printing tokens."""
        # 1. Environment variable token
        if os.environ.get("KAGGLE_API_TOKEN"):
            return True, "Authenticated via KAGGLE_API_TOKEN environment variable."
        # 2. Environment variable key pair
        if os.environ.get("KAGGLE_USERNAME") and os.environ.get("KAGGLE_KEY"):
            return True, "Authenticated via KAGGLE_USERNAME / KAGGLE_KEY environment variables."
        # 3. New access token file
        access_token_file = os.path.expanduser("~/.kaggle/access_token")
        if os.path.exists(access_token_file) and os.path.getsize(access_token_file) > 0:
            return True, f"Authenticated via access token at {access_token_file}."
        # 4. Standard kaggle.json
        kaggle_json = os.path.expanduser("~/.kaggle/kaggle.json")
        if os.path.exists(kaggle_json) and os.path.getsize(kaggle_json) > 0:
            return True, f"Authenticated via credentials at {kaggle_json}."

        instructions = (
            "Kaggle API authentication is not configured.\n"
            "To enable automated Kaggle downloads:\n"
            "  Option A: Set environment variable:\n"
            "    export KAGGLE_API_TOKEN=\"your_kaggle_token\"\n"
            "    or\n"
            "    export KAGGLE_USERNAME=\"your_user\" KAGGLE_KEY=\"your_key\"\n"
            "  Option B: Download kaggle.json from https://www.kaggle.com/settings -> 'Create New Token'\n"
            "    Place it at ~/.kaggle/kaggle.json and run: chmod 600 ~/.kaggle/kaggle.json\n"
            "Public Hugging Face and benchmark datasets will be used in the meantime."
        )
        return False, instructions

    def discover_kaggle(self, query: str = "object detection", max_pages: int = 5) -> List[Dict[str, Any]]:
        """Queries Kaggle for object detection datasets with pagination."""
        is_auth, _ = self.check_kaggle_auth()
        if not is_auth:
            return []

        discovered = []
        try:
            import kaggle
            for page in range(1, max_pages + 1):
                datasets = kaggle.api.dataset_list(search=query, page=page, sort_by="votes")
                if not datasets:
                    break
                for ds in datasets:
                    ref = getattr(ds, "ref", None) or f"{getattr(ds, 'ownerRef', '')}/{getattr(ds, 'datasetSlug', '')}"
                    title = getattr(ds, "title", ref)
                    size_bytes = getattr(ds, "totalBytes", 0)
                    size_mb = round(size_bytes / (1024 * 1024), 2) if size_bytes else None
                    url = f"https://www.kaggle.com/datasets/{ref}"
                    license_name = getattr(ds, "licenseName", "Unknown")

                    discovered.append({
                        "id": f"kaggle_{ref.replace('/', '_')}",
                        "source": "kaggle",
                        "ref": ref,
                        "title": title,
                        "url": url,
                        "size_mb": size_mb,
                        "license": license_name,
                        "status": "discovered"
                    })
        except Exception as e:
            print(f"[Kaggle Discovery Error] {e}")
        return discovered

    def discover_huggingface(self, query: str = "object-detection", limit: int = 30) -> List[Dict[str, Any]]:
        """Queries Hugging Face for object detection datasets."""
        discovered = []
        try:
            from huggingface_hub import HfApi
            api = HfApi()
            ds_list = list(api.list_datasets(search=query, limit=limit))
            for ds in ds_list:
                repo_id = ds.id
                url = f"https://huggingface.co/datasets/{repo_id}"
                downloads = getattr(ds, "downloads", 0)
                likes = getattr(ds, "likes", 0)
                
                discovered.append({
                    "id": f"hf_{repo_id.replace('/', '_').replace('-', '_')}",
                    "source": "huggingface",
                    "repo_id": repo_id,
                    "title": repo_id,
                    "url": url,
                    "downloads": downloads,
                    "likes": likes,
                    "license": "Open Source / Public",
                    "status": "discovered"
                })
        except Exception as e:
            print(f"[Hugging Face Discovery Error] {e}")
        return discovered

    def load_manifest(self) -> Dict[str, Any]:
        """Loads manifest JSON or initializes a new one."""
        if os.path.exists(self.manifest_path):
            try:
                with open(self.manifest_path, "r") as f:
                    return json.load(f)
            except Exception:
                pass
        return {
            "project": "SmartVision Object Detection Pipeline",
            "last_updated": time.strftime("%Y-%m-%d %H:%M:%S"),
            "datasets": {}
        }

    def save_manifest(self, manifest: Dict[str, Any]):
        """Saves manifest JSON atomically."""
        manifest["last_updated"] = time.strftime("%Y-%m-%d %H:%M:%S")
        temp_path = self.manifest_path + ".tmp"
        with open(temp_path, "w") as f:
            json.dump(manifest, f, indent=2)
        os.replace(temp_path, self.manifest_path)

    def run_discovery(self) -> List[Dict[str, Any]]:
        """Runs full discovery across all configured platforms."""
        print("=" * 65)
        print("SMARTVISION DATASET DISCOVERY ENGINE")
        print("=" * 65)
        manifest = self.load_manifest()
        all_discovered = []

        # 1. Kaggle Discovery
        if self.discovery_cfg.get("kaggle", {}).get("enabled", True):
            q = self.discovery_cfg.get("kaggle", {}).get("query", "object detection")
            mp = self.discovery_cfg.get("kaggle", {}).get("max_pages", 5)
            print(f"Discovering Kaggle datasets for query: '{q}' (max {mp} pages)...")
            k_ds = self.discover_kaggle(query=q, max_pages=mp)
            print(f"Found {len(k_ds)} Kaggle datasets.")
            all_discovered.extend(k_ds)

        # 2. Hugging Face Discovery
        if self.discovery_cfg.get("huggingface", {}).get("enabled", True):
            hq = self.discovery_cfg.get("huggingface", {}).get("query", "object-detection")
            hl = self.discovery_cfg.get("huggingface", {}).get("limit", 30)
            print(f"Discovering Hugging Face datasets for query: '{hq}' (limit {hl})...")
            hf_ds = self.discover_huggingface(query=hq, limit=hl)
            print(f"Found {len(hf_ds)} Hugging Face datasets.")
            all_discovered.extend(hf_ds)

        # Merge into manifest
        for ds in all_discovered:
            ds_id = ds["id"]
            if ds_id not in manifest["datasets"]:
                manifest["datasets"][ds_id] = ds
            else:
                # Update metadata while keeping download status
                for k, v in ds.items():
                    if k != "status" or manifest["datasets"][ds_id].get("status") == "discovered":
                        manifest["datasets"][ds_id][k] = v

        self.save_manifest(manifest)
        print(f"Total cataloged datasets in manifest: {len(manifest['datasets'])}")
        return all_discovered

    def download_dataset(self, ds_info: Dict[str, Any]) -> Tuple[bool, str]:
        """Downloads a single dataset with limits, retry, and progress reporting."""
        ds_id = ds_info["id"]
        source = ds_info.get("source")
        target_dir = os.path.join(self.raw_dir, ds_id)

        # Check if already downloaded
        if os.path.exists(target_dir) and len(os.listdir(target_dir)) > 0:
            return True, f"Dataset already downloaded at {target_dir}."

        # Check storage limits
        min_free_gb = self.limits_cfg.get("min_free_disk_gb", 4.0)
        current_free_gb = get_free_disk_space_gb(self.raw_dir)
        if current_free_gb < min_free_gb:
            return False, f"Aborting download: Free disk space ({current_free_gb:.1f} GB) is below minimum threshold ({min_free_gb} GB)."

        max_size_mb = self.limits_cfg.get("max_dataset_size_mb", 400)
        ds_size = ds_info.get("size_mb")
        if ds_size and ds_size > max_size_mb:
            return False, f"Skipping dataset: Size ({ds_size} MB) exceeds maximum limit ({max_size_mb} MB)."

        os.makedirs(target_dir, exist_ok=True)
        retries = self.limits_cfg.get("retry_attempts", 3)
        backoff = self.limits_cfg.get("retry_backoff_sec", 2)

        for attempt in range(1, retries + 1):
            try:
                print(f"[{ds_id}] Download attempt {attempt}/{retries}...")
                if source == "kaggle":
                    import kaggle
                    ref = ds_info["ref"]
                    kaggle.api.dataset_download_files(ref, path=target_dir, unzip=True, quiet=False)
                    return True, "Kaggle dataset downloaded and extracted."
                elif source == "huggingface":
                    from huggingface_hub import snapshot_download
                    repo_id = ds_info["repo_id"]
                    snapshot_download(
                        repo_id=repo_id,
                        repo_type="dataset",
                        local_dir=target_dir,
                        local_dir_use_symlinks=False,
                        max_workers=2
                    )
                    return True, "Hugging Face dataset downloaded."
                elif source == "http_zip":
                    url = ds_info["url"]
                    zip_path = os.path.join(target_dir, "archive.zip")
                    urllib.request.urlretrieve(url, zip_path)
                    with zipfile.ZipFile(zip_path, "r") as zf:
                        zf.extractall(target_dir)
                    if os.path.exists(zip_path):
                        os.remove(zip_path)
                    return True, "HTTP zip package downloaded and extracted."
                else:
                    return False, f"Unsupported dataset source: {source}"
            except Exception as e:
                print(f"[{ds_id}] Attempt {attempt} failed: {e}")
                if attempt < retries:
                    time.sleep(backoff ** attempt)
                else:
                    return False, str(e)
        return False, "Exhausted all download retries."

    def download_batch(self, max_downloads: Optional[int] = None) -> Dict[str, Any]:
        """Downloads discovered datasets in batches respecting limits."""
        manifest = self.load_manifest()
        limit = max_downloads or self.limits_cfg.get("max_downloads", 5)

        results = {
            "downloaded": 0,
            "skipped": 0,
            "failed": 0,
            "details": []
        }

        candidates = [
            ds for ds in manifest["datasets"].values()
            if ds.get("status") in ["discovered", "pending"]
        ]

        print(f"Starting batch download (up to {limit} datasets)...")
        for ds in candidates:
            if results["downloaded"] >= limit:
                print(f"Reached batch limit of {limit} downloads.")
                break

            ds_id = ds["id"]
            success, msg = self.download_dataset(ds)
            if success:
                ds["status"] = "downloaded"
                ds["download_msg"] = msg
                results["downloaded"] += 1
                print(f"✓ [{ds_id}] Success: {msg}")
            else:
                if "Skipping" in msg or "Aborting" in msg:
                    ds["status"] = "skipped"
                    results["skipped"] += 1
                    print(f"⚠ [{ds_id}] Skipped: {msg}")
                else:
                    ds["status"] = "failed"
                    results["failed"] += 1
                    print(f"✗ [{ds_id}] Failed: {msg}")
                ds["failure_reason"] = msg

            results["details"].append({"id": ds_id, "status": ds["status"], "message": msg})
            self.save_manifest(manifest)

        return results
