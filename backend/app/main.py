import os
import json
import uuid
import datetime
from starlette.applications import Starlette
from starlette.responses import JSONResponse, Response
from starlette.routing import Route, Mount
from starlette.middleware import Middleware
from starlette.middleware.cors import CORSMiddleware
from starlette.staticfiles import StaticFiles

from app.config import UPLOAD_DIR
from app.database import db
from app.auth import hash_password, verify_password, create_token, get_current_user, log_audit

import decimal

class JSONCustomEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, (datetime.date, datetime.datetime)):
            return obj.isoformat()
        if isinstance(obj, decimal.Decimal):
            return float(obj)
        return super().default(obj)

class CustomJSONResponse(JSONResponse):
    def render(self, content) -> bytes:
        return json.dumps(
            content,
            ensure_ascii=False,
            allow_nan=False,
            indent=None,
            separators=(",", ":"),
            cls=JSONCustomEncoder
        ).encode("utf-8")

# Inisialisasi Database
db.init_tables()

# =====================================================================
# HELPER FUNCTIONS
# =====================================================================

def error_response(message: str, status_code: int = 400):
    return CustomJSONResponse({"success": False, "message": message}, status_code=status_code)

def success_response(data=None, message: str = "Sukses", status_code: int = 200):
    res = {"success": True, "message": message}
    if data is not None:
        res["data"] = data
    return CustomJSONResponse(res, status_code=status_code)

def get_auth_user(request):
    auth_header = request.headers.get("authorization", "")
    return get_current_user(auth_header)

def require_auth(request, allowed_roles=None):
    user = get_auth_user(request)
    if not user:
        return None, error_response("Sesi telah berakhir atau Anda belum masuk. Silakan login kembali.", 401)
    if allowed_roles and user["role"] not in allowed_roles:
        return None, error_response("Akses ditolak. Anda tidak memiliki izin untuk tindakan ini.", 403)
    return user, None

# =====================================================================
# ROUTE HANDLERS
# =====================================================================

# 1. Health & Status
async def health(request):
    return success_response({
        "status": "online",
        "app": "Sahabat Masjid API v1.0",
        "database": "MySQL" if db.is_mysql else "SQLite (Fallback)",
        "timestamp": datetime.datetime.now().isoformat()
    })

# 2. Auth Endpoints (FR-01 - FR-05)
async def register(request):
    try:
        body = await request.json()
    except Exception:
        return error_response("Format data tidak valid.")

    name = body.get("name", "").strip()
    email = body.get("email", "").strip().lower()
    password = body.get("password", "")
    role = body.get("role", "admin").lower().strip()

    if not name or not email or not password:
        return error_response("Nama lengkap, email, dan kata sandi wajib diisi.")
    if role not in ["admin", "takmir"]:
        return error_response("Peran akun harus berupa 'admin' (Marbot) atau 'takmir'.")
    if len(password) < 6:
        return error_response("Kata sandi minimal 6 karakter.")

    existing = db.fetch_one("SELECT id FROM users WHERE email = %s", (email,))
    if existing:
        return error_response("Email tersebut sudah terdaftar di sistem masjid.")

    pwd_hash = hash_password(password)
    new_id = db.execute(
        "INSERT INTO users (name, email, password_hash, role, is_active) VALUES (%s, %s, %s, %s, 1)",
        (name, email, pwd_hash, role)
    )
    log_audit(new_id, "REGISTER", "users", new_id, f"Pendaftaran akun baru: {name} ({role})")

    token = create_token(new_id, email, role)
    return success_response({
        "token": token,
        "user": {
            "id": new_id,
            "name": name,
            "email": email,
            "role": role
        }
    }, f"Pendaftaran berhasil! Akun {role.upper()} atas nama {name} siap digunakan.", 201)

async def login(request):
    try:
        body = await request.json()
    except Exception:
        return error_response("Format request tidak valid.")
    
    email = body.get("email", "").strip().lower()
    password = body.get("password", "")
    
    if not email or not password:
        return error_response("Email dan kata sandi wajib diisi.")
        
    user = db.fetch_one("SELECT * FROM users WHERE email = %s", (email,))
    if not user or not verify_password(password, user["password_hash"]):
        return error_response("Email atau kata sandi yang Anda masukkan salah.", 401)
        
    if not user["is_active"]:
        return error_response("Akun Anda telah dinonaktifkan oleh Takmir. Hubungi pengurus masjid.", 403)
        
    token = create_token(user["id"], user["email"], user["role"])
    log_audit(user["id"], "LOGIN", "users", user["id"], "Pengurus masuk ke sistem")
    
    return success_response({
        "token": token,
        "user": {
            "id": user["id"],
            "name": user["name"],
            "email": user["email"],
            "role": user["role"]
        }
    }, "Berhasil masuk ke aplikasi Sahabat Masjid.")

async def get_me(request):
    user, err = require_auth(request)
    if err: return err
    return success_response(user)

async def list_users(request):
    user, err = require_auth(request, ["takmir"])
    if err: return err
    users = db.fetch_all("SELECT id, name, email, role, is_active, created_at FROM users ORDER BY id ASC")
    return success_response(users)

