# Aturan Khusus Proyek / Brand

File ini mendefinisikan identitas dan aturan desain khusus untuk proyek **EduLimbah** sesuai panduan `SKILL.md`.

## Identitas

- Nama brand / proyek: EduLimbah
- Bidang dan audiens: Platform edukasi pengelolaan limbah B3 medis rumah tangga untuk masyarakat umum, pasien perawatan mandiri di rumah, dan keluarga pasien di wilayah Kediri & sekitarnya.
- Kesan yang diinginkan: Terpercaya, klinis-modern, tenang, ramah di mata (nuansa bioluminescent/neon lembut di atas permukaan gelap bertingkat, dengan opsi mode terang).
- Bahasa konten: Bahasa Indonesia yang jelas, instruksional, dan mudah dipahami masyarakat awam.

## Warna

| Peran | Hex (Mode Gelap Neon Ramah Mata) | Hex (Mode Terang) |
|---|---|---|
| Primer (Teal Neon / Medis) | `#2dd4bf` | `#0f766e` |
| Latar Utama (60%) | `#0b111e` | `#f6f8fa` |
| Permukaan (30%) | `#131c2e` | `#ffffff` |
| Permukaan Bertingkat | `#1a263d` | `#eef2f6` |
| Teks Utama | `#eef2f6` | `#111827` |
| Teks Redup (Muted) | `#94a3b8` | `#4b5563` |
| Semantik Kuning (Infeksius) | `#fbbf24` | `#b45309` |
| Semantik Merah (Benda Tajam / Safety Box) | `#fb7185` | `#be123c` |
| Semantik Cokelat (Farmasi / Obat) | `#fb923c` | `#9a3412` |

Dark mode: ya (default mode gelap neon lembut yang nyaman di mata, dengan tombol ganti ke mode terang).

## Tipografi

- Font judul: `"Plus Jakarta Sans"`, `system-ui`, `-apple-system`, `"Segoe UI"`, `Roboto`, `sans-serif`
- Font isi: `"Inter"`, `system-ui`, `-apple-system`, `"Segoe UI"`, `Roboto`, `sans-serif`
- Sumber font: Font sistem dengan fallback modern (`font-display: swap`).

## Teknologi

- Framework / library: HTML5 + CSS3 + Vanilla JavaScript murni (tanpa Bootstrap, tanpa Tailwind, tanpa library CDN eksternal).
- Library UI yang dipakai: tidak ada.
- Batasan: Semua nilai warna, ukuran, spasi, radius, dan durasi berasal dari token CSS (`:root`). Tidak ada inline `style` pada HTML.

## Gaya dan bentuk

- Radius sudut: 3 level (`--radius-sm: 0.25rem`, `--radius-md: 0.5rem`, `--radius-lg: 1rem`).
- Kepadatan: lega (jarak antar section 4rem–6rem, ruang kosong jelas).
- Gaya gambar dan ikon: Ikon SVG garis (`stroke-width: 2`), tanpa emoji pada elemen UI.

## Aturan tambahan

- Semua halaman memiliki `.skip-link` menuju `#konten-utama` untuk aksesibilitas keyboard.
- Bagian pembuka (Hero) di beranda langsung menghadirkan alat interaktif **Cek Cepat Wadah Limbah Medis** sebagai fokus utama.
- Urutan penanganan limbah menggunakan langkah bernomor (`1`, `2`, `3`, `4`) disertai waktu tindakan (`.step-timing`) dan bukti verifikasi (`.step-verification`).

## Yang dilarang

- Jangan memakai emoji sebagai ikon tombol atau fitur UI.
- Jangan memakai label huruf kapital kecil di atas setiap judul section.
- Jangan memberi warna berbeda pada satu kata di tengah judul `h1` sebagai aksen.
- Jangan menulis nilai hex, `px`, atau `ms` langsung di dalam selector komponen maupun inline `style` HTML.
