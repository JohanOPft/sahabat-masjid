-- =====================================================================
-- Sahabat Masjid - Sample Seed Data
-- Sesuai Latar Belakang & Wawancara SRS v1.0 Masjid Al-Ikhlas
-- =====================================================================

USE `sahabat_masjid`;

-- 1. Pengurus: Takmir (Pak Abdul) & Admin / Marbot (Mas Risqon)
-- Password takmir123 & marbot123
INSERT INTO `users` (`id`, `name`, `email`, `password_hash`, `role`, `is_active`) VALUES
(1, 'Bapak Abdul (Takmir)', 'takmir@alikhlas.id', '1d12200fccbb8fe63e5a51de63d5abdf2feb47d8da209fb913d44b114aa4c229', 'takmir', 1),
(2, 'Mas Risqon (Marbot / Admin)', 'marbot@alikhlas.id', '4db95cf836e6b75dd0357821517bfe15574314f31c4f9a47ed9943ead9bb91fc', 'admin', 1)
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- 2. Profil Masjid Al-Ikhlas & Info Donasi
INSERT INTO `mosque_info` (`id`, `name`, `address`, `description`, `bank_name`, `bank_account`, `bank_holder`, `qris_image`, `donation_info`, `whatsapp_contact`) VALUES
(1, 'Masjid Al-Ikhlas', 'Jl. Al-Ikhlas No. 12, Semarang, Jawa Tengah', 'Pusat ibadah, kegiatan dakwah, kajian, dan santunan umat di lingkungan Al-Ikhlas.', 'Bank Syariah Indonesia (BSI)', '7123456789', 'Masjid Al-Ikhlas Semarang', '', 'Salurkan donasi terbaik Anda melalui rekening resmi di atas atau scan QRIS statis di papan masjid. Setelah transfer, mohon kirim bukti konfirmasi melalui menu Konfirmasi Donasi agar segera dicatat oleh tim marbot.', '6281234567890')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- 3. Kegiatan Masjid (Jumat Berkah, Pengajian, Bulan Puasa)
INSERT INTO `activities` (`id`, `title`, `type`, `activity_date`, `activity_time`, `location`, `pj_name`, `notes`, `status`, `created_by`) VALUES
(1, 'Jumat Berkah Berbagi Makanan', 'Jumat Berkah', '2026-11-28', '11:30 - 13:00 WIB', 'Serambi Masjid Al-Ikhlas', 'Mas Risqon', 'Target 150 porsi nasi bungkus untuk jamaah shalat Jumat.', 'terjadwal', 2),
(2, 'Pengajian Rutin Malam Ahad', 'Pengajian', '2026-11-29', '19:30 - 21:00 WIB', 'Ruang Utama Masjid Al-Ikhlas', 'Pak Hadi', 'Kajian tafsir Al-Quran bersama Ustadz Al-Hafidz.', 'terjadwal', 1),
(3, 'Kajian Muslimah & Doa Bersama', 'Pengajian', '2026-12-05', '08:30 - 10:30 WIB', 'Aula Al-Ikhlas', NULL, 'Perlu penunjukan PJ segera sebelum acara dimulai.', 'terjadwal', 1)
ON DUPLICATE KEY UPDATE `title`=VALUES(`title`);

-- 4. Saldo Awal Kas Masjid
INSERT INTO `cash_transactions` (`id`, `activity_id`, `transaction_date`, `direction`, `amount`, `note`, `status`, `created_by`) VALUES
(1, NULL, '2026-11-01', 'masuk', 5000000.00, 'Saldo awal kas kas masjid bulan November 2026', 'sah', 1)
ON DUPLICATE KEY UPDATE `amount`=VALUES(`amount`);

-- 5. Contoh Donasi Tercatat (Uang, Makanan, Barang, Jasa)
INSERT INTO `donations` (`id`, `activity_id`, `confirmation_id`, `donation_date`, `type`, `donor_name`, `description`, `value_amount`, `portions`, `payment_method`, `status`, `created_by`) VALUES
(1, 1, NULL, '2026-11-20', 'uang', 'Hamba Allah (Tembalang)', 'Infaq Jumat Berkah via transfer BSI', 500000.00, NULL, 'transfer', 'terverifikasi', 2),
(2, 1, NULL, '2026-11-20', 'makanan', 'Ibu Hj. Aminah', 'Donasi nasi kotak ayam bakar', 0.00, 50, NULL, 'terverifikasi', 2),
(3, 2, NULL, '2026-11-21', 'uang', 'Bapak Suryono', 'Infaq pengajian tunai', 300000.00, NULL, 'tunai', 'terverifikasi', 2),
(4, NULL, NULL, '2026-11-15', 'barang', 'Bapak Heru', 'Donasi sajadah panjang 2 gulung', 1200000.00, NULL, NULL, 'terverifikasi', 1),
(5, NULL, NULL, '2026-11-16', 'jasa', 'Mas Dimas (Teknisi)', 'Jasa perbaikan sound system dan kabel mic masjid', 350000.00, NULL, NULL, 'terverifikasi', 2)
ON DUPLICATE KEY UPDATE `description`=VALUES(`description`);

-- 6. Contoh Pengeluaran Kegiatan
INSERT INTO `expenses` (`id`, `activity_id`, `expense_date`, `category`, `description`, `amount`, `proof_photo`, `status`, `created_by`) VALUES
(1, 1, '2026-11-21', 'Konsumsi', 'Pembelian air mineral gelas 5 dus dan buah pisang', 220000.00, '', 'sah', 2)
ON DUPLICATE KEY UPDATE `amount`=VALUES(`amount`);

-- 7. Contoh Konfirmasi Donasi Pending dari Donatur Jauh
INSERT INTO `donation_confirmations` (`id`, `reference_code`, `activity_id`, `donor_name`, `contact`, `amount`, `donation_date`, `proof_photo`, `status`, `reject_reason`, `reviewed_by`, `reviewed_at`) VALUES
(1, 'DON-20261121-0001', 1, 'Keluarga Budi Santoso (Tembalang)', '081298765432', 250000.00, '2026-11-21', '', 'menunggu', NULL, NULL, NULL)
ON DUPLICATE KEY UPDATE `donor_name`=VALUES(`donor_name`);

-- 8. Laporan yang Sudah Dipublikasikan untuk Publik
INSERT INTO `published_reports` (`id`, `report_type`, `title`, `period_start`, `period_end`, `activity_id`, `summary_json`, `is_published`, `approved_by`, `published_at`) VALUES
(1, 'kegiatan', 'Laporan Jumat Berkah Pekan Ini', '2026-11-20', '2026-11-28', 1, '{"total_money_donation": 500000.0, "total_goods_services": 0.0, "total_food_portions": 50, "total_expense": 220000.0, "balance": 280000.0, "cash_subsidy": 0.0}', 1, 1, '2026-11-21 12:00:00')
ON DUPLICATE KEY UPDATE `title`=VALUES(`title`);
