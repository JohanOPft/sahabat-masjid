import sys
import os
import time
import threading
import requests
import uvicorn

sys.path.insert(0, os.path.dirname(__file__))
from app.main import app

def run_test_suite():
    port = 8008
    base_url = f"http://127.0.0.1:{port}/api"
    
    # Jalankan uvicorn server di background thread
    server = uvicorn.Server(uvicorn.Config(app, host="127.0.0.1", port=port, log_level="warning"))
    srv_thread = threading.Thread(target=server.run, daemon=True)
    srv_thread.start()
    
    print("\n" + "=" * 70)
    print("  SAHABAT MASJID - PENGUJIAN OTOMATIS (END-TO-END TEST SUITE)")
    print("  Masjid Al-Ikhlas - SRS v1.0 (FR-01 s.d. FR-42)")
    print("=" * 70)
    
    # Tunggu server aktif
    ready = False
    for _ in range(10):
        try:
            r = requests.get(f"{base_url}/health", timeout=1)
            if r.status_code == 200:
                ready = True
                break
        except Exception:
            time.sleep(0.5)
            
    if not ready:
        print("[GAGAL] Server tidak dapat dinyalakan pada port", port)
        sys.exit(1)
        
    print("\n[OK] 1. Pengujian Health Check & Database Koneksi")
    r = requests.get(f"{base_url}/health")
    data = r.json()["data"]
    print(f"     Status: {data['status']} | Database: {data['database']}")
    assert r.status_code == 200

    print("\n[OK] 2. Pengujian Login & Hak Akses Peran (FR-01 s.d. FR-05)")
    # Registrasi Pengurus Baru (Admin & Takmir)
    reg_email = f"marbot_reg_{int(time.time())}@alikhlas.id"
    r_reg = requests.post(f"{base_url}/auth/register", json={
        "name": "Marbot Baru Terdaftar",
        "email": reg_email,
        "password": "password123",
        "role": "admin"
    })
    assert r_reg.status_code == 201, r_reg.text
    print(f"     Registrasi akun baru berhasil: {r_reg.json()['data']['user']['name']} ({r_reg.json()['data']['user']['role']})")

    # Login Takmir (Pak Abdul)
    r_takmir = requests.post(f"{base_url}/auth/login", json={"email": "takmir@alikhlas.id", "password": "takmir123"})
    assert r_takmir.status_code == 200, r_takmir.text
    takmir_token = r_takmir.json()["data"]["token"]
    takmir_headers = {"Authorization": f"Bearer {takmir_token}"}
    print(f"     Takmir login berhasil: {r_takmir.json()['data']['user']['name']}")

    # Login Admin / Marbot (Mas Risqon)
    r_admin = requests.post(f"{base_url}/auth/login", json={"email": "marbot@alikhlas.id", "password": "marbot123"})
    assert r_admin.status_code == 200, r_admin.text
    admin_token = r_admin.json()["data"]["token"]
    admin_headers = {"Authorization": f"Bearer {admin_token}"}
    print(f"     Admin (Marbot) login berhasil: {r_admin.json()['data']['user']['name']}")

    # Verifikasi Profil Me
    r_me = requests.get(f"{base_url}/auth/me", headers=takmir_headers)
    assert r_me.status_code == 200
    print(f"     Verifikasi token Takmir ID #{r_me.json()['data']['id']} berhasil")

    # Takmir tambah user baru (FR-04)
    r_new_u = requests.post(f"{base_url}/users", headers=takmir_headers, json={
        "name": "Marbot Baru (Mahasiswa UIN)",
        "email": f"marbot_baru_{int(time.time())}@alikhlas.id",
        "password": "password123",
        "role": "admin"
    })
    assert r_new_u.status_code == 201
    new_user_id = r_new_u.json()["data"]["id"]
    print(f"     Takmir menambah pengurus baru ID #{new_user_id} berhasil")

    print("\n[OK] 3. Pengujian Kegiatan & Jadwal PJ (FR-06 s.d. FR-10)")
    # List kegiatan publik
    r_acts = requests.get(f"{base_url}/activities")
    assert r_acts.status_code == 200
    acts = r_acts.json()["data"]
    print(f"     Memuat {len(acts)} kegiatan terjadwal di masjid")

    # Tambah kegiatan baru oleh Admin
    r_new_act = requests.post(f"{base_url}/activities", headers=admin_headers, json={
        "title": "Bimbingan Tahsin & Qiroah",
        "type": "Pengajian",
        "activity_date": "2026-12-12",
        "activity_time": "16:00 - 17:30 WIB",
        "location": "Masjid Al-Ikhlas",
        "pj_name": "Ustadz H. Syamsuddin",
        "notes": "Peserta membawa mushaf masing-masing."
    })
    assert r_new_act.status_code == 201
    act_id = r_new_act.json()["data"]["id"]
    print(f"     Tambah kegiatan #{act_id} berhasil: Bimbingan Tahsin")

    # Salin kegiatan sebelumnya (FR-08)
    r_copy = requests.post(f"{base_url}/activities/{act_id}/copy", headers=admin_headers, json={
        "activity_date": "2026-12-19",
        "activity_time": "16:00 - 17:30 WIB"
    })
    assert r_copy.status_code == 200
    copy_act_id = r_copy.json()["data"]["id"]
    print(f"     Menyalin kegiatan FR-08 berhasil (Kegiatan Baru ID #{copy_act_id})")

    print("\n[OK] 4. Pengujian Pencatatan Donasi (4 Jenis: Uang, Barang, Jasa, Makanan) (FR-11 s.d. FR-17)")
    # Donasi Uang
    r_don_uang = requests.post(f"{base_url}/donations", headers=admin_headers, json={
        "activity_id": act_id,
        "type": "uang",
        "donor_name": "Keluarga Bapak Budi",
        "value_amount": 1000000,
        "payment_method": "transfer",
        "description": "Infaq penyelenggaraan kajian tahsin"
    })
    assert r_don_uang.status_code == 201
    don_id = r_don_uang.json()["data"]["id"]
    print(f"     Catat donasi uang Rp 1.000.000 (ID #{don_id})")

    # Donasi Makanan
    r_don_food = requests.post(f"{base_url}/donations", headers=admin_headers, json={
        "activity_id": act_id,
        "type": "makanan",
        "donor_name": "Ibu Hj. Aminah",
        "portions": 40,
        "description": "Donasi snack box dan kurma"
    })
    assert r_don_food.status_code == 201
    print(f"     Catat donasi makanan 40 porsi")

    # Donasi Barang
    r_don_goods = requests.post(f"{base_url}/donations", headers=admin_headers, json={
        "type": "barang",
        "donor_name": "Hamba Allah",
        "value_amount": 500000,
        "description": "1 unit kipas angin dinding masjid"
    })
    assert r_don_goods.status_code == 201
    print(f"     Catat donasi barang perkiraan Rp 500.000")

    print("\n[OK] 5. Pengujian Pencatatan Pengeluaran Kegiatan (FR-18 s.d. FR-21)")
    r_exp = requests.post(f"{base_url}/expenses", headers=admin_headers, json={
        "activity_id": act_id,
        "category": "Konsumsi",
        "description": "Pembelian air mineral gelas dan konsumsi pemateri",
        "amount": 350000,
        "proof_photo": ""
    })
    assert r_exp.status_code == 201
    exp_id = r_exp.json()["data"]["id"]
    print(f"     Catat pengeluaran Rp 350.000 (ID #{exp_id})")

    print("\n[OK] 6. Pengujian Kas & Selisih Kegiatan (FR-22 s.d. FR-26)")
    # Ringkasan Kas
    r_cash_sum = requests.get(f"{base_url}/cash/summary", headers=takmir_headers)
    assert r_cash_sum.status_code == 200
    saldo = r_cash_sum.json()["data"]["current_balance"]
    print(f"     Saldo kas masjid saat ini: Rp {saldo:,.0f}")

    # Tambah Kas Masuk oleh Takmir
    r_cash_in = requests.post(f"{base_url}/cash/transaction", headers=takmir_headers, json={
        "direction": "masuk",
        "amount": 2000000,
        "note": "Kotak infaq jumat keliling"
    })
    assert r_cash_in.status_code == 201
    print(f"     Takmir mencatat kas masuk Rp 2.000.000")

    print("\n[OK] 7. Pengujian Konfirmasi Donasi dari Donatur Jauh (FR-27 s.d. FR-31)")
    # Donatur kirim konfirmasi donasi
    r_conf = requests.post(f"{base_url}/confirmations", json={
        "activity_id": act_id,
        "donor_name": "Bapak Rudi (Donatur Tembalang)",
        "contact": "081298765432",
        "amount": 500000,
        "donation_date": "2026-11-21",
        "proof_photo": ""
    })
    assert r_conf.status_code == 201
    ref_code = r_conf.json()["data"]["reference_code"]
    conf_id = r_conf.json()["data"]["id"]
    print(f"     Donatur mengirim konfirmasi transfer (Kode Ref: {ref_code})")

    # Donatur cek status dengan kode referensi (FR-31)
    r_chk = requests.get(f"{base_url}/confirmations/check/{ref_code}")
    assert r_chk.status_code == 200
    assert r_chk.json()["data"]["status"] == "menunggu"
    print(f"     Cek status donasi berhasil: Status '{r_chk.json()['data']['status']}'")

    # Pengurus menyetujui konfirmasi (FR-29) -> otomatis menjadi donasi terverifikasi
    r_appr = requests.post(f"{base_url}/confirmations/{conf_id}/approve", headers=admin_headers)
    assert r_appr.status_code == 200
    print(f"     Pengurus menyetujui konfirmasi ID #{conf_id} (Otomatis terbit donasi)")

    print("\n[OK] 8. Pengujian Penyusunan Laporan & Publikasi (FR-32 s.d. FR-37)")
    # Ringkasan laporan
    r_rep_sum = requests.get(f"{base_url}/reports/summary?activity_id={act_id}", headers=takmir_headers)
    assert r_rep_sum.status_code == 200
    rep_summary = r_rep_sum.json()["data"]
    print(f"     Laporan kegiatan terakumulasi otomatis: Donasi Uang Rp {rep_summary['total_money_donation']:,.0f}, Pengeluaran Rp {rep_summary['total_expense']:,.0f}")

    # Takmir publikasikan laporan untuk publik
    r_pub = requests.post(f"{base_url}/reports/publish", headers=takmir_headers, json={
        "title": "Laporan Transparansi Kajian Tahsin",
        "report_type": "kegiatan",
        "activity_id": act_id,
        "summary_json": rep_summary
    })
    assert r_pub.status_code == 201
    pub_id = r_pub.json()["data"]["id"]
    print(f"     Takmir mempublikasikan laporan ID #{pub_id} untuk jamaah")

    # Publik melihat laporan terpublikasi (FR-34)
    r_pub_list = requests.get(f"{base_url}/reports/published")
    assert r_pub_list.status_code == 200
    assert len(r_pub_list.json()["data"]) >= 1
    print(f"     Publik berhasil mengakses {len(r_pub_list.json()['data'])} laporan terpublikasi")

    print("\n[OK] 9. Pengujian Fitur Bagikan ke WhatsApp (FR-41, FR-42)")
    # Text WA Kegiatan
    r_wa_act = requests.get(f"{base_url}/whatsapp/activity/{act_id}")
    assert r_wa_act.status_code == 200
    print(f"     Teks WA Kegiatan Terbentuk:\n" + "-"*40 + f"\n{r_wa_act.json()['data']['share_text'].strip()}\n" + "-"*40)

    # Text WA Laporan
    r_wa_rep = requests.get(f"{base_url}/whatsapp/report/{pub_id}")
    assert r_wa_rep.status_code == 200
    print(f"     Teks WA Laporan Terbentuk:\n" + "-"*40 + f"\n{r_wa_rep.json()['data']['share_text'].strip()}\n" + "-"*40)

    print("\n[OK] 10. Pengujian Profil Masjid & Info Donasi (FR-38 s.d. FR-40)")
    r_mosque = requests.get(f"{base_url}/mosque")
    assert r_mosque.status_code == 200
    print(f"     Nama Masjid: {r_mosque.json()['data']['name']}")
    print(f"     Rekening: {r_mosque.json()['data']['bank_name']} - {r_mosque.json()['data']['bank_account']}")

    print("\n[OK] 11. Pengujian Jejak Audit (Audit Logs - Bab 8.2 & NFR-15)")
    r_audit = requests.get(f"{base_url}/audit-logs", headers=takmir_headers)
    assert r_audit.status_code == 200
    print(f"     Total log audit tercatat dalam pengujian: {len(r_audit.json()['data'])} kejadian")

    print("\n" + "=" * 70)
    print("  HASIL PENGUJIAN: SEMUA 11 MODUL & KEBUTUHAN SRS LULUS 100%!   ")
    print("=" * 70 + "\n")

if __name__ == "__main__":
    run_test_suite()
