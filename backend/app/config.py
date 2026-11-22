import os
from pathlib import Path

# Coba load file .env jika ada
try:
    from dotenv import load_dotenv
    # Cari .env di backend/.env atau di root project
    env_backend = Path(__file__).resolve().parent.parent / ".env"
    env_root = Path(__file__).resolve().parent.parent.parent / ".env"
    if env_backend.exists():
        load_dotenv(env_backend)
    elif env_root.exists():
        load_dotenv(env_root)
    else:
        load_dotenv()
except ImportError:
    pass

# =====================================================================
# KONFIGURASI DATABASE MYSQL
# =====================================================================
DB_TYPE = os.getenv("DB_TYPE", "mysql").lower()
DB_HOST = os.getenv("DB_HOST", "127.0.0.1")
DB_PORT = int(os.getenv("DB_PORT", "3306"))
DB_USER = os.getenv("DB_USER", "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_NAME = os.getenv("DB_NAME", "sahabat_masjid")

# Fallback lokal jika MySQL belum dinyalakan
SQLITE_PATH = os.getenv(
    "SQLITE_PATH", 
    str(Path(__file__).resolve().parent.parent / "sahabat_masjid.db")
)

# =====================================================================
# KEAMANAN & TOKEN OTORISASI
# =====================================================================
SECRET_KEY = os.getenv("SECRET_KEY", "sahabat_masjid_secret_key_2026_alikhlas")
PASSWORD_SALT = os.getenv("PASSWORD_SALT", "sahabat_masjid_salt")
TOKEN_EXPIRE_HOURS = int(os.getenv("TOKEN_EXPIRE_HOURS", "24"))

# =====================================================================
# SERVER HOST & PORT
# =====================================================================
SERVER_HOST = os.getenv("SERVER_HOST", "127.0.0.1")
SERVER_PORT = int(os.getenv("SERVER_PORT", "8000"))

# =====================================================================
# UPLOADS FOLDER
# =====================================================================
UPLOAD_DIR = str(Path(__file__).resolve().parent.parent / "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)
