-- =====================================================================
-- Sahabat Masjid - Database Schema (MySQL 8.x / MariaDB)
-- Sesuai SRS v1.0 Masjid Al-Ikhlas (Bab 4: Data Requirements)
-- =====================================================================

CREATE DATABASE IF NOT EXISTS `sahabat_masjid` 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE `sahabat_masjid`;

-- ---------------------------------------------------------------------
-- 1. Table: users (Pengurus: Takmir & Admin/Marbot)
-- FR-01, FR-04, FR-05
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `users` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `email` VARCHAR(120) NOT NULL UNIQUE,
    `password_hash` VARCHAR(255) NOT NULL,
    `role` ENUM('admin', 'takmir') NOT NULL DEFAULT 'admin',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. Table: activities (Kegiatan Masjid & Jadwal PJ)
-- FR-06, FR-07, FR-08, FR-09, FR-10
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `activities` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `title` VARCHAR(150) NOT NULL,
    `type` ENUM('Jumat Berkah', 'Pengajian', 'Kegiatan Bulan Puasa', 'Lainnya') NOT NULL,
    `activity_date` DATE NOT NULL,
    `activity_time` VARCHAR(20) NOT NULL,
    `location` VARCHAR(150) NOT NULL DEFAULT 'Masjid Al-Ikhlas',
    `pj_name` VARCHAR(100) NULL DEFAULT NULL,
    `notes` TEXT NULL,
    `status` ENUM('terjadwal', 'selesai', 'dibatalkan') NOT NULL DEFAULT 'terjadwal',
    `cancel_reason` TEXT NULL,
    `created_by` INT NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_activity_user` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. Table: donation_confirmations (Konfirmasi Donasi dari Donatur)
-- FR-27, FR-28, FR-29, FR-30, FR-31
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `donation_confirmations` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `reference_code` VARCHAR(30) NOT NULL UNIQUE,
    `activity_id` INT NULL DEFAULT NULL,
    `donor_name` VARCHAR(100) NULL DEFAULT NULL,
    `contact` VARCHAR(50) NULL DEFAULT NULL,
    `amount` DECIMAL(15,2) NOT NULL,
    `donation_date` DATE NOT NULL,
    `proof_photo` VARCHAR(255) NULL DEFAULT NULL,
    `status` ENUM('menunggu', 'disetujui', 'ditolak') NOT NULL DEFAULT 'menunggu',
    `reject_reason` TEXT NULL,
    `reviewed_by` INT NULL DEFAULT NULL,
    `reviewed_at` DATETIME NULL DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_confirm_activity` FOREIGN KEY (`activity_id`) REFERENCES `activities` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_confirm_reviewer` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 4. Table: donations (Pencatatan Donasi: Uang, Barang, Jasa, Makanan)
-- FR-11, FR-12, FR-13, FR-14, FR-15, FR-16, FR-17
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `donations` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `activity_id` INT NULL DEFAULT NULL,
    `confirmation_id` INT NULL DEFAULT NULL,
    `donation_date` DATE NOT NULL,
    `type` ENUM('uang', 'barang', 'jasa', 'makanan') NOT NULL,
    `donor_name` VARCHAR(100) NULL DEFAULT NULL,
    `description` TEXT NULL,
    `value_amount` DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `portions` INT NULL DEFAULT NULL,
    `payment_method` ENUM('tunai', 'transfer') NULL DEFAULT NULL,
    `status` ENUM('terverifikasi', 'dibatalkan') NOT NULL DEFAULT 'terverifikasi',
    `cancel_reason` TEXT NULL,
    `created_by` INT NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_donation_activity` FOREIGN KEY (`activity_id`) REFERENCES `activities` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_donation_confirm` FOREIGN KEY (`confirmation_id`) REFERENCES `donation_confirmations` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_donation_user` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 5. Table: expenses (Pencatatan Pengeluaran Kegiatan)
-- FR-18, FR-19, FR-20, FR-21
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `expenses` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `activity_id` INT NOT NULL,
    `expense_date` DATE NOT NULL,
    `category` VARCHAR(80) NOT NULL,
    `description` TEXT NOT NULL,
    `amount` DECIMAL(15,2) NOT NULL,
    `proof_photo` VARCHAR(255) NULL DEFAULT NULL,
    `status` ENUM('sah', 'dibatalkan') NOT NULL DEFAULT 'sah',
    `cancel_reason` TEXT NULL,
    `created_by` INT NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_expense_activity` FOREIGN KEY (`activity_id`) REFERENCES `activities` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_expense_user` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 6. Table: cash_transactions (Kas Masjid & Penambalan Selisih Kegiatan)
-- FR-22, FR-23, FR-24, FR-25, FR-26
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `cash_transactions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `activity_id` INT NULL DEFAULT NULL,
    `transaction_date` DATE NOT NULL,
    `direction` ENUM('masuk', 'keluar') NOT NULL,
    `amount` DECIMAL(15,2) NOT NULL,
    `note` TEXT NOT NULL,
    `status` ENUM('sah', 'dibatalkan') NOT NULL DEFAULT 'sah',
    `cancel_reason` TEXT NULL,
    `created_by` INT NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_cash_activity` FOREIGN KEY (`activity_id`) REFERENCES `activities` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_cash_user` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 7. Table: published_reports (Persetujuan Publikasi Laporan oleh Takmir)
-- FR-32, FR-33, FR-34, FR-35, FR-36
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `published_reports` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `report_type` ENUM('periode', 'kegiatan', 'kas') NOT NULL,
    `title` VARCHAR(150) NOT NULL,
    `period_start` DATE NULL DEFAULT NULL,
    `period_end` DATE NULL DEFAULT NULL,
    `activity_id` INT NULL DEFAULT NULL,
    `summary_json` JSON NULL,
    `is_published` TINYINT(1) NOT NULL DEFAULT 0,
    `approved_by` INT NULL DEFAULT NULL,
    `published_at` DATETIME NULL DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_pubreport_activity` FOREIGN KEY (`activity_id`) REFERENCES `activities` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_pubreport_user` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 8. Table: mosque_info (Profil Masjid & Petunjuk Cara Berdonasi)
-- FR-38, FR-39, FR-40
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `mosque_info` (
    `id` INT PRIMARY KEY DEFAULT 1,
    `name` VARCHAR(150) NOT NULL DEFAULT 'Masjid Al-Ikhlas',
    `address` TEXT NOT NULL,
    `description` TEXT NULL,
    `bank_name` VARCHAR(80) NOT NULL DEFAULT 'Bank Syariah Indonesia (BSI)',
    `bank_account` VARCHAR(50) NOT NULL DEFAULT '7123456789',
    `bank_holder` VARCHAR(100) NOT NULL DEFAULT 'Masjid Al-Ikhlas',
    `qris_image` VARCHAR(255) NULL,
    `donation_info` TEXT NULL,
    `whatsapp_contact` VARCHAR(30) NULL DEFAULT '6281234567890',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 9. Table: audit_logs (Jejak Perubahan & Pembatalan Data Keuangan)
-- FR-15, FR-16, FR-21, NFR-15, Bab 8.2
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `audit_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NULL DEFAULT NULL,
    `action` VARCHAR(50) NOT NULL,
    `entity` VARCHAR(50) NOT NULL,
    `entity_id` INT NOT NULL,
    `reason` TEXT NULL,
    `details` TEXT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_audit_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB;