async def create_user(request):
    admin_user, err = require_auth(request, ["takmir"])
    if err: return err
    
    body = await request.json()
    name = body.get("name", "").strip()
    email = body.get("email", "").strip().lower()
    password = body.get("password", "")
    role = body.get("role", "admin")
    
    if not name or not email or not password:
        return error_response("Nama, email, dan kata sandi wajib diisi.")
    if role not in ["admin", "takmir"]:
        return error_response("Peran harus berupa admin atau takmir.")
        
    existing = db.fetch_one("SELECT id FROM users WHERE email = %s", (email,))
    if existing:
        return error_response("Email tersebut sudah terdaftar.")
        
    pwd_hash = hash_password(password)
    new_id = db.execute(
        "INSERT INTO users (name, email, password_hash, role, is_active) VALUES (%s, %s, %s, %s, 1)",
        (name, email, pwd_hash, role)
    )
    log_audit(admin_user["id"], "CREATE_USER", "users", new_id, f"Menambah akun {role} ({name})")
    return success_response({"id": new_id}, "Akun pengurus berhasil dibuat.", 201)

async def toggle_user_active(request):
    admin_user, err = require_auth(request, ["takmir"])
    if err: return err
    user_id = int(request.path_params["id"])
    
    target = db.fetch_one("SELECT id, name, is_active FROM users WHERE id = %s", (user_id,))
    if not target:
        return error_response("Akun tidak ditemukan.", 404)
    if target["id"] == admin_user["id"]:
        return error_response("Anda tidak dapat menonaktifkan akun Anda sendiri.")
        
    new_state = 0 if target["is_active"] else 1
    db.execute("UPDATE users SET is_active = %s WHERE id = %s", (new_state, user_id))
    log_audit(admin_user["id"], "TOGGLE_USER", "users", user_id, f"Mengubah status aktif menjadi {new_state}")
    return success_response({"is_active": new_state}, "Status akun berhasil diperbarui.")

async def reset_user_password(request):
    admin_user, err = require_auth(request, ["takmir"])
    if err: return err
    user_id = int(request.path_params["id"])
    body = await request.json()
    new_pass = body.get("new_password", "")
    if not new_pass or len(new_pass) < 6:
        return error_response("Kata sandi baru minimal 6 karakter.")
        
    pwd_hash = hash_password(new_pass)
    db.execute("UPDATE users SET password_hash = %s WHERE id = %s", (pwd_hash, user_id))
    log_audit(admin_user["id"], "RESET_PASSWORD", "users", user_id, "Mengatur ulang kata sandi")
    return success_response(None, "Kata sandi akun berhasil diatur ulang.")

# 3. Activities Endpoints (FR-06 - FR-10)
async def list_activities(request):
    status_filter = request.query_params.get("status")
    query = """
    SELECT a.*, u.name as creator_name,
           COALESCE((SELECT SUM(value_amount) FROM donations WHERE activity_id = a.id AND status = 'terverifikasi' AND type = 'uang'), 0) as total_donation_uang,
           COALESCE((SELECT SUM(amount) FROM expenses WHERE activity_id = a.id AND status = 'sah'), 0) as total_expense,
           COALESCE((SELECT SUM(portions) FROM donations WHERE activity_id = a.id AND status = 'terverifikasi' AND type = 'makanan'), 0) as total_food_portions,
           COALESCE((SELECT SUM(amount) FROM cash_transactions WHERE activity_id = a.id AND status = 'sah' AND direction = 'keluar'), 0) as total_cash_subsidy
    FROM activities a
    LEFT JOIN users u ON a.created_by = u.id
    """
    params = []
    if status_filter:
        query += " WHERE a.status = %s"
        params.append(status_filter)
    query += " ORDER BY a.activity_date ASC, a.activity_time ASC"
    
    activities = db.fetch_all(query, tuple(params))
    for act in activities:
        # Selisih = total_expense - total_donation_uang - total_cash_subsidy
        # Defisit jika expense > (donasi + subsidi kas)
        uang = float(act.get("total_donation_uang", 0))
        exp = float(act.get("total_expense", 0))
        sub = float(act.get("total_cash_subsidy", 0))
        act["net_balance"] = uang + sub - exp
        act["is_deficit"] = exp > (uang + sub)
        act["deficit_amount"] = max(0.0, exp - (uang + sub))
        act["needs_pj"] = (act.get("pj_name") is None or act.get("pj_name").strip() == "")
        
    return success_response(activities)

async def get_activity(request):
    act_id = int(request.path_params["id"])
    activity = db.fetch_one("""
        SELECT a.*, u.name as creator_name
        FROM activities a
        LEFT JOIN users u ON a.created_by = u.id
        WHERE a.id = %s
    """, (act_id,))
    if not activity:
        return error_response("Kegiatan tidak ditemukan.", 404)
        
    donations = db.fetch_all("SELECT * FROM donations WHERE activity_id = %s ORDER BY donation_date DESC", (act_id,))
    expenses = db.fetch_all("SELECT * FROM expenses WHERE activity_id = %s ORDER BY expense_date DESC", (act_id,))
    cash_subsidies = db.fetch_all("SELECT * FROM cash_transactions WHERE activity_id = %s AND direction = 'keluar' AND status = 'sah'", (act_id,))
    
    total_uang = sum(float(d["value_amount"]) for d in donations if d["type"] == "uang" and d["status"] == "terverifikasi")
    total_food = sum(int(d["portions"] or 0) for d in donations if d["type"] == "makanan" and d["status"] == "terverifikasi")
    total_exp = sum(float(e["amount"]) for e in expenses if e["status"] == "sah")
    total_sub = sum(float(c["amount"]) for c in cash_subsidies)
    
    activity["donations"] = donations
    activity["expenses"] = expenses
    activity["cash_subsidies"] = cash_subsidies
    activity["total_donation_uang"] = total_uang
    activity["total_food_portions"] = total_food
    activity["total_expense"] = total_exp
    activity["total_cash_subsidy"] = total_sub
    activity["deficit_amount"] = max(0.0, total_exp - (total_uang + total_sub))
    activity["is_deficit"] = total_exp > (total_uang + total_sub)
    activity["needs_pj"] = (activity.get("pj_name") is None or activity.get("pj_name").strip() == "")
    
    return success_response(activity)

