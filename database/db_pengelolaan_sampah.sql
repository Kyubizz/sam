-- =====================================================================
-- DATABASE SISTEM PENGELOLAAN SAMPAH
-- Role: admin, pengguna, pengelola_tps, kurir
-- DBMS: MySQL 8.0.16+ (CHECK constraint, ST_Distance_Sphere)
-- Catatan: bagian TRIGGER/PROCEDURE memakai DELIMITER (jalankan lewat
-- mysql CLI, atau atur delimiter di phpMyAdmin/DBeaver).
-- =====================================================================

CREATE DATABASE IF NOT EXISTS db_sampah
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE db_sampah;

-- ---------------------------------------------------------------------
-- 1. AKUN
-- ---------------------------------------------------------------------
CREATE TABLE users (
  user_id        BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  role           ENUM('admin','pengguna','pengelola_tps','kurir') NOT NULL,
  nama           VARCHAR(100) NOT NULL,
  email          VARCHAR(120) NOT NULL UNIQUE,
  no_hp          VARCHAR(20)  NOT NULL UNIQUE,
  password_hash  VARCHAR(255) NOT NULL,
  foto_url       VARCHAR(255) NULL,
  -- pengguna: langsung 'aktif'; pengelola_tps & kurir: 'pending' sampai diverifikasi admin
  status         ENUM('pending','aktif','nonaktif','ditolak') NOT NULL DEFAULT 'aktif',
  last_login_at  DATETIME NULL,
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_users_role_status (role, status)
) ENGINE=InnoDB;

