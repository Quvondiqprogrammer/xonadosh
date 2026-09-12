#!/usr/bin/env python3
"""Deploy Flutter web (backend/app), APIs, Admin panel and core files to honadosh.uz via FTP.

Credentials: env FTP_HOST / FTP_USER / FTP_PASS
  or backend/config.local.php keys ftp_host, ftp_user, ftp_pass
  (defaults: host 142.132.250.229, user 69561c631190f_honadosh.uz).

Usage:
  FTP_USER='69561c631190f_honadosh.uz' FTP_PASS='Asad03@18' python3 scripts/deploy_ftp.py [all|app|api|admin]
"""
from __future__ import annotations

import ftplib
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BACKEND = ROOT / "backend"


def load_creds() -> tuple[str, str, str]:
    host = os.environ.get("FTP_HOST", "142.132.250.229")
    user = os.environ.get("FTP_USER", "69561c631190f_honadosh.uz")
    password = os.environ.get("FTP_PASS", "Asad03@18")
    cfg = BACKEND / "config.local.php"
    if cfg.exists() and (not user or not password):
        text = cfg.read_text(encoding="utf-8", errors="replace")
        def grab(key: str) -> str:
            m = re.search(rf"'{key}'\s*=>\s*'([^']*)'", text)
            return m.group(1) if m else ""
        if not user:
            db_user = grab("db_user")
            user = grab("ftp_user") or (f"{db_user}.uz" if db_user else "")
        if not password:
            password = grab("ftp_pass") or grab("db_pass")
        host = grab("ftp_host") or host
    return host, user, password


def ensure_dir(ftp: ftplib.FTP, path: str) -> None:
    parts = path.strip("/").split("/")
    cur = ""
    for p in parts:
        if not p:
            continue
        cur = f"{cur}/{p}" if cur else p
        try:
            ftp.mkd(cur)
        except Exception:
            pass


def upload_file(ftp: ftplib.FTP, local: Path, remote: str) -> None:
    parent = str(Path(remote).parent).replace("\\", "/")
    if parent not in (".", ""):
        ensure_dir(ftp, parent)
    with open(local, "rb") as f:
        ftp.storbinary(f"STOR {remote}", f)


def main() -> int:
    host, user, password = load_creds()
    ftp = ftplib.FTP()
    ftp.connect(host, 21, timeout=120)
    ftp.login(user, password)
    ftp.set_pasv(True)
    print("FTP Connected:", ftp.pwd())

    uploaded = 0
    errors: list[str] = []
    only = (sys.argv[1] if len(sys.argv) > 1 else "").strip().lower()

    def upload_tree(local_root: Path, remote_prefix: str) -> None:
        nonlocal uploaded
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
                try:
                    upload_file(ftp, local, remote)
                    uploaded += 1
                    if uploaded % 25 == 0:
                        print(f"  … {uploaded} files uploaded")
                except Exception as e:
                    errors.append(f"{remote}: {e}")

    if only in ("", "all", "api"):
        print("Uploading backend/api/ …")
        upload_tree(BACKEND / "api", "api")
        print("Uploading backend/includes/ …")
        upload_tree(BACKEND / "includes", "includes")

    if only in ("", "all", "admin"):
        print("Uploading backend/admin/ …")
        upload_tree(BACKEND / "admin", "admin")

    if only in ("", "all", "app"):
        print("Uploading backend/app/ (Flutter Web) …")
        upload_tree(BACKEND / "app", "app")

    if only in ("", "all", "pitch"):
        print("Uploading backend/pitch/ …")
        upload_tree(BACKEND / "pitch", "pitch")

    if only in ("", "all", "assets"):
        print("Uploading backend/assets/ …")
        upload_tree(BACKEND / "assets", "assets")

    if only in ("", "all", "root", "pitch"):
        for root_file in ("index.html", ".htaccess"):
            local = BACKEND / root_file
            if local.exists():
                try:
                    upload_file(ftp, local, root_file)
                    uploaded += 1
                    print(f"Root file: {root_file}")
                except Exception as e:
                    errors.append(f"{root_file}: {e}")

        for rel in (
            "uploads/.htaccess",
            "uploads/listings/.htaccess",
            "uploads/listings/.gitkeep",
        ):
            local = BACKEND / rel
            if local.exists():
                try:
                    upload_file(ftp, local, rel)
                    uploaded += 1
                except Exception as e:
                    errors.append(f"{rel}: {e}")

    print(f"\nDEPLOY FINISHED: uploaded={uploaded} errors={len(errors)}")
    for e in errors[:20]:
        print("ERR", e)
    ftp.quit()
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