async def create_activity(request):
    user, err = require_auth(request, ["admin", "takmir"])
    if err: return err
    body = await request.json()
    
    title = body.get("title", "").strip()
    act_type = body.get("type", "Lainnya")
    date = body.get("activity_date", "").strip()
    time_str = body.get("activity_time", "").strip()
    location = body.get("location", "Masjid Al-Ikhlas").strip()
    pj_name = body.get("pj_name", "").strip() or None
    notes = body.get("notes", "").strip()
    
    if not title or not date or not time_str:
        return error_response("Nama kegiatan, tanggal, dan waktu wajib diisi.")
        
    new_id = db.execute("""
        INSERT INTO activities (title, type, activity_date, activity_time, location, pj_name, notes, status, created_by)
        VALUES (%s, %s, %s, %s, %s, %s, %s, 'terjadwal', %s)
    """, (title, act_type, date, time_str, location, pj_name, notes, user["id"]))
    
    log_audit(user["id"], "CREATE_ACTIVITY", "activities", new_id, f"Menambah kegiatan: {title}")
    return success_response({"id": new_id}, "Kegiatan berhasil ditambahkan.", 201)

async def update_activity(request):
    user, err = require_auth(request, ["admin", "takmir"])
    if err: return err
    act_id = int(request.path_params["id"])
    body = await request.json()
    
    title = body.get("title", "").strip()
    act_type = body.get("type", "Lainnya")
    date = body.get("activity_date", "").strip()
    time_str = body.get("activity_time", "").strip()
    location = body.get("location", "Masjid Al-Ikhlas").strip()
    pj_name = body.get("pj_name", "").strip() or None
    notes = body.get("notes", "").strip()
    status = body.get("status", "terjadwal")
    
    db.execute("""
        UPDATE activities 
        SET title = %s, type = %s, activity_date = %s, activity_time = %s, location = %s, pj_name = %s, notes = %s, status = %s
        WHERE id = %s
    """, (title, act_type, date, time_str, location, pj_name, notes, status, act_id))
    
    log_audit(user["id"], "UPDATE_ACTIVITY", "activities", act_id, f"Memperbarui kegiatan: {title}")
    return success_response(None, "Kegiatan berhasil diperbarui.")

async def cancel_activity(request):
    user, err = require_auth(request, ["admin", "takmir"])
    if err: return err
    act_id = int(request.path_params["id"])
    body = await request.json()
    reason = body.get("reason", "").strip()
    if not reason:
        return error_response("Alasan pembatalan kegiatan wajib diisi.")
        
    db.execute("UPDATE activities SET status = 'dibatalkan', cancel_reason = %s WHERE id = %s", (reason, act_id))
    log_audit(user["id"], "CANCEL_ACTIVITY", "activities", act_id, reason)
    return success_response(None, "Kegiatan berhasil dibatalkan.")

async def copy_activity(request):
    # FR-08: Menyalin kegiatan sebelumnya menjadi kegiatan baru
    user, err = require_auth(request, ["admin", "takmir"])
    if err: return err
    act_id = int(request.path_params["id"])
    body = await request.json()
    new_date = body.get("activity_date", "").strip()
    new_time = body.get("activity_time", "").strip()
    
    orig = db.fetch_one("SELECT * FROM activities WHERE id = %s", (act_id,))
    if not orig:
        return error_response("Kegiatan asal tidak ditemukan.", 404)
        
    new_id = db.execute("""
        INSERT INTO activities (title, type, activity_date, activity_time, location, pj_name, notes, status, created_by)
        VALUES (%s, %s, %s, %s, %s, %s, %s, 'terjadwal', %s)
    """, (
        orig["title"],
        orig["type"],
        new_date if new_date else orig["activity_date"],
        new_time if new_time else orig["activity_time"],
        orig["location"],
        orig["pj_name"],
        orig["notes"],
        user["id"]
    ))
    log_audit(user["id"], "COPY_ACTIVITY", "activities", new_id, f"Menyalin dari kegiatan ID #{act_id}")
    return success_response({"id": new_id}, "Kegiatan berhasil disalin menjadi kegiatan baru.")

# 4. Donations Endpoints (FR-11 - FR-17)
async def list_donations(request):
    act_id = request.query_params.get("activity_id")
    dtype = request.query_params.get("type")
    start = request.query_params.get("start_date")
    end = request.query_params.get("end_date")
    status = request.query_params.get("status")
    
    query = """
        SELECT d.*, a.title as activity_title, u.name as creator_name
        FROM donations d
        LEFT JOIN activities a ON d.activity_id = a.id
        LEFT JOIN users u ON d.created_by = u.id
        WHERE 1=1
    """
    params = []
    if act_id:
        query += " AND d.activity_id = %s"
        params.append(act_id)
    if dtype:
        query += " AND d.type = %s"
        params.append(dtype)
    if start:
        query += " AND d.donation_date >= %s"
        params.append(start)
    if end:
        query += " AND d.donation_date <= %s"
        params.append(end)
    if status:
        query += " AND d.status = %s"
        params.append(status)
        
    query += " ORDER BY d.donation_date DESC, d.id DESC"
    donations = db.fetch_all(query, tuple(params))
    return success_response(donations)

