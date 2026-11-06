#!/usr/bin/env python3
"""
Deploy Flutter web (backend/app), APIs, Admin panel, and core backend files to honadosh.uz via FTP.

Usage:
  python3 scripts/deploy_ftp.py [all|app|api|admin|includes|quick]
"""
from __future__ import annotations

import ftplib
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOCAL_BACKEND_DIR = ROOT / "backend"

FTP_HOST = os.environ.get("FTP_HOST", "142.132.250.229")
FTP_PORT = int(os.environ.get("FTP_PORT", "21"))
FTP_USER = os.environ.get("FTP_USER", "69561c631190f_honadosh.uz")
FTP_PASS = os.environ.get("FTP_PASS", "Asad03@18")

def ensure_remote_dir(ftp: ftplib.FTP, remote_dir: str) -> None:
    parts = [p for p in remote_dir.strip("/").split("/") if p]
    current = ""
    for part in parts:
        current += "/" + part
        try:
            ftp.cwd(current)
        except ftplib.error_perm:
            try:
                ftp.mkd(current)
                ftp.cwd(current)
            except Exception:
                pass

def upload_file(ftp: ftplib.FTP, local_path: Path, remote_path: str) -> bool:
    remote_dir = os.path.dirname(remote_path)
    if remote_dir:
        ensure_remote_dir(ftp, remote_dir)
        try:
            ftp.cwd("/")
        except Exception:
            pass
    
    try:
        with open(local_path, "rb") as f:
            ftp.storbinary(f"STOR {remote_path.lstrip('/')}", f)
        return True
    except Exception as e:
        print(f"Error uploading {remote_path}: {e}")
        return False

def upload_tree(ftp: ftplib.FTP, local_root: Path, remote_prefix: str) -> int:
    uploaded = 0
    for dirpath, _, filenames in os.walk(local_root):
        rel = os.path.relpath(dirpath, local_root)
        for name in filenames:
            if name.startswith(".") and name not in (".htaccess",):
                continue
            local = Path(dirpath) / name
            remote = (
                f"{remote_prefix}/{name}"
                if rel == "."
                else f"{remote_prefix}/{rel}/{name}".replace("\\", "/")
            )
            if upload_file(ftp, local, "/" + remote):
                uploaded += 1
                if uploaded % 20 == 0:
                    print(f"  … {uploaded} files transferred ({remote_prefix})")
    return uploaded

def main() -> int:
    target = (sys.argv[1] if len(sys.argv) > 1 else "all").strip().lower()
    print(f"Connecting to FTP {FTP_HOST}:{FTP_PORT} as {FTP_USER} (target: {target})...")

    try:
        ftp = ftplib.FTP()
        ftp.connect(FTP_HOST, FTP_PORT, timeout=60)
        ftp.login(FTP_USER, FTP_PASS)
        ftp.set_pasv(True)
        print("FTP login successful!\n")
    except Exception as e:
        print(f"FTP connection failed: {e}")
        return 1

    total_uploaded = 0

    # 1. Root and config files
    if target in ("all", "quick", "root"):
        print("→ Uploading root & config files...")
        root_files = [
            "config.local.php",
            "index.html",
            "robots.txt",
            "sitemap.xml",
            ".htaccess",
        ]
        for rf in root_files:
            lf = LOCAL_BACKEND_DIR / rf
            if lf.exists():
                if upload_file(ftp, lf, "/" + rf):
                    total_uploaded += 1
                    print(f"  ✓ {rf}")

    # 2. Includes & Libraries
    if target in ("all", "quick", "api", "includes"):
        print("→ Uploading backend/includes/...")
        total_uploaded += upload_tree(ftp, LOCAL_BACKEND_DIR / "includes", "includes")

    # 3. APIs
    if target in ("all", "quick", "api"):
        print("→ Uploading backend/api/...")
        total_uploaded += upload_tree(ftp, LOCAL_BACKEND_DIR / "api", "api")

    # 4. Admin panel
    if target in ("all", "quick", "admin"):
        print("→ Uploading backend/admin/...")
        total_uploaded += upload_tree(ftp, LOCAL_BACKEND_DIR / "admin", "admin")

    # 4b. Migrations
    if target in ("all", "quick", "migrations"):
        print("→ Uploading backend/migrations/...")
        total_uploaded += upload_tree(ftp, LOCAL_BACKEND_DIR / "migrations", "migrations")

    # 4c. SEO SSR pages (uylar)
    if target in ("all", "quick", "uylar"):
        print("→ Uploading backend/uylar/...")
        total_uploaded += upload_tree(ftp, LOCAL_BACKEND_DIR / "uylar", "uylar")

    # 5. Assets
    if target in ("all", "assets"):
        print("→ Uploading backend/assets/...")
        total_uploaded += upload_tree(ftp, LOCAL_BACKEND_DIR / "assets", "assets")

    # 6. Web App (Flutter build)
    if target in ("all", "app"):
        app_dir = LOCAL_BACKEND_DIR / "app"
        if app_dir.exists():
            print("→ Uploading backend/app (Flutter Web)...")
            total_uploaded += upload_tree(ftp, app_dir, "app")

    # 7. Uploads htaccess protection
    if target in ("all", "quick"):
        for sub in ("uploads/.htaccess", "uploads/listings/.htaccess"):
            lf = LOCAL_BACKEND_DIR / sub
            if lf.exists():
                upload_file(ftp, lf, "/" + sub)

    try:
        ftp.quit()
    except Exception:
        pass

    print(f"\n✓ Deploy finished: {total_uploaded} files transferred successfully!")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