CREATE TABLE alamat_pengguna (
  alamat_id       BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id         BIGINT UNSIGNED NOT NULL,
  label           VARCHAR(50) NOT NULL DEFAULT 'Rumah',
  alamat_lengkap  TEXT NOT NULL,
  latitude        DECIMAL(10,7) NOT NULL,
  longitude       DECIMAL(10,7) NOT NULL,
  is_default      TINYINT(1) NOT NULL DEFAULT 0,
  CONSTRAINT fk_alamat_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE kurir_profil (
  user_id              BIGINT UNSIGNED PRIMARY KEY,
  jenis_kendaraan      VARCHAR(30) NOT NULL,
  plat_nomor           VARCHAR(15) NOT NULL,
  no_sim               VARCHAR(30) NULL,
  kapasitas_angkut_kg  DECIMAL(8,2) NULL,
  status_ketersediaan  ENUM('offline','online','bertugas') NOT NULL DEFAULT 'offline',
  lat_terakhir         DECIMAL(10,7) NULL,
  lng_terakhir         DECIMAL(10,7) NULL,
  lokasi_update_at     DATETIME NULL,
  rating_rata          DECIMAL(3,2) NOT NULL DEFAULT 0,
  CONSTRAINT fk_kurir_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. TPS & JENIS SAMPAH
-- ---------------------------------------------------------------------
CREATE TABLE tps (
  tps_id                 BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pengelola_id           BIGINT UNSIGNED NOT NULL,   -- users.role = 'pengelola_tps' (validasi di aplikasi)
  nama_tps               VARCHAR(120) NOT NULL,
  alamat                 VARCHAR(255) NOT NULL,
  latitude               DECIMAL(10,7) NOT NULL,
  longitude              DECIMAL(10,7) NOT NULL,
  kapasitas_total_kg     DECIMAL(12,2) NOT NULL,
  kapasitas_terpakai_kg  DECIMAL(12,2) NOT NULL DEFAULT 0,  -- disinkronkan trigger dari tps_jenis_sampah
  jam_buka               TIME NULL,
  jam_tutup              TIME NULL,
  no_izin                VARCHAR(100) NULL,
  izin_limbah_medis      TINYINT(1) NOT NULL DEFAULT 0,     -- 1 = berizin menerima limbah medis
  status                 ENUM('buka','tutup','penuh') NOT NULL DEFAULT 'buka',
  is_verified            TINYINT(1) NOT NULL DEFAULT 0,     -- diverifikasi admin
  created_at             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_tps_pengelola FOREIGN KEY (pengelola_id) REFERENCES users(user_id),
  CONSTRAINT chk_tps_kapasitas CHECK (kapasitas_total_kg > 0 AND kapasitas_terpakai_kg >= 0),
  INDEX idx_tps_status (status, is_verified),
  INDEX idx_tps_pengelola (pengelola_id)
) ENGINE=InnoDB;

CREATE TABLE jenis_sampah (
  jenis_id                 BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nama                     VARCHAR(80) NOT NULL UNIQUE,
  kategori                 ENUM('organik','anorganik','b3','elektronik','medis') NOT NULL,
  deskripsi                VARCHAR(255) NULL,
  perlu_penanganan_khusus  TINYINT(1) NOT NULL DEFAULT 0,
  poin_per_kg              INT NOT NULL DEFAULT 0
) ENGINE=InnoDB;

-- Jenis sampah yang diterima tiap TPS + kapasitas per jenis
CREATE TABLE tps_jenis_sampah (
  tps_id             BIGINT UNSIGNED NOT NULL,
  jenis_id           BIGINT UNSIGNED NOT NULL,
  kapasitas_maks_kg  DECIMAL(12,2) NOT NULL,
  terpakai_kg        DECIMAL(12,2) NOT NULL DEFAULT 0,
  diterima           TINYINT(1) NOT NULL DEFAULT 1,
  catatan            VARCHAR(255) NULL,
  updated_at         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (tps_id, jenis_id),
  CONSTRAINT fk_tjs_tps   FOREIGN KEY (tps_id)   REFERENCES tps(tps_id) ON DELETE CASCADE,
  CONSTRAINT fk_tjs_jenis FOREIGN KEY (jenis_id) REFERENCES jenis_sampah(jenis_id),
  CONSTRAINT chk_tjs CHECK (kapasitas_maks_kg >= 0 AND terpakai_kg >= 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. SETORAN (transaksi pembuangan sampah)
-- ---------------------------------------------------------------------
-- Alur status:
--   dijemput      : menunggu_kurir -> kurir_ditugaskan -> diangkut -> tiba_di_tps -> selesai
--   antar_sendiri : menuju_tps -> tiba_di_tps -> selesai
--   cabang        : ditolak_tps / dibatalkan
CREATE TABLE setoran (
  setoran_id             BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  kode_setoran           VARCHAR(25) NOT NULL UNIQUE,      -- contoh: STR-20261105-0001 (dibuat aplikasi)
  pengguna_id            BIGINT UNSIGNED NOT NULL,
  tps_id                 BIGINT UNSIGNED NOT NULL,
  metode                 ENUM('dijemput','antar_sendiri') NOT NULL,
  status                 ENUM('diajukan','menunggu_kurir','kurir_ditugaskan','diangkut',
                              'menuju_tps','tiba_di_tps','selesai','ditolak_tps','dibatalkan')
                         NOT NULL DEFAULT 'diajukan',
  estimasi_tiba          DATETIME NULL,                    -- untuk antar_sendiri
  catatan_pengguna       VARCHAR(255) NULL,
  alasan_penolakan       VARCHAR(255) NULL,
  total_berat_aktual_kg  DECIMAL(10,2) NULL,
  total_poin             INT NOT NULL DEFAULT 0,
  created_at             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  selesai_at             DATETIME NULL,
  CONSTRAINT fk_setoran_pengguna FOREIGN KEY (pengguna_id) REFERENCES users(user_id),
  CONSTRAINT fk_setoran_tps      FOREIGN KEY (tps_id)      REFERENCES tps(tps_id),
  INDEX idx_setoran_tps_status (tps_id, status),
  INDEX idx_setoran_pengguna (pengguna_id, created_at),
  INDEX idx_setoran_status (status)
) ENGINE=InnoDB;

CREATE TABLE setoran_detail (
  detail_id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  setoran_id         BIGINT UNSIGNED NOT NULL,
  jenis_id           BIGINT UNSIGNED NOT NULL,
  berat_estimasi_kg  DECIMAL(10,2) NOT NULL,
  berat_aktual_kg    DECIMAL(10,2) NULL,                  -- diisi pengelola TPS saat menimbang
  foto_url           VARCHAR(255) NULL,
  catatan            VARCHAR(255) NULL,
  UNIQUE KEY uq_setoran_jenis (setoran_id, jenis_id),
  CONSTRAINT fk_sd_setoran FOREIGN KEY (setoran_id) REFERENCES setoran(setoran_id) ON DELETE CASCADE,
  CONSTRAINT fk_sd_jenis   FOREIGN KEY (jenis_id)   REFERENCES jenis_sampah(jenis_id),
  CONSTRAINT chk_sd_berat CHECK (berat_estimasi_kg > 0 AND (berat_aktual_kg IS NULL OR berat_aktual_kg >= 0))
) ENGINE=InnoDB;

-- Khusus metode 'dijemput' (1 setoran = 1 penjemputan)
CREATE TABLE penjemputan (
  penjemputan_id    BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  setoran_id        BIGINT UNSIGNED NOT NULL UNIQUE,
  alamat_id         BIGINT UNSIGNED NOT NULL,
  kurir_id          BIGINT UNSIGNED NULL,                 -- NULL sampai ada kurir yang menerima
  jadwal_jemput     DATETIME NULL,
  status            ENUM('menunggu','diterima','diangkut','tiba_di_tps','dibatalkan')
                    NOT NULL DEFAULT 'menunggu',
  diterima_at       DATETIME NULL,
  diangkut_at       DATETIME NULL,
  tiba_at           DATETIME NULL,
  foto_bukti_ambil  VARCHAR(255) NULL,
  foto_bukti_serah  VARCHAR(255) NULL,
  catatan_kurir     VARCHAR(255) NULL,
  CONSTRAINT fk_pj_setoran FOREIGN KEY (setoran_id) REFERENCES setoran(setoran_id) ON DELETE CASCADE,
  CONSTRAINT fk_pj_alamat  FOREIGN KEY (alamat_id)  REFERENCES alamat_pengguna(alamat_id),
  CONSTRAINT fk_pj_kurir   FOREIGN KEY (kurir_id)   REFERENCES kurir_profil(user_id),
  INDEX idx_pj_kurir_status (kurir_id, status)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 4. NOTIFIKASI, KONTEN, ULASAN, POIN, LOG
-- ---------------------------------------------------------------------
CREATE TABLE notifikasi (
  notif_id     BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  penerima_id  BIGINT UNSIGNED NOT NULL,
  setoran_id   BIGINT UNSIGNED NULL,
  tipe         ENUM('tugas_baru','kurir_ditugaskan','sampah_akan_diantar','sampah_tiba',
                    'setoran_selesai','setoran_ditolak','akun_diverifikasi','pengumuman') NOT NULL,
  judul        VARCHAR(150) NOT NULL,
  pesan        VARCHAR(500) NOT NULL,
  is_read      TINYINT(1) NOT NULL DEFAULT 0,
  read_at      DATETIME NULL,
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_notif_user    FOREIGN KEY (penerima_id) REFERENCES users(user_id) ON DELETE CASCADE,
  CONSTRAINT fk_notif_setoran FOREIGN KEY (setoran_id)  REFERENCES setoran(setoran_id) ON DELETE SET NULL,
  INDEX idx_notif_inbox (penerima_id, is_read, created_at)
) ENGINE=InnoDB;

CREATE TABLE konten (
  konten_id     BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  admin_id      BIGINT UNSIGNED NOT NULL,
  judul         VARCHAR(200) NOT NULL,
  slug          VARCHAR(220) NOT NULL UNIQUE,
  jenis         ENUM('artikel','edukasi','pengumuman','banner') NOT NULL,
  ringkasan     VARCHAR(300) NULL,
  isi           MEDIUMTEXT NOT NULL,
  gambar_url    VARCHAR(255) NULL,
  status        ENUM('draft','terbit','arsip') NOT NULL DEFAULT 'draft',
  published_at  DATETIME NULL,
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_konten_admin FOREIGN KEY (admin_id) REFERENCES users(user_id),
  INDEX idx_konten_publik (status, jenis, published_at)
) ENGINE=InnoDB;

CREATE TABLE ulasan (
  ulasan_id     BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  setoran_id    BIGINT UNSIGNED NOT NULL UNIQUE,
  pengguna_id   BIGINT UNSIGNED NOT NULL,
  rating_kurir  TINYINT NULL,
  rating_tps    TINYINT NULL,
  komentar      VARCHAR(500) NULL,
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ulasan_setoran  FOREIGN KEY (setoran_id)  REFERENCES setoran(setoran_id) ON DELETE CASCADE,
  CONSTRAINT fk_ulasan_pengguna FOREIGN KEY (pengguna_id) REFERENCES users(user_id),
  CONSTRAINT chk_rating CHECK ((rating_kurir IS NULL OR rating_kurir BETWEEN 1 AND 5)
                           AND (rating_tps   IS NULL OR rating_tps   BETWEEN 1 AND 5))
) ENGINE=InnoDB;

CREATE TABLE transaksi_poin (
  transaksi_id  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pengguna_id   BIGINT UNSIGNED NOT NULL,
  setoran_id    BIGINT UNSIGNED NULL,
  tipe          ENUM('masuk','keluar') NOT NULL,
  jumlah        INT NOT NULL,
  keterangan    VARCHAR(200) NULL,
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_poin_pengguna FOREIGN KEY (pengguna_id) REFERENCES users(user_id),
  CONSTRAINT fk_poin_setoran  FOREIGN KEY (setoran_id)  REFERENCES setoran(setoran_id) ON DELETE SET NULL,
  CONSTRAINT chk_poin CHECK (jumlah > 0),
  INDEX idx_poin_pengguna (pengguna_id, created_at)
) ENGINE=InnoDB;

CREATE TABLE setoran_status_log (
  log_id       BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  setoran_id   BIGINT UNSIGNED NOT NULL,
  status_lama  VARCHAR(20) NULL,
  status_baru  VARCHAR(20) NOT NULL,
  diubah_oleh  BIGINT UNSIGNED NULL,
  catatan      VARCHAR(255) NULL,
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_log_setoran FOREIGN KEY (setoran_id)  REFERENCES setoran(setoran_id) ON DELETE CASCADE,
  CONSTRAINT fk_log_user    FOREIGN KEY (diubah_oleh) REFERENCES users(user_id) ON DELETE SET NULL,
  INDEX idx_log_setoran (setoran_id, created_at)
) ENGINE=InnoDB;

CREATE TABLE log_aktivitas_admin (
  log_id        BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  admin_id      BIGINT UNSIGNED NOT NULL,
  aksi          VARCHAR(60) NOT NULL,        -- mis. 'verifikasi_tps', 'nonaktifkan_akun', 'terbitkan_konten'
  tabel_target  VARCHAR(60) NULL,
  id_target     BIGINT UNSIGNED NULL,
  detail        JSON NULL,
  ip_address    VARCHAR(45) NULL,
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ladmin_user FOREIGN KEY (admin_id) REFERENCES users(user_id),
  INDEX idx_ladmin (admin_id, created_at)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 5. DATA AWAL: JENIS SAMPAH
-- ---------------------------------------------------------------------
INSERT INTO jenis_sampah (nama, kategori, deskripsi, perlu_penanganan_khusus, poin_per_kg) VALUES
('Sisa makanan',            'organik',    'Sisa dapur dan makanan',                         0, 5),
('Daun dan ranting',        'organik',    'Sampah kebun',                                   0, 5),
('Plastik',                 'anorganik',  'Botol, kemasan, kantong plastik',                0, 20),
('Kertas dan kardus',       'anorganik',  'Kertas bekas, kardus, koran',                    0, 15),
('Logam',                   'anorganik',  'Kaleng, besi, aluminium',                        0, 30),
('Kaca',                    'anorganik',  'Botol dan pecahan kaca',                         1, 10),
('Baterai bekas',           'b3',         'Baterai dan aki kecil',                          1, 10),
('Lampu bekas',             'b3',         'Lampu neon dan LED',                             1, 10),
('Elektronik bekas',        'elektronik', 'Ponsel, kabel, peralatan elektronik',            1, 25),
('Medis - infeksius',       'medis',      'Perban, sarung tangan, masker bekas pakai',      1, 0),
('Medis - benda tajam',     'medis',      'Jarum suntik, pisau bedah, ampul pecah',         1, 0),
('Medis - farmasi',         'medis',      'Obat kedaluwarsa dan sisa obat',                 1, 0),
('Medis - patologis',       'medis',      'Jaringan dan cairan tubuh dari fasilitas medis', 1, 0);

-- ---------------------------------------------------------------------
-- 6. VIEW
-- ---------------------------------------------------------------------
-- Ringkasan kapasitas TPS (dashboard pengelola TPS)
CREATE VIEW v_kapasitas_tps AS
SELECT t.tps_id, t.nama_tps, t.status,
       t.kapasitas_total_kg, t.kapasitas_terpakai_kg,
       (t.kapasitas_total_kg - t.kapasitas_terpakai_kg) AS sisa_kg,
       ROUND(t.kapasitas_terpakai_kg / t.kapasitas_total_kg * 100, 1) AS persen_terisi
FROM tps t;

-- Sampah yang sedang/akan diantar ke TPS (notifikasi pengelola TPS)
CREATE VIEW v_setoran_masuk_tps AS
SELECT s.setoran_id, s.kode_setoran, s.tps_id, s.metode, s.status, s.estimasi_tiba,
       u.nama  AS nama_pengguna,
       kr.nama AS nama_kurir,
       SUM(d.berat_estimasi_kg)         AS total_estimasi_kg,
       GROUP_CONCAT(j.nama SEPARATOR ', ') AS jenis_sampah
FROM setoran s
JOIN users u            ON u.user_id = s.pengguna_id
JOIN setoran_detail d   ON d.setoran_id = s.setoran_id
JOIN jenis_sampah j     ON j.jenis_id = d.jenis_id
LEFT JOIN penjemputan p ON p.setoran_id = s.setoran_id
LEFT JOIN users kr      ON kr.user_id = p.kurir_id
WHERE s.status IN ('diangkut','menuju_tps','tiba_di_tps')
GROUP BY s.setoran_id, s.kode_setoran, s.tps_id, s.metode, s.status, s.estimasi_tiba, u.nama, kr.nama;

-- Tugas angkut kurir: lokasi jemput + lokasi TPS tujuan
CREATE VIEW v_tugas_angkut AS
SELECT p.penjemputan_id, p.kurir_id, p.status AS status_penjemputan,
       s.setoran_id, s.kode_setoran, p.jadwal_jemput,
       a.alamat_lengkap AS alamat_jemput, a.latitude AS jemput_lat, a.longitude AS jemput_lng,
       t.nama_tps, t.alamat AS alamat_tps, t.latitude AS tps_lat, t.longitude AS tps_lng
FROM penjemputan p
JOIN setoran s         ON s.setoran_id = p.setoran_id
JOIN alamat_pengguna a ON a.alamat_id = p.alamat_id
JOIN tps t             ON t.tps_id = s.tps_id;

-- ---------------------------------------------------------------------
-- 7. TRIGGER & STORED PROCEDURE
-- Sebelum eksekusi per-request, backend dapat mengisi: SET @app_user_id = <user_id>;
-- agar log status mencatat siapa yang mengubah.
-- ---------------------------------------------------------------------
DELIMITER $$

-- Status awal setoran ditentukan dari metode
CREATE TRIGGER trg_setoran_bi BEFORE INSERT ON setoran FOR EACH ROW
BEGIN
  IF NEW.metode = 'dijemput' THEN
    SET NEW.status = 'menunggu_kurir';
  ELSE
    SET NEW.status = 'menuju_tps';
  END IF;
END$$

-- Validasi: TPS buka, menerima jenis tsb, berizin (jika medis), dan kapasitas cukup
CREATE TRIGGER trg_setoran_detail_bi BEFORE INSERT ON setoran_detail FOR EACH ROW
BEGIN
  DECLARE v_tps       BIGINT UNSIGNED;
  DECLARE v_status    VARCHAR(10);
  DECLARE v_izin      TINYINT(1);
  DECLARE v_kategori  VARCHAR(20);
  DECLARE v_diterima  TINYINT(1);
  DECLARE v_sisa      DECIMAL(12,2);

  SELECT t.tps_id, t.status, t.izin_limbah_medis
    INTO v_tps, v_status, v_izin
    FROM setoran s JOIN tps t ON t.tps_id = s.tps_id
   WHERE s.setoran_id = NEW.setoran_id;

  SELECT kategori INTO v_kategori FROM jenis_sampah WHERE jenis_id = NEW.jenis_id;

  SELECT diterima, (kapasitas_maks_kg - terpakai_kg)
    INTO v_diterima, v_sisa
    FROM tps_jenis_sampah
   WHERE tps_id = v_tps AND jenis_id = NEW.jenis_id;

  IF v_status <> 'buka' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TPS sedang tutup atau penuh';
  END IF;
  IF v_diterima IS NULL OR v_diterima = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TPS tidak menerima jenis sampah ini';
  END IF;
  IF v_kategori = 'medis' AND v_izin = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TPS tidak memiliki izin limbah medis';
  END IF;
  IF v_sisa < NEW.berat_estimasi_kg THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Kapasitas TPS untuk jenis ini tidak mencukupi';
  END IF;
END$$

-- Setoran baru: notifikasi ke pengelola TPS (antar sendiri) atau ke semua kurir online (dijemput)
CREATE TRIGGER trg_setoran_ai AFTER INSERT ON setoran FOR EACH ROW
BEGIN
  INSERT INTO setoran_status_log (setoran_id, status_lama, status_baru, diubah_oleh)
  VALUES (NEW.setoran_id, NULL, NEW.status, NEW.pengguna_id);

  IF NEW.metode = 'antar_sendiri' THEN
    INSERT INTO notifikasi (penerima_id, setoran_id, tipe, judul, pesan)
    SELECT t.pengelola_id, NEW.setoran_id, 'sampah_akan_diantar',
           'Sampah akan diantar pengguna',
           CONCAT('Setoran ', NEW.kode_setoran, ' akan diantar sendiri oleh pengguna ke ', t.nama_tps)
      FROM tps t WHERE t.tps_id = NEW.tps_id;
  ELSE
    -- Untuk produksi, filter kurir terdekat di aplikasi (lat_terakhir/lng_terakhir).
    INSERT INTO notifikasi (penerima_id, setoran_id, tipe, judul, pesan)
    SELECT k.user_id, NEW.setoran_id, 'tugas_baru',
           'Tugas angkut baru',
           CONCAT('Setoran ', NEW.kode_setoran, ' menunggu diangkut. TPS tujuan: ', t.nama_tps, ', ', t.alamat)
      FROM kurir_profil k JOIN tps t ON t.tps_id = NEW.tps_id
     WHERE k.status_ketersediaan = 'online';
  END IF;
END$$

-- Catat setiap perubahan status setoran
CREATE TRIGGER trg_setoran_au AFTER UPDATE ON setoran FOR EACH ROW
BEGIN
  IF NOT (OLD.status <=> NEW.status) THEN
    INSERT INTO setoran_status_log (setoran_id, status_lama, status_baru, diubah_oleh)
    VALUES (NEW.setoran_id, OLD.status, NEW.status, @app_user_id);
  END IF;
END$$

-- Kemajuan penjemputan -> sinkron status setoran + notifikasi
-- Catatan: agar tidak rebutan, kurir menerima tugas lewat:
--   UPDATE penjemputan SET kurir_id=?, status='diterima', diterima_at=NOW()
--    WHERE setoran_id=? AND kurir_id IS NULL;   -- cek ROW_COUNT() = 1
CREATE TRIGGER trg_penjemputan_au AFTER UPDATE ON penjemputan FOR EACH ROW
BEGIN
  IF NOT (OLD.status <=> NEW.status) THEN

    IF NEW.status = 'diterima' THEN
      UPDATE setoran SET status = 'kurir_ditugaskan' WHERE setoran_id = NEW.setoran_id;
      UPDATE kurir_profil SET status_ketersediaan = 'bertugas' WHERE user_id = NEW.kurir_id;
      INSERT INTO notifikasi (penerima_id, setoran_id, tipe, judul, pesan)
      SELECT s.pengguna_id, s.setoran_id, 'kurir_ditugaskan',
             'Kurir menuju lokasi Anda',
             CONCAT('Kurir telah menerima penjemputan setoran ', s.kode_setoran)
        FROM setoran s WHERE s.setoran_id = NEW.setoran_id;

    ELSEIF NEW.status = 'diangkut' THEN
      UPDATE setoran SET status = 'diangkut' WHERE setoran_id = NEW.setoran_id;
      INSERT INTO notifikasi (penerima_id, setoran_id, tipe, judul, pesan)
      SELECT t.pengelola_id, s.setoran_id, 'sampah_akan_diantar',
             'Sampah akan diantar kurir',
             CONCAT('Kurir membawa setoran ', s.kode_setoran, ' menuju ', t.nama_tps)
        FROM setoran s JOIN tps t ON t.tps_id = s.tps_id
       WHERE s.setoran_id = NEW.setoran_id;

    ELSEIF NEW.status = 'tiba_di_tps' THEN
      UPDATE setoran SET status = 'tiba_di_tps' WHERE setoran_id = NEW.setoran_id;
      UPDATE kurir_profil SET status_ketersediaan = 'online' WHERE user_id = NEW.kurir_id;
      INSERT INTO notifikasi (penerima_id, setoran_id, tipe, judul, pesan)
      SELECT t.pengelola_id, s.setoran_id, 'sampah_tiba',
             'Sampah tiba di TPS',
             CONCAT('Setoran ', s.kode_setoran, ' sudah tiba dan siap ditimbang')
        FROM setoran s JOIN tps t ON t.tps_id = s.tps_id
       WHERE s.setoran_id = NEW.setoran_id;

    ELSEIF NEW.status = 'dibatalkan' THEN
      IF NEW.kurir_id IS NOT NULL THEN
        UPDATE kurir_profil SET status_ketersediaan = 'online' WHERE user_id = NEW.kurir_id;
      END IF;
    END IF;

  END IF;
END$$

-- Sinkronkan kapasitas TPS saat terpakai_kg per jenis berubah
-- (termasuk saat TPS mengosongkan sampah secara manual)
CREATE TRIGGER trg_tjs_au AFTER UPDATE ON tps_jenis_sampah FOR EACH ROW
BEGIN
  DECLARE v_total DECIMAL(12,2);

  SELECT COALESCE(SUM(terpakai_kg), 0) INTO v_total
    FROM tps_jenis_sampah WHERE tps_id = NEW.tps_id;

  UPDATE tps
     SET kapasitas_terpakai_kg = v_total,
         status = CASE
                    WHEN status = 'buka'  AND v_total >= kapasitas_total_kg THEN 'penuh'
                    WHEN status = 'penuh' AND v_total <  kapasitas_total_kg THEN 'buka'
                    ELSE status
                  END
   WHERE tps_id = NEW.tps_id;
END$$

-- Dipanggil pengelola TPS setelah menimbang (berat_aktual_kg sudah diisi semua)
-- CALL sp_selesaikan_setoran(<setoran_id>);
CREATE PROCEDURE sp_selesaikan_setoran(IN p_setoran_id BIGINT UNSIGNED)
BEGIN
  DECLARE v_tps     BIGINT UNSIGNED;
  DECLARE v_user    BIGINT UNSIGNED;
  DECLARE v_status  VARCHAR(20);
  DECLARE v_kode    VARCHAR(25);
  DECLARE v_berat   DECIMAL(10,2);
  DECLARE v_poin    INT;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT tps_id, pengguna_id, status, kode_setoran
    INTO v_tps, v_user, v_status, v_kode
    FROM setoran WHERE setoran_id = p_setoran_id FOR UPDATE;

  IF v_status IS NULL OR v_status <> 'tiba_di_tps' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Setoran tidak ditemukan atau belum tiba di TPS';
  END IF;

  IF EXISTS (SELECT 1 FROM setoran_detail
              WHERE setoran_id = p_setoran_id AND berat_aktual_kg IS NULL) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Berat aktual belum diisi untuk semua jenis sampah';
  END IF;

  SELECT COALESCE(SUM(d.berat_aktual_kg), 0),
         COALESCE(FLOOR(SUM(d.berat_aktual_kg * j.poin_per_kg)), 0)
    INTO v_berat, v_poin
    FROM setoran_detail d JOIN jenis_sampah j ON j.jenis_id = d.jenis_id
   WHERE d.setoran_id = p_setoran_id;

  -- Tambah kapasitas terpakai per jenis (trigger trg_tjs_au menyinkronkan total TPS)
  UPDATE tps_jenis_sampah tjs
    JOIN setoran_detail d ON d.jenis_id = tjs.jenis_id AND d.setoran_id = p_setoran_id
     SET tjs.terpakai_kg = tjs.terpakai_kg + d.berat_aktual_kg
   WHERE tjs.tps_id = v_tps;

  UPDATE setoran
     SET status = 'selesai', total_berat_aktual_kg = v_berat,
         total_poin = v_poin, selesai_at = NOW()
   WHERE setoran_id = p_setoran_id;

  IF v_poin > 0 THEN
    INSERT INTO transaksi_poin (pengguna_id, setoran_id, tipe, jumlah, keterangan)
    VALUES (v_user, p_setoran_id, 'masuk', v_poin, CONCAT('Poin setoran ', v_kode));
  END IF;

  INSERT INTO notifikasi (penerima_id, setoran_id, tipe, judul, pesan)
  VALUES (v_user, p_setoran_id, 'setoran_selesai', 'Setoran selesai',
          CONCAT('Setoran ', v_kode, ' diterima seberat ', v_berat, ' kg. Poin: ', v_poin));

  COMMIT;
END$$

-- Rekomendasi TPS terdekat yang buka, terverifikasi, menerima jenis tsb, dan kapasitasnya cukup
-- CALL sp_rekomendasi_tps(-7.8480, 112.0178, <jenis_id>, 5.0);
CREATE PROCEDURE sp_rekomendasi_tps(
  IN p_lat      DECIMAL(10,7),
  IN p_lng      DECIMAL(10,7),
  IN p_jenis_id BIGINT UNSIGNED,
  IN p_berat    DECIMAL(10,2))
BEGIN
  SELECT t.tps_id, t.nama_tps, t.alamat,
         ROUND(ST_Distance_Sphere(POINT(p_lng, p_lat), POINT(t.longitude, t.latitude)) / 1000, 2) AS jarak_km,
         (tj.kapasitas_maks_kg - tj.terpakai_kg) AS sisa_kg
    FROM tps t
    JOIN tps_jenis_sampah tj ON tj.tps_id = t.tps_id AND tj.jenis_id = p_jenis_id AND tj.diterima = 1
    JOIN jenis_sampah j      ON j.jenis_id = tj.jenis_id
   WHERE t.status = 'buka'
     AND t.is_verified = 1
     AND (j.kategori <> 'medis' OR t.izin_limbah_medis = 1)
     AND (tj.kapasitas_maks_kg - tj.terpakai_kg) >= p_berat
   ORDER BY jarak_km
   LIMIT 5;
END$$

DELIMITER ;