async def create_donation(request):
    user, err = require_auth(request, ["admin", "takmir"])
    if err: return err
    body = await request.json()
    
    dtype = body.get("type", "uang")
    date = body.get("donation_date", "").strip() or datetime.date.today().isoformat()
    donor_name = body.get("donor_name", "").strip() or "Hamba Allah"
    desc = body.get("description", "").strip()
    act_id = body.get("activity_id") or None
    
    val_amount = float(body.get("value_amount", 0))
    portions = body.get("portions")
    payment_method = body.get("payment_method") or None
    
    # Validasi FR-13
    if dtype == "uang":
        if val_amount <= 0:
            return error_response("Nominal donasi uang harus lebih dari Rp 0.")
        if not payment_method:
            payment_method = "tunai"
    elif dtype in ["barang", "jasa"]:
        if val_amount <= 0:
            return error_response(f"Estimasi nilai rupiah untuk {dtype} harus lebih dari Rp 0.")
    elif dtype == "makanan":
        if not portions or int(portions) <= 0:
            return error_response("Jumlah porsi makanan harus lebih dari 0.")
        portions = int(portions)
        
    new_id = db.execute("""
        INSERT INTO donations (activity_id, donation_date, type, donor_name, description, value_amount, portions, payment_method, status, created_by)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, 'terverifikasi', %s)
    """, (act_id, date, dtype, donor_name, desc, val_amount, portions, payment_method, user["id"]))
    
    log_audit(user["id"], "CREATE_DONATION", "donations", new_id, f"Mencatat donasi {dtype} ({donor_name})")
    return success_response({"id": new_id}, "Donasi berhasil dicatat.", 201)

async def cancel_donation(request):
    # FR-16: Pembatalan hanya oleh Takmir dengan alasan
    user, err = require_auth(request, ["takmir"])
    if err: return err
    don_id = int(request.path_params["id"])
    body = await request.json()
    reason = body.get("reason", "").strip()
    if not reason:
        return error_response("Alasan pembatalan donasi wajib diisi.")
        
    db.execute("UPDATE donations SET status = 'dibatalkan', cancel_reason = %s WHERE id = %s", (reason, don_id))
    log_audit(user["id"], "CANCEL_DONATION", "donations", don_id, reason)
    return success_response(None, "Donasi berhasil dibatalkan.")

# 5. Expenses Endpoints (FR-18 - FR-21)
async def list_expenses(request):
    act_id = request.query_params.get("activity_id")
    query = """
        SELECT e.*, a.title as activity_title, u.name as creator_name
        FROM expenses e
        LEFT JOIN activities a ON e.activity_id = a.id
        LEFT JOIN users u ON e.created_by = u.id
        WHERE 1=1
    """
    params = []
    if act_id:
        query += " AND e.activity_id = %s"
        params.append(act_id)
    query += " ORDER BY e.expense_date DESC, e.id DESC"
    expenses = db.fetch_all(query, tuple(params))
    return success_response(expenses)

async def create_expense(request):
    user, err = require_auth(request, ["admin", "takmir"])
    if err: return err
    body = await request.json()
    
    act_id = body.get("activity_id")
    if not act_id:
        return error_response("Kegiatan pengeluaran wajib dipilih.")
    date = body.get("expense_date", "").strip() or datetime.date.today().isoformat()
    category = body.get("category", "Lainnya").strip()
    desc = body.get("description", "").strip()
    amount = float(body.get("amount", 0))
    proof = body.get("proof_photo", "").strip()
    
    if amount <= 0:
        return error_response("Nominal pengeluaran harus lebih dari Rp 0.")
    if not desc:
        return error_response("Keterangan pengeluaran wajib diisi.")
        
    new_id = db.execute("""
        INSERT INTO expenses (activity_id, expense_date, category, description, amount, proof_photo, status, created_by)
        VALUES (%s, %s, %s, %s, %s, %s, 'sah', %s)
    """, (act_id, date, category, desc, amount, proof, user["id"]))
    
    log_audit(user["id"], "CREATE_EXPENSE", "expenses", new_id, f"Mencatat pengeluaran Rp {amount:,.0f} untuk {category}")
    return success_response({"id": new_id}, "Pengeluaran kegiatan berhasil dicatat.", 201)

async def cancel_expense(request):
    # FR-21: Pembatalan hanya oleh Takmir dengan alasan
    user, err = require_auth(request, ["takmir"])
    if err: return err
    exp_id = int(request.path_params["id"])
    body = await request.json()
    reason = body.get("reason", "").strip()
    if not reason:
        return error_response("Alasan pembatalan pengeluaran wajib diisi.")
        
    db.execute("UPDATE expenses SET status = 'dibatalkan', cancel_reason = %s WHERE id = %s", (reason, exp_id))
    log_audit(user["id"], "CANCEL_EXPENSE", "expenses", exp_id, reason)
    return success_response(None, "Pengeluaran berhasil dibatalkan.")

