import sys
import os

# Tambahkan direktori backend ke path
sys.path.insert(0, os.path.dirname(__file__))

import uvicorn
from app.main import app

if __name__ == "__main__":
    print("=" * 60)
    print("  SAHABAT MASJID - REST API BACKEND (Python)")
    print("  Masjid Al-Ikhlas - SRS v1.0")
    print("  Server berjalan di: http://127.0.0.1:8000")
    print("  Tekan Ctrl+C untuk menghentikan server.")
    print("=" * 60)
    uvicorn.run("app.main:app", host="127.0.0.1", port=8000, reload=True)
