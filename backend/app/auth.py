import hashlib
import hmac
import base64
import json
import time
from app.config import SECRET_KEY, PASSWORD_SALT, TOKEN_EXPIRE_HOURS
from app.database import db

def hash_password(password: str) -> str:
    """Hash password dengan SHA-256 dan salt."""
    salted = f"{PASSWORD_SALT}:{password}"
    return hashlib.sha256(salted.encode('utf-8')).hexdigest()

def verify_password(password: str, hashed: str) -> bool:
    """Verifikasi kecocokan password."""
    return hash_password(password) == hashed

def create_token(user_id: int, email: str, role: str) -> str:
    """Buat token akses mandiri berbasis HMAC-SHA256."""
    header = {"alg": "HS256", "typ": "JWT"}
    payload = {
        "user_id": user_id,
        "email": email,
        "role": role,
        "exp": int(time.time()) + (TOKEN_EXPIRE_HOURS * 3600)
    }
    
    header_b64 = base64.urlsafe_b64encode(json.dumps(header).encode()).decode().rstrip("=")
    payload_b64 = base64.urlsafe_b64encode(json.dumps(payload).encode()).decode().rstrip("=")
    signature_data = f"{header_b64}.{payload_b64}".encode()
    
    sig = hmac.new(SECRET_KEY.encode(), signature_data, hashlib.sha256).digest()
    sig_b64 = base64.urlsafe_b64encode(sig).decode().rstrip("=")
    
    return f"{header_b64}.{payload_b64}.{sig_b64}"

def decode_token(token: str) -> dict:
    """Validasi dan baca payload token."""
    try:
        parts = token.split(".")
        if len(parts) != 3:
            return None
        header_b64, payload_b64, sig_b64 = parts
        
        # Cek tanda tangan
        signature_data = f"{header_b64}.{payload_b64}".encode()
        expected_sig = hmac.new(SECRET_KEY.encode(), signature_data, hashlib.sha256).digest()
        
        # Tambah padding
        pad = len(sig_b64) % 4
        if pad:
            sig_b64 += "=" * (4 - pad)
        actual_sig = base64.urlsafe_b64decode(sig_b64.encode())
        
        if not hmac.compare_digest(expected_sig, actual_sig):
            return None
            
        pad = len(payload_b64) % 4
        if pad:
            payload_b64 += "=" * (4 - pad)
        payload = json.loads(base64.urlsafe_b64decode(payload_b64.encode()).decode())
        
        # Cek kedaluwarsa
        if payload.get("exp", 0) < time.time():
            return None
            
        return payload
    except Exception:
        return None

def get_current_user(auth_header: str) -> dict:
    """Ambil user aktif dari header Authorization: Bearer <token>"""
    if not auth_header or not auth_header.startswith("Bearer "):
        return None
    token = auth_header[7:].strip()
    payload = decode_token(token)
    if not payload:
        return None
        
    user = db.fetch_one("SELECT id, name, email, role, is_active FROM users WHERE id = %s", (payload["user_id"],))
    if not user or not user["is_active"]:
        return None
    return user

def log_audit(user_id: int, action: str, entity: str, entity_id: int, reason: str = "", details: str = ""):
    """Pencatatan jejak audit (FR-15, FR-16, FR-21, Bab 8.2)."""
    try:
        db.execute(
            "INSERT INTO audit_logs (user_id, action, entity, entity_id, reason, details) VALUES (%s, %s, %s, %s, %s, %s)",
            (user_id, action, entity, entity_id, reason, details)
        )
    except Exception as e:
        print(f"[Audit] Gagal mencatat audit log: {e}")