# 6. Kas & Selisih Endpoints (FR-22 - FR-26)
async def get_cash_summary(request):
    user, err = require_auth(request, ["admin", "takmir"])
    if err: return err
    
    # Hitung saldo kas hanya dari cash_transactions yang sah (BR-03)
    masuk = db.fetch_one("SELECT COALESCE(SUM(amount), 0) as total FROM cash_transactions WHERE direction = 'masuk' AND status = 'sah'")
    keluar = db.fetch_one("SELECT COALESCE(SUM(amount), 0) as total FROM cash_transactions WHERE direction = 'keluar' AND status = 'sah'")
    
    total_masuk = float(masuk["total"] if masuk else 0)
    total_keluar = float(keluar["total"] if keluar else 0)
    current_balance = total_masuk - total_keluar
    
    # Ambil kegiatan yang defisit (pengeluaran > donasi uang + subsidi kas)
    activities = db.fetch_all("""
        SELECT a.id, a.title, a.activity_date, a.pj_name,
               COALESCE((SELECT SUM(value_amount) FROM donations WHERE activity_id = a.id AND status = 'terverifikasi' AND type = 'uang'), 0) as total_donation,
               COALESCE((SELECT SUM(amount) FROM expenses WHERE activity_id = a.id AND status = 'sah'), 0) as total_expense,
               COALESCE((SELECT SUM(amount) FROM cash_transactions WHERE activity_id = a.id AND status = 'sah' AND direction = 'keluar'), 0) as total_subsidy
        FROM activities a
        WHERE a.status != 'dibatalkan'
        ORDER BY a.activity_date DESC
    """)
    
    deficit_activities = []
    surplus_activities = []
    for a in activities:
        don = float(a["total_donation"])
        exp = float(a["total_expense"])
        sub = float(a["total_subsidy"])
        diff = (don + sub) - exp
        a["net_balance"] = diff
        if diff < 0:
            a["deficit_amount"] = abs(diff)
            deficit_activities.append(a)
        else:
            a["surplus_amount"] = diff
            surplus_activities.append(a)
            
    return success_response({
        "total_cash_in": total_masuk,
        "total_cash_out": total_keluar,
        "current_balance": current_balance,
        "deficit_activities": deficit_activities,
        "surplus_activities": surplus_activities
    })

async def list_cash_transactions(request):
    user, err = require_auth(request, ["admin", "takmir"])
    if err: return err
    
    transactions = db.fetch_all("""
        SELECT c.*, a.title as activity_title, u.name as creator_name
        FROM cash_transactions c
        LEFT JOIN activities a ON c.activity_id = a.id
        LEFT JOIN users u ON c.created_by = u.id
        ORDER BY c.transaction_date DESC, c.id DESC
    """)
    return success_response(transactions)

async def record_cash_transaction(request):
    # FR-23: Takmir mencatat transaksi kas
    user, err = require_auth(request, ["takmir"])
    if err: return err
    body = await request.json()
    
    direction = body.get("direction", "masuk")
    amount = float(body.get("amount", 0))
    note = body.get("note", "").strip()
    act_id = body.get("activity_id") or None
    date = body.get("transaction_date", "").strip() or datetime.date.today().isoformat()
    
    if amount <= 0:
        return error_response("Nominal transaksi kas harus lebih dari Rp 0.")
    if not note:
        return error_response("Keterangan transaksi kas wajib diisi.")
        
    # FR-26: Cek saldo jika keluar
    if direction == "keluar":
        masuk = db.fetch_one("SELECT COALESCE(SUM(amount), 0) as total FROM cash_transactions WHERE direction = 'masuk' AND status = 'sah'")
        keluar = db.fetch_one("SELECT COALESCE(SUM(amount), 0) as total FROM cash_transactions WHERE direction = 'keluar' AND status = 'sah'")
        curr_saldo = float(masuk["total"]) - float(keluar["total"])
        if amount > curr_saldo:
            return error_response(f"Penambalan dari kas ditolak! Saldo kas saat ini (Rp {curr_saldo:,.0f}) tidak mencukupi untuk nominal Rp {amount:,.0f}.")
            
    new_id = db.execute("""
        INSERT INTO cash_transactions (activity_id, transaction_date, direction, amount, note, status, created_by)
        VALUES (%s, %s, %s, %s, %s, 'sah', %s)
    """, (act_id, date, direction, amount, note, user["id"]))
    
    log_audit(user["id"], f"CASH_{direction.upper()}", "cash_transactions", new_id, f"Kas {direction} Rp {amount:,.0f}: {note}")
    return success_response({"id": new_id}, f"Transaksi kas {direction} berhasil dicatat.", 201)

# 7. Donation Confirmations Endpoints (FR-27 - FR-31)
async def submit_confirmation(request):
    # FR-27: Donatur mengirim konfirmasi donasi
    try:
        body = await request.json()
    except Exception:
        return error_response("Data tidak valid.")
        
    donor_name = body.get("donor_name", "").strip() or "Hamba Allah"
    contact = body.get("contact", "").strip()
    amount = float(body.get("amount", 0))
    act_id = body.get("activity_id") or None
    date = body.get("donation_date", "").strip() or datetime.date.today().isoformat()
    proof = body.get("proof_photo", "").strip()
    
    if amount <= 0:
        return error_response("Nominal donasi harus lebih dari Rp 0.")
        
    # Buat kode referensi unik FR-31
    ref_code = f"DON-{datetime.date.today().strftime('%Y%m%d')}-{uuid.uuid4().hex[:6].upper()}"
    
    new_id = db.execute("""
        INSERT INTO donation_confirmations (reference_code, activity_id, donor_name, contact, amount, donation_date, proof_photo, status)
        VALUES (%s, %s, %s, %s, %s, %s, %s, 'menunggu')
    """, (ref_code, act_id, donor_name, contact, amount, date, proof))
    
    return success_response({
        "id": new_id,
        "reference_code": ref_code
    }, "Konfirmasi donasi berhasil dikirim! Simpan kode referensi Anda untuk memantau status.", 201)

async def check_confirmation(request):
    ref_code = request.path_params["ref_code"].strip().upper()
    conf = db.fetch_one("""
        SELECT c.*, a.title as activity_title
        FROM donation_confirmations c
        LEFT JOIN activities a ON c.activity_id = a.id
        WHERE c.reference_code = %s
    """, (ref_code,))
    if not conf:
        return error_response("Kode referensi konfirmasi tidak ditemukan.", 404)
    # Masking contact jika untuk keamanan publik
    if conf.get("contact") and len(conf["contact"]) > 4:
        conf["contact"] = conf["contact"][:3] + "****" + conf["contact"][-3:]
    return success_response(conf)

