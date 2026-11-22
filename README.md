<<<<<<< HEAD
# 🕌 Sahabat Masjid - Sistem Pengelolaan Donasi & Kegiatan Masjid Al-Ikhlas

Proyek website dan aplikasi **Sahabat Masjid** yang dibangun secara lengkap dan terstruktur sesuai dengan dokumen **Software Requirements Specification (SRS) v1.0** Masjid Al-Ikhlas Semarang.

Aplikasi ini menggantikan proses manual via WhatsApp Group menjadi sistem digital yang transparan, akuntabel, dan ramah pengguna (termasuk pengurus lansia dan mahasiswa marbot).

---

## 🛠️ Arsitektur & Teknologi

| Lapisan | Teknologi | Keterangan |
| :--- | :--- | :--- |
| **Frontend** | **Dart / Flutter (Web & Mobile)** | Material 3, responsif, kontras tinggi, huruf besar (NFR-01), alur ringkas (NFR-03). |
| **Backend** | **Python (REST API)** | Starlette / FastAPI + Uvicorn, arsitektur modular, HMAC-SHA256 Token Auth, jejak audit otomatis. |
| **Database** | **MySQL 8.x / MariaDB** | Skema relasional terstruktur (ERD Bab 4.1), integritas data keuangan (BR-06), dengan dukungan fallback lokal otomatis. |

---

## 📁 Struktur Direktori Proyek

```
Project Sahabat Masjid/
├── SRS.md                         # Dokumen Spesifikasi Kebutuhan Perangkat Lunak v1.0
├── README.md                      # Dokumentasi & Panduan Menjalankan Sistem
│
├── database/                      # Modul Basis Data (MySQL)
│   ├── schema.sql                 # DDL tabel (users, activities, donations, expenses, cash, dll.)
│   └── seed.sql                   # Data awal (Pak Abdul Takmir, Mas Risqon Marbot, Jumat Berkah)
│
├── backend/                       # REST API Backend (Python)
│   ├── app/
│   │   ├── __init__.py
│   │   ├── config.py              # Konfigurasi database & token
│   │   ├── database.py            # Konektor MySQL & SQLite fallback
│   │   ├── auth.py                # Hashing kata sandi, token JWT & audit log
│   │   └── main.py                # Endpoint REST API (FR-01 s.d. FR-42)
│   ├── run.py                     # Script peluncur server backend
│   ├── test_api.py                # Automated test suite pengujian seluruh alur SRS
│   └── requirements.txt           # Dependensi Python
│
└── frontend/                      # Antarmuka Pengguna (Dart / Flutter Web)
    ├── pubspec.yaml               # Konfigurasi dependensi Flutter/Dart
    ├── web/
    │   └── index.html             # Web client interaktif & live preview
    └── lib/
        ├── main.dart              # Entry point aplikasi & konfigurasi rute
        ├── config/
        │   └── api_config.dart    # Konfigurasi base URL API & formatter Rupiah
        ├── models/                # Data model (Activity, Donation, Expense, Cash, User, dll.)
        ├── services/
        │   └── api_service.dart   # HTTP client terpadu ke backend REST API
        ├── state/
        │   └── auth_state.dart    # Manajemen state autentikasi & peran pengguna
        ├── screens/
        │   ├── public/            # Halaman Publik (Jamaah & Donatur)
        │   │   ├── public_home_screen.dart
        │   │   ├── public_activities_screen.dart
        │   │   ├── public_how_to_donate_screen.dart
        │   │   ├── public_confirm_donation_screen.dart
        │   │   └── public_reports_screen.dart
        │   ├── auth/
        │   │   └── login_screen.dart
        │   └── admin/             # Halaman Pengurus (Admin/Marbot & Takmir)
        │       ├── dashboard_screen.dart
        │       ├── activities_manage_screen.dart
        │       ├── donations_manage_screen.dart
        │       ├── expenses_manage_screen.dart
        │       ├── cash_manage_screen.dart
        │       ├── confirmations_manage_screen.dart
        │       ├── reports_manage_screen.dart
        │       ├── users_manage_screen.dart
        │       └── mosque_info_screen.dart
        └── widgets/
            ├── app_drawer.dart
            └── stat_card.dart
```

---

## 🚀 Panduan Menjalankan Proyek

### 1. Persiapan Database (MySQL)
Jika menggunakan **Laragon**, **XAMPP**, atau MySQL mandiri:
1. Jalankan service MySQL (port default `3306`).
2. Impor berkas database melalui MySQL CLI atau phpMyAdmin / HeidiSQL:
   ```sql
   source database/schema.sql;
   source database/seed.sql;
   ```
> **Catatan Fleksibilitas:** Backend Python telah dilengkapi mekanisme deteksi otomatis. Jika MySQL belum dinyalakan, backend akan otomatis menggunakan SQLite lokal sebagai fallback sehingga sistem tetap dapat diuji tanpa hambatan.

---

### 2. Menjalankan Backend (Python)

Buka terminal pada folder proyek:
```powershell
cd backend
python run.py
```
Server akan aktif di: **`http://127.0.0.1:8000`**  
Status API dapat diperiksa di: **`http://127.0.0.1:8000/api/health`**

