import os
import sqlite3
import json
from app.config import (
    DB_TYPE, DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME,
    SQLITE_PATH, PASSWORD_SALT
)

# Coba import PyMySQL jika tersedia
try:
    import pymysql
    import pymysql.cursors
    PYMYSQL_AVAILABLE = True
except ImportError:
    PYMYSQL_AVAILABLE = False


class Database:
    def __init__(self):
        self.is_mysql = False
        self.conn = None
        self._check_connection()

    def _check_connection(self):
        if PYMYSQL_AVAILABLE and DB_TYPE == "mysql":
            try:
                # Coba koneksi ke MySQL server
                conn = pymysql.connect(
                    host=DB_HOST,
                    port=DB_PORT,
                    user=DB_USER,
                    password=DB_PASSWORD,
                    charset='utf8mb4',
                    cursorclass=pymysql.cursors.DictCursor,
                    autocommit=True
                )
                with conn.cursor() as cursor:
                    cursor.execute(f"CREATE DATABASE IF NOT EXISTS `{DB_NAME}` CHARACTER SET utf8mb4;")
                conn.select_db(DB_NAME)
                conn.close()
                self.is_mysql = True
                print(f"[Database] Terhubung ke MySQL Server di {DB_HOST}:{DB_PORT} (Database: {DB_NAME})")
                return
            except Exception as e:
                print(f"[Database] Gagal terhubung ke MySQL ({e}). Beralih otomatis ke SQLite lokal agar sistem tetap berjalan.")
        else:
            print("[Database] Menggunakan SQLite lokal (PyMySQL belum terpasang atau DB_TYPE=sqlite).")
        
        self.is_mysql = False

    def get_connection(self):
        if self.is_mysql:
            return pymysql.connect(
                host=DB_HOST,
                port=DB_PORT,
                user=DB_USER,
                password=DB_PASSWORD,
                database=DB_NAME,
                charset='utf8mb4',
                cursorclass=pymysql.cursors.DictCursor,
                autocommit=True
            )
        else:
            conn = sqlite3.connect(SQLITE_PATH)
            conn.row_factory = sqlite3.Row
            return conn

    def _prepare_query(self, query: str) -> str:
        if not self.is_mysql:
            # Ganti placeholder %s dengan ? untuk SQLite
            return query.replace("%s", "?")
        return query

    def fetch_all(self, query: str, params: tuple = ()):
        conn = self.get_connection()
        query = self._prepare_query(query)
        try:
            if self.is_mysql:
                with conn.cursor() as cursor:
                    cursor.execute(query, params)
                    return cursor.fetchall()
            else:
                cursor = conn.cursor()
                cursor.execute(query, params)
                rows = cursor.fetchall()
                return [dict(r) for r in rows]
        finally:
            conn.close()

    def fetch_one(self, query: str, params: tuple = ()):
        conn = self.get_connection()
        query = self._prepare_query(query)
        try:
            if self.is_mysql:
                with conn.cursor() as cursor:
                    cursor.execute(query, params)
                    return cursor.fetchone()
            else:
                cursor = conn.cursor()
                cursor.execute(query, params)
                row = cursor.fetchone()
                return dict(row) if row else None
        finally:
            conn.close()

    def execute(self, query: str, params: tuple = ()):
        conn = self.get_connection()
        query = self._prepare_query(query)
        try:
            if self.is_mysql:
                with conn.cursor() as cursor:
                    cursor.execute(query, params)
                    return cursor.lastrowid
            else:
                cursor = conn.cursor()
                cursor.execute(query, params)
                conn.commit()
                return cursor.lastrowid
        finally:
            conn.close()

    def _clean_sql(self, sql_content: str):
        lines = []
        for line in sql_content.splitlines():
            s = line.strip()
            if s.startswith("--") or s.startswith("/*"):
                continue
            lines.append(line)
        cleaned = "\n".join(lines)
        statements = []
        for stmt in cleaned.split(";"):
            s = stmt.strip()
            if s and not s.lower().startswith("create database") and not s.lower().startswith("use "):
                statements.append(s)
        return statements

    def init_tables(self):
        """Inisialisasi tabel jika belum ada."""
        if self.is_mysql:
            schema_file = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "database", "schema.sql")
            seed_file = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "database", "seed.sql")
            if os.path.exists(schema_file):
                conn = self.get_connection()
                try:
                    with conn.cursor() as cursor:
                        with open(schema_file, "r", encoding="utf-8") as f:
                            statements = self._clean_sql(f.read())
                            for stmt in statements:
                                cursor.execute(stmt)
                    print("[Database] Schema MySQL berhasil diverifikasi/dimuat.")
                    # Cek jika belum ada user
                    res = self.fetch_one("SELECT COUNT(*) as cnt FROM users")
                    if res and res["cnt"] == 0 and os.path.exists(seed_file):
                        with conn.cursor() as cursor:
                            with open(seed_file, "r", encoding="utf-8") as f:
                                for stmt in self._clean_sql(f.read()):
                                    cursor.execute(stmt)
                        print("[Database] Data awal (Seed) MySQL berhasil dimasukkan.")
                except Exception as e:
                    print(f"[Database] Error inisialisasi tabel MySQL: {e}")
                finally:
                    conn.close()
        else:
            # Inisialisasi skema di SQLite
            conn = sqlite3.connect(SQLITE_PATH)
            cursor = conn.cursor()
            cursor.executescript("""
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                email TEXT NOT NULL UNIQUE,
                password_hash TEXT NOT NULL,
                role TEXT NOT NULL DEFAULT 'admin',
                is_active INTEGER NOT NULL DEFAULT 1,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS activities (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                type TEXT NOT NULL,
                activity_date TEXT NOT NULL,
                activity_time TEXT NOT NULL,
                location TEXT NOT NULL DEFAULT 'Masjid Al-Ikhlas',
                pj_name TEXT,
                notes TEXT,
                status TEXT NOT NULL DEFAULT 'terjadwal',
                cancel_reason TEXT,
                created_by INTEGER NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS donation_confirmations (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                reference_code TEXT NOT NULL UNIQUE,
                activity_id INTEGER,
                donor_name TEXT,
                contact TEXT,
                amount REAL NOT NULL,
                donation_date TEXT NOT NULL,
                proof_photo TEXT,
                status TEXT NOT NULL DEFAULT 'menunggu',
                reject_reason TEXT,
                reviewed_by INTEGER,
                reviewed_at TIMESTAMP,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS donations (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                activity_id INTEGER,
                confirmation_id INTEGER,
                donation_date TEXT NOT NULL,
                type TEXT NOT NULL,
                donor_name TEXT,
                description TEXT,
                value_amount REAL NOT NULL DEFAULT 0.0,
                portions INTEGER,
                payment_method TEXT,
                status TEXT NOT NULL DEFAULT 'terverifikasi',
                cancel_reason TEXT,
                created_by INTEGER NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS expenses (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                activity_id INTEGER NOT NULL,
                expense_date TEXT NOT NULL,
                category TEXT NOT NULL,
                description TEXT NOT NULL,
                amount REAL NOT NULL,
                proof_photo TEXT,
                status TEXT NOT NULL DEFAULT 'sah',
                cancel_reason TEXT,
                created_by INTEGER NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS cash_transactions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                activity_id INTEGER,
                transaction_date TEXT NOT NULL,
                direction TEXT NOT NULL,
                amount REAL NOT NULL,
                note TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'sah',
                cancel_reason TEXT,
                created_by INTEGER NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS published_reports (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                report_type TEXT NOT NULL,
                title TEXT NOT NULL,
                period_start TEXT,
                period_end TEXT,
                activity_id INTEGER,
                summary_json TEXT,
                is_published INTEGER NOT NULL DEFAULT 0,
                approved_by INTEGER,
                published_at TIMESTAMP,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS mosque_info (
                id INTEGER PRIMARY KEY DEFAULT 1,
                name TEXT NOT NULL,
                address TEXT NOT NULL,
                description TEXT,
                bank_name TEXT NOT NULL,
                bank_account TEXT NOT NULL,
                bank_holder TEXT NOT NULL,
                qris_image TEXT,
                donation_info TEXT,
                whatsapp_contact TEXT,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS audit_logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER,
                action TEXT NOT NULL,
                entity TEXT NOT NULL,
                entity_id INTEGER NOT NULL,
                reason TEXT,
                details TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            """)

            # Seed default data jika users masih kosong
            cursor.execute("SELECT COUNT(*) FROM users")
            if cursor.fetchone()[0] == 0:
                # takmir123 -> 1d12200fccbb8fe63e5a51de63d5abdf2feb47d8da209fb913d44b114aa4c229
                # marbot123 -> 4db95cf836e6b75dd0357821517bfe15574314f31c4f9a47ed9943ead9bb91fc
                cursor.execute("""
                INSERT INTO users (id, name, email, password_hash, role, is_active) VALUES
                (1, 'Bapak Abdul (Takmir)', 'takmir@alikhlas.id', '1d12200fccbb8fe63e5a51de63d5abdf2feb47d8da209fb913d44b114aa4c229', 'takmir', 1),
                (2, 'Mas Risqon (Marbot / Admin)', 'marbot@alikhlas.id', '4db95cf836e6b75dd0357821517bfe15574314f31c4f9a47ed9943ead9bb91fc', 'admin', 1)
                """)

                cursor.execute("""
                INSERT INTO mosque_info (id, name, address, description, bank_name, bank_account, bank_holder, qris_image, donation_info, whatsapp_contact) VALUES
                (1, 'Masjid Al-Ikhlas', 'Jl. Al-Ikhlas No. 12, Semarang, Jawa Tengah', 'Pusat ibadah, kegiatan dakwah, kajian, dan santunan umat di lingkungan Al-Ikhlas.', 'Bank Syariah Indonesia (BSI)', '7123456789', 'Masjid Al-Ikhlas Semarang', '', 'Salurkan donasi terbaik Anda melalui rekening resmi di atas atau scan QRIS statis di papan masjid. Setelah transfer, mohon kirim bukti konfirmasi melalui menu Konfirmasi Donasi agar segera dicatat oleh tim marbot.', '6281234567890')
                """)

                cursor.execute("""
                INSERT INTO activities (id, title, type, activity_date, activity_time, location, pj_name, notes, status, created_by) VALUES
                (1, 'Jumat Berkah Berbagi Makanan', 'Jumat Berkah', '2026-11-28', '11:30 - 13:00 WIB', 'Serambi Masjid Al-Ikhlas', 'Mas Risqon', 'Target 150 porsi nasi bungkus untuk jamaah shalat Jumat.', 'terjadwal', 2),
                (2, 'Pengajian Rutin Malam Ahad', 'Pengajian', '2026-11-29', '19:30 - 21:00 WIB', 'Ruang Utama Masjid Al-Ikhlas', 'Pak Hadi', 'Kajian tafsir Al-Quran bersama Ustadz Al-Hafidz.', 'terjadwal', 1),
                (3, 'Kajian Muslimah & Doa Bersama', 'Pengajian', '2026-12-05', '08:30 - 10:30 WIB', 'Aula Al-Ikhlas', NULL, 'Perlu penunjukan PJ segera sebelum acara dimulai.', 'terjadwal', 1)
                """)

                cursor.execute("""
                INSERT INTO cash_transactions (id, activity_id, transaction_date, direction, amount, note, status, created_by) VALUES
                (1, NULL, '2026-11-01', 'masuk', 5000000.0, 'Saldo awal kas kas masjid bulan November 2026', 'sah', 1)
                """)

                cursor.execute("""
                INSERT INTO donations (id, activity_id, confirmation_id, donation_date, type, donor_name, description, value_amount, portions, payment_method, status, created_by) VALUES
                (1, 1, NULL, '2026-11-20', 'uang', 'Hamba Allah (Tembalang)', 'Infaq Jumat Berkah via transfer BSI', 500000.0, NULL, 'transfer', 'terverifikasi', 2),
                (2, 1, NULL, '2026-11-20', 'makanan', 'Ibu Hj. Aminah', 'Donasi nasi kotak ayam bakar', 0.0, 50, NULL, 'terverifikasi', 2),
                (3, 2, NULL, '2026-11-21', 'uang', 'Bapak Suryono', 'Infaq pengajian tunai', 300000.0, NULL, 'tunai', 'terverifikasi', 2),
                (4, NULL, NULL, '2026-11-15', 'barang', 'Bapak Heru', 'Donasi sajadah panjang 2 gulung', 1200000.0, NULL, NULL, 'terverifikasi', 1),
                (5, NULL, NULL, '2026-11-16', 'jasa', 'Mas Dimas (Teknisi)', 'Jasa perbaikan sound system dan kabel mic masjid', 350000.0, NULL, NULL, 'terverifikasi', 2)
                """)

                cursor.execute("""
                INSERT INTO expenses (id, activity_id, expense_date, category, description, amount, proof_photo, status, created_by) VALUES
                (1, 1, '2026-11-21', 'Konsumsi', 'Pembelian air mineral gelas 5 dus dan buah pisang', 220000.0, '', 'sah', 2)
                """)

                cursor.execute("""
                INSERT INTO donation_confirmations (id, reference_code, activity_id, donor_name, contact, amount, donation_date, proof_photo, status, reject_reason, reviewed_by, reviewed_at) VALUES
                (1, 'DON-20261121-0001', 1, 'Keluarga Budi Santoso (Tembalang)', '081298765432', 250000.0, '2026-11-21', '', 'menunggu', NULL, NULL, NULL)
                """)

                cursor.execute("""
                INSERT INTO published_reports (id, report_type, title, period_start, period_end, activity_id, summary_json, is_published, approved_by, published_at) VALUES
                (1, 'kegiatan', 'Laporan Jumat Berkah Pekan Ini', '2026-11-20', '2026-11-28', 1, '{"total_money_donation": 500000.0, "total_goods_services": 0.0, "total_food_portions": 50, "total_expense": 220000.0, "balance": 280000.0, "cash_subsidy": 0.0}', 1, 1, '2026-11-21 12:00:00')
                """)

                conn.commit()
                print("[Database] Seed data SQLite berhasil dimuat.")

            conn.close()

db = Database()