async def list_confirmations(request):
    user, err = require_auth(request, ["admin", "takmir"])
    if err: return err
    status = request.query_params.get("status")
    query = """
        SELECT c.*, a.title as activity_title, u.name as reviewer_name
        FROM donation_confirmations c
        LEFT JOIN activities a ON c.activity_id = a.id
        LEFT JOIN users u ON c.reviewed_by = u.id
        WHERE 1=1
    """
    params = []
    if status:
        query += " AND c.status = %s"
        params.append(status)
    query += " ORDER BY c.created_at DESC"
    confirmations = db.fetch_all(query, tuple(params))
    return success_response(confirmations)

async def approve_confirmation(request):
    # FR-29: Menyetujui konfirmasi donasi -> otomatis membuat donasi terverifikasi
    user, err = require_auth(request, ["admin", "takmir"])
    if err: return err
    conf_id = int(request.path_params["id"])
    
    conf = db.fetch_one("SELECT * FROM donation_confirmations WHERE id = %s", (conf_id,))
    if not conf:
        return error_response("Data konfirmasi tidak ditemukan.", 404)
    if conf["status"] != "menunggu":
        return error_response(f"Konfirmasi sudah berstatus {conf['status']}.")
        
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    db.execute("""
        UPDATE donation_confirmations 
        SET status = 'disetujui', reviewed_by = %s, reviewed_at = %s 
        WHERE id = %s
    """, (user["id"], now, conf_id))
    
    # Otomatis insert ke donations terverifikasi
    don_id = db.execute("""
        INSERT INTO donations (activity_id, confirmation_id, donation_date, type, donor_name, description, value_amount, payment_method, status, created_by)
        VALUES (%s, %s, %s, 'uang', %s, %s, %s, 'transfer', 'terverifikasi', %s)
    """, (
        conf["activity_id"],
        conf["id"],
        conf["donation_date"],
        conf["donor_name"] or "Hamba Allah",
        f"Verifikasi transfer (Ref: {conf['reference_code']})",
        conf["amount"],
        user["id"]
    ))
    
    log_audit(user["id"], "APPROVE_CONFIRMATION", "donation_confirmations", conf_id, f"Menyetujui donasi Rp {conf['amount']:,.0f} dan menerbitkan donasi ID #{don_id}")
    return success_response({"donation_id": don_id}, "Konfirmasi donasi berhasil disetujui dan dicatat ke data donasi.")

async def reject_confirmation(request):
    user, err = require_auth(request, ["admin", "takmir"])
    if err: return err
    conf_id = int(request.path_params["id"])
    body = await request.json()
    reason = body.get("reason", "").strip()
    if not reason:
        return error_response("Alasan penolakan konfirmasi donasi wajib diisi.")
        
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    db.execute("""
        UPDATE donation_confirmations 
        SET status = 'ditolak', reject_reason = %s, reviewed_by = %s, reviewed_at = %s 
        WHERE id = %s
    """, (reason, user["id"], now, conf_id))
    
    log_audit(user["id"], "REJECT_CONFIRMATION", "donation_confirmations", conf_id, reason)
    return success_response(None, "Konfirmasi donasi telah ditolak.")

# 8. Reports & Publications Endpoints (FR-32 - FR-37)
async def generate_report_summary(request):
    user, err = require_auth(request, ["admin", "takmir"])
    if err: return err
    
    start_date = request.query_params.get("start_date")
    end_date = request.query_params.get("end_date")
    act_id = request.query_params.get("activity_id")
    
    # Donasi uang
    don_q = "SELECT COALESCE(SUM(value_amount), 0) as total FROM donations WHERE status = 'terverifikasi' AND type = 'uang'"
    # Nilai barang & jasa
    val_q = "SELECT COALESCE(SUM(value_amount), 0) as total FROM donations WHERE status = 'terverifikasi' AND type IN ('barang', 'jasa')"
    # Porsi makanan
    food_q = "SELECT COALESCE(SUM(portions), 0) as total FROM donations WHERE status = 'terverifikasi' AND type = 'makanan'"
    # Pengeluaran
    exp_q = "SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE status = 'sah'"
    
    params = []
    where_parts = []
    if act_id:
        where_parts.append("activity_id = %s")
        params.append(act_id)
    if start_date:
        where_parts.append("donation_date >= %s")
        params.append(start_date)
    if end_date:
        where_parts.append("donation_date <= %s")
        params.append(end_date)
        
    clause = (" AND " + " AND ".join(where_parts)) if where_parts else ""
    
    tot_uang = float(db.fetch_one(don_q + clause, tuple(params))["total"])
    tot_val = float(db.fetch_one(val_q + clause, tuple(params))["total"])
    tot_food = int(db.fetch_one(food_q + clause, tuple(params))["total"])
    
    exp_clause = clause.replace("donation_date", "expense_date")
    tot_exp = float(db.fetch_one(exp_q + exp_clause, tuple(params))["total"])
    
    summary = {
        "total_money_donation": tot_uang,
        "total_goods_services_value": tot_val,
        "total_food_portions": tot_food,
        "total_expense": tot_exp,
        "balance": tot_uang - tot_exp,
        "period_start": start_date,
        "period_end": end_date,
        "activity_id": act_id
    }
    return success_response(summary)