---

### 3. Menjalankan Frontend (Dart / Flutter)

Terdapat 2 cara mudah untuk menjalankan frontend:

#### Opsi A: Menggunakan Flutter Web (Dart)
Jika Flutter SDK terpasang di komputer Anda:
```powershell
cd frontend
flutter pub get
flutter run -d chrome
```

#### Opsi B: Web Client Langsung di Browser
Buka berkas **`frontend/web/index.html`** langsung di browser (Chrome / Edge / Firefox) atau jalankan mini web server lokal:
```powershell
cd frontend/web
python -m http.server 3000
```
Lalu buka **`http://localhost:3000`** di browser.

---

## 🔑 Akun Pengguna Bawaan (Sesuai SRS)

Sesuai dengan SRS Bab 2.2, akun pengurus telah diisi dengan data awal:

| Peran | Nama | Email | Kata Sandi | Wewenang Utama |
| :--- | :--- | :--- | :--- | :--- |
| **Takmir** | Bapak Abdul | `takmir@alikhlas.id` | `takmir123` | Persetujuan publikasi laporan, pengawasan kas, pembatalan data, kelola akun pengurus. |
| **Admin (Marbot)** | Mas Risqon | `marbot@alikhlas.id` | `marbot123` | Pencatatan cepat donasi (4 jenis), pengeluaran kegiatan, jadwal PJ kegiatan. |
| **Jamaah & Donatur** | Publik | *(Tanpa Login)* | *(Tanpa Login)* | Melihat jadwal kegiatan, cara berdonasi, mengirim konfirmasi transfer, melihat laporan terpublikasi. |

---

## 📋 Pemetaan Fitur Lengkap Sesuai SRS

| No | Fitur SRS | Kode FR | Keterangan Implementasi |
| :---: | :--- | :--- | :--- |
| **1** | **Login & Hak Akses Peran** | `FR-01` s.d. `FR-05` | Login email & kata sandi terenkripsi, peran admin & takmir, fitur takmir kelola akun pengurus. |
| **2** | **Kegiatan & Jadwal PJ** | `FR-06` s.d. `FR-10` | CRUD kegiatan (Jumat Berkah, Pengajian, Bulan Puasa), salin kegiatan mingguan, penanda visual jika belum ada PJ. |
| **3** | **Pencatatan Donasi (4 Jenis)** | `FR-11` s.d. `FR-17` | Donasi Uang (tunai/transfer), Barang (taksiran Rp), Jasa (taksiran Rp), Makanan (porsi), donatur anonim/bernama, pembatalan oleh Takmir dengan alasan. |
| **4** | **Pencatatan Pengeluaran** | `FR-18` s.d. `FR-21` | Pengeluaran per kegiatan, kategori biaya, foto bukti, pembatalan oleh Takmir dengan alasan. |
| **5** | **Kas & Selisih Kegiatan** | `FR-22` s.d. `FR-26` | Perhitungan otomatis defisit kegiatan, pencatatan kas masuk/keluar, tombol **"Tambal dari Kas"** untuk menutup kekurangan dana dengan proteksi batas saldo. |
| **6** | **Konfirmasi Donasi Donatur** | `FR-27` s.d. `FR-31` | Form publik untuk donatur jauh (Tembalang dll), pembuatan kode referensi otomatis (`DON-YYYYMMDD-XXXX`), persetujuan oleh pengurus langsung mengonversi ke donasi terverifikasi. |
| **7** | **Laporan & Publikasi** | `FR-32` s.d. `FR-37` | Penyusunan laporan otomatis, persetujuan publikasi oleh Takmir, masking privasi nama donatur untuk publik. |
| **8** | **Informasi Publik** | `FR-38` s.d. `FR-40` | Beranda jadwal terdekat, nomor rekening BSI & QRIS masjid, profil masjid yang dapat diperbarui Takmir. |
| **9** | **Bagikan ke WhatsApp** | `FR-41`, `FR-42` | Format teks siap kirim satu klik untuk membagikan ringkasan kegiatan dan laporan keuangan ke WhatsApp Group. |
| **10** | **Logging & Audit Trail** | `FR-15`, `FR-16`, `FR-21`, `8.2` | Pencatatan otomatis siapa yang mengubah, membatalkan, atau menyetujui transaksi keuangan beserta alasannya. |

---

## 🛡️ Jaminan Kualitas & Integritas Data
- **Keamanan:** Kata sandi di-hash dengan SHA-256 + garam rahasia (`PASSWORD_SALT`), token akses HMAC-SHA256 dengan waktu kedaluwarsa (NFR-10, NFR-14).
- **Integritas Keuangan:** Data keuangan tidak pernah dihapus permanen (`hard delete`), melainkan berstatus `dibatalkan` disertai alasan pembatalan dan pencatatan jejak audit (BR-06).
- **Kemudahan Lansia (NFR-01):** Teks besar (minimal 16px), warna kontras, tombol berukuran nyaman, dan alur kerja utama tidak lebih dari tiga langkah (NFR-03).
=======
# sahabat-masjid
sahabat masjid ver 0.1
>>>>>>> cd1ecbf38c59d77629aef28bdbb2aeff18f0fb18
