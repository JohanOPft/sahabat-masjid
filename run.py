import sys
import os

# Arahkan path ke folder backend
current_dir = os.path.dirname(os.path.abspath(__file__))
backend_dir = os.path.join(current_dir, "backend")
sys.path.insert(0, backend_dir)

import uvicorn
from app.main import app
from app.config import SERVER_HOST, SERVER_PORT, DB_TYPE, DB_HOST, DB_PORT, DB_NAME
from app.database import db

if __name__ == "__main__":
    print("=" * 65)
    print("  🕌 SAHABAT MASJID - REST API BACKEND & DATABASE MYSQL")
    print("  Masjid Al-Ikhlas - SRS v1.0")
    print(f"  Mode Database: {'MySQL' if db.is_mysql else 'SQLite'}")
    if db.is_mysql:
        print(f"  Terhubung ke: {DB_HOST}:{DB_PORT} (Database: {DB_NAME})")
    print(f"  Server Aktif di: http://{SERVER_HOST}:{SERVER_PORT}")
    print(f"  Health Check:   http://{SERVER_HOST}:{SERVER_PORT}/api/health")
    print("=" * 65)
    uvicorn.run("app.main:app", host=SERVER_HOST, port=SERVER_PORT, reload=True)