async def list_published_reports(request):
    # FR-34: Publik hanya melihat laporan yang disetujui/dipublikasikan
    reports = db.fetch_all("""
        SELECT r.*, a.title as activity_title, u.name as approver_name
        FROM published_reports r
        LEFT JOIN activities a ON r.activity_id = a.id
        LEFT JOIN users u ON r.approved_by = u.id
        WHERE r.is_published = 1
        ORDER BY r.published_at DESC
    """)
    for r in reports:
        if isinstance(r.get("summary_json"), str):
            try: r["summary_json"] = json.loads(r["summary_json"])
            except: pass
    return success_response(reports)

async def list_all_reports_admin(request):
    user, err = require_auth(request, ["admin", "takmir"])
    if err: return err
    reports = db.fetch_all("""
        SELECT r.*, a.title as activity_title, u.name as approver_name
        FROM published_reports r
        LEFT JOIN activities a ON r.activity_id = a.id
        LEFT JOIN users u ON r.approved_by = u.id
        ORDER BY r.created_at DESC
    """)
    for r in reports:
        if isinstance(r.get("summary_json"), str):
            try: r["summary_json"] = json.loads(r["summary_json"])
            except: pass
    return success_response(reports)

async def publish_report(request):
    # FR-34: Hanya Takmir yang dapat menyetujui & mempublikasikan laporan
    user, err = require_auth(request, ["takmir"])
    if err: return err
    body = await request.json()
    
    title = body.get("title", "").strip()
    rtype = body.get("report_type", "periode")
    p_start = body.get("period_start") or None
    p_end = body.get("period_end") or None
    act_id = body.get("activity_id") or None
    summary_data = body.get("summary_json") or {}
    
    if not title:
        return error_response("Judul publikasi laporan wajib diisi.")
        
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    summary_str = json.dumps(summary_data)
    
    new_id = db.execute("""
        INSERT INTO published_reports (report_type, title, period_start, period_end, activity_id, summary_json, is_published, approved_by, published_at)
        VALUES (%s, %s, %s, %s, %s, %s, 1, %s, %s)
    """, (rtype, title, p_start, p_end, act_id, summary_str, user["id"], now))
    
    log_audit(user["id"], "PUBLISH_REPORT", "published_reports", new_id, f"Mempublikasikan laporan: {title}")
    return success_response({"id": new_id}, "Laporan berhasil dipublikasikan untuk jamaah & publik.", 201)

async def unpublish_report(request):
    user, err = require_auth(request, ["takmir"])
    if err: return err
    report_id = int(request.path_params["id"])
    
    db.execute("UPDATE published_reports SET is_published = 0 WHERE id = %s", (report_id,))
    log_audit(user["id"], "UNPUBLISH_REPORT", "published_reports", report_id, "Menarik kembali publikasi laporan")
    return success_response(None, "Publikasi laporan berhasil ditarik.")

# 9. Mosque Info Endpoints (FR-38 - FR-40)
async def get_mosque_info(request):
    info = db.fetch_one("SELECT * FROM mosque_info WHERE id = 1")
    if not info:
        info = {
            "name": "Masjid Al-Ikhlas",
            "address": "Semarang",
            "bank_name": "BSI",
            "bank_account": "7123456789",
            "bank_holder": "Masjid Al-Ikhlas"
        }
    return success_response(info)

async def update_mosque_info(request):
    user, err = require_auth(request, ["takmir"])
    if err: return err
    body = await request.json()
    
    name = body.get("name", "").strip()
    address = body.get("address", "").strip()
    desc = body.get("description", "").strip()
    bname = body.get("bank_name", "").strip()
    bacc = body.get("bank_account", "").strip()
    bholder = body.get("bank_holder", "").strip()
    donation_info = body.get("donation_info", "").strip()
    qris = body.get("qris_image", "").strip()
    wa = body.get("whatsapp_contact", "").strip()
    
    db.execute("""
        UPDATE mosque_info
        SET name = %s, address = %s, description = %s, bank_name = %s, bank_account = %s,
            bank_holder = %s, donation_info = %s, qris_image = %s, whatsapp_contact = %s
        WHERE id = 1
    """, (name, address, desc, bname, bacc, bholder, donation_info, qris, wa))
    
    log_audit(user["id"], "UPDATE_MOSQUE_INFO", "mosque_info", 1, "Memperbarui profil masjid & info donasi")
    return success_response(None, "Informasi masjid & cara berdonasi berhasil diperbarui.")

# 10. WhatsApp Share Helpers (FR-41, FR-42)
async def get_whatsapp_activity_text(request):
    act_id = int(request.path_params["id"])
    act = db.fetch_one("SELECT * FROM activities WHERE id = %s", (act_id,))
    if not act:
        return error_response("Kegiatan tidak ditemukan.", 404)
    info = db.fetch_one("SELECT name FROM mosque_info WHERE id = 1")
    mname = info["name"] if info else "Masjid Al-Ikhlas"
    
    pj = act['pj_name'] if act['pj_name'] else '(Belum Ditentukan)'
    text = (
        f"🕌 *{mname}*\n"
        f"📢 *Jadwal Kegiatan: {act['title']}*\n"
        f"🗓 Tanggal: {act['activity_date']}\n"
        f"⏰ Waktu: {act['activity_time']}\n"
        f"📍 Lokasi: {act['location']}\n"
        f"👤 Penanggung Jawab (PJ): {pj}\n"
    )
    if act.get('notes'):
        text += f"📝 Keterangan: {act['notes']}\n"
    text += "\n_Mari bersama-sama meramaikan dan mendukung kegiatan masjid kita._"
    
    return success_response({"share_text": text})

async def get_whatsapp_report_text(request):
    rep_id = int(request.path_params["id"])
    rep = db.fetch_one("SELECT * FROM published_reports WHERE id = %s", (rep_id,))
    if not rep:
        return error_response("Laporan tidak ditemukan.", 404)
    info = db.fetch_one("SELECT name FROM mosque_info WHERE id = 1")
    mname = info["name"] if info else "Masjid Al-Ikhlas"
    
    summary = rep.get("summary_json") or {}
    if isinstance(summary, str):
        try: summary = json.loads(summary)
        except: summary = {}
        
    text = (
        f"🕌 *LAPORAN KEUANGAN {mname.upper()}*\n"
        f"📊 *{rep['title']}*\n"
        f"📅 Periode: {rep.get('period_start') or '-'} s.d. {rep.get('period_end') or '-'}\n"
        f"────────────────────────\n"
        f"💰 Donasi Uang: Rp {summary.get('total_money_donation', 0):,.0f}\n"
        f"📦 Nilai Barang & Jasa: Rp {summary.get('total_goods_services_value', 0):,.0f}\n"
        f"🍱 Makanan: {summary.get('total_food_portions', 0)} Porsi\n"
        f"💸 Total Pengeluaran: Rp {summary.get('total_expense', 0):,.0f}\n"
        f"📈 Saldo / Selisih: Rp {summary.get('balance', 0):,.0f}\n"
        f"────────────────────────\n"
        f"_Jazakumullahu khairan katsiran kepada seluruh donatur dan jamaah._"
    )
    return success_response({"share_text": text})

# 11. Audit Logs (FR-15, FR-16, FR-21, 8.2)
async def list_audit_logs(request):
    user, err = require_auth(request, ["takmir"])
    if err: return err
    logs = db.fetch_all("""
        SELECT l.*, u.name as user_name, u.role as user_role
        FROM audit_logs l
        LEFT JOIN users u ON l.user_id = u.id
        ORDER BY l.created_at DESC
        LIMIT 100
    """)
    return success_response(logs)

# =====================================================================
# ROUTES CONFIGURATION
# =====================================================================

routes = [
    Route("/api/health", health, methods=["GET"]),
    
    # Auth
    Route("/api/auth/login", login, methods=["POST"]),
    Route("/api/auth/register", register, methods=["POST"]),
    Route("/api/auth/me", get_me, methods=["GET"]),
    Route("/api/users", list_users, methods=["GET"]),
    Route("/api/users", create_user, methods=["POST"]),
    Route("/api/users/{id:int}/toggle-active", toggle_user_active, methods=["PUT"]),
    Route("/api/users/{id:int}/reset-password", reset_user_password, methods=["PUT"]),
    
    # Activities
    Route("/api/activities", list_activities, methods=["GET"]),
    Route("/api/activities", create_activity, methods=["POST"]),
    Route("/api/activities/{id:int}", get_activity, methods=["GET"]),
    Route("/api/activities/{id:int}", update_activity, methods=["PUT"]),
    Route("/api/activities/{id:int}/cancel", cancel_activity, methods=["POST"]),
    Route("/api/activities/{id:int}/copy", copy_activity, methods=["POST"]),
    
    # Donations
    Route("/api/donations", list_donations, methods=["GET"]),
    Route("/api/donations", create_donation, methods=["POST"]),
    Route("/api/donations/{id:int}/cancel", cancel_donation, methods=["POST"]),
    
    # Expenses
    Route("/api/expenses", list_expenses, methods=["GET"]),
    Route("/api/expenses", create_expense, methods=["POST"]),
    Route("/api/expenses/{id:int}/cancel", cancel_expense, methods=["POST"]),
    
    # Cash & Deficit
    Route("/api/cash/summary", get_cash_summary, methods=["GET"]),
    Route("/api/cash/transactions", list_cash_transactions, methods=["GET"]),
    Route("/api/cash/transaction", record_cash_transaction, methods=["POST"]),
    
    # Donation Confirmations
    Route("/api/confirmations", submit_confirmation, methods=["POST"]),
    Route("/api/confirmations/check/{ref_code:str}", check_confirmation, methods=["GET"]),
    Route("/api/confirmations", list_confirmations, methods=["GET"]),
    Route("/api/confirmations/{id:int}/approve", approve_confirmation, methods=["POST"]),
    Route("/api/confirmations/{id:int}/reject", reject_confirmation, methods=["POST"]),
    
    # Reports & Publications
    Route("/api/reports/summary", generate_report_summary, methods=["GET"]),
    Route("/api/reports/published", list_published_reports, methods=["GET"]),
    Route("/api/reports/admin", list_all_reports_admin, methods=["GET"]),
    Route("/api/reports/publish", publish_report, methods=["POST"]),
    Route("/api/reports/{id:int}/unpublish", unpublish_report, methods=["POST"]),
    
    # Mosque Profile
    Route("/api/mosque", get_mosque_info, methods=["GET"]),
    Route("/api/mosque", update_mosque_info, methods=["PUT"]),
    
    # WhatsApp Text
    Route("/api/whatsapp/activity/{id:int}", get_whatsapp_activity_text, methods=["GET"]),
    Route("/api/whatsapp/report/{id:int}", get_whatsapp_report_text, methods=["GET"]),
    
    # Audit Logs
    Route("/api/audit-logs", list_audit_logs, methods=["GET"]),
]

middleware = [
    Middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_methods=["*"],
        allow_headers=["*"],
        allow_credentials=True
    )
]

app = Starlette(debug=True, routes=routes, middleware=middleware)
