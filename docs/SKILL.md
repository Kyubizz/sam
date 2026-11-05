---
name: web-design-rules
description: Aturan desain web yang harus diikuti AI saat membuat, memperbaiki, atau me-review tampilan website, landing page, dashboard, halaman HTML/CSS, komponen React atau Tailwind, dan UI apa pun. Pakai skill ini setiap kali user meminta membuat atau merapikan halaman web atau antarmuka, bahkan jika kata "desain" tidak disebut (misalnya "buatkan landing page", "bikin website toko", "rapikan tampilan ini", "buat dashboard", "redesign halaman ini"). Use for any web design, UI, front-end layout, styling, or website-building request. Berisi aturan token desain, tipografi, warna, spasi, layout, responsif, aksesibilitas, komponen, motion, copywriting, dan checklist sebelum hasil diserahkan.
---

# Aturan Desain Web

Skill ini memberi AI aturan yang konsisten setiap kali membuat atau memperbaiki tampilan web. Tujuannya dua: menjamin kualitas minimum (terbaca, rapi, nyaman di HP, bisa diakses semua orang) dan mencegah hasil yang terasa generik.

Jika dua aturan bertabrakan, urutan prioritasnya:

1. Permintaan eksplisit user di percakapan ini.
2. `references/aturan-proyek.md`, yaitu aturan khusus brand atau proyek milik user. Baca file ini lebih dulu; jika sudah terisi, isinya mengalahkan default di bawah.
3. Aturan di file ini.

Jika skill `frontend-design` tersedia, pakai untuk menentukan arah estetika. Skill ini berfungsi sebagai lantai kualitas dan penjaga konsistensi di bawahnya.

## Alur kerja

1. **Kenali konteks.** Apa subjeknya, siapa audiensnya, dan apa satu aksi utama yang harus terjadi di halaman ini (beli, daftar, hubungi, baca)? Jika brief tidak menyebutnya, buat asumsi, tulis dalam satu kalimat, lalu lanjut. Jangan menginterogasi user.
2. **Baca aturan proyek** di `references/aturan-proyek.md`.
3. **Tulis rencana desain singkat** sebelum menulis kode: 4–6 warna bernama, font dan perannya, konsep layout, skala spasi.
4. **Bangun dengan token.** Semua nilai warna, ukuran, dan jarak datang dari CSS variables. `assets/base.css` bisa jadi titik awal, tetapi ganti nilainya sesuai subjek, jangan dipakai apa adanya.
5. **Periksa dengan checklist** di bagian akhir sebelum menyerahkan hasil.

## 1. Token dulu, baru komponen

Definisikan token di `:root` dan pakai di mana-mana. Alasannya: satu perubahan nilai merambat ke seluruh halaman, dan inkonsistensi (tiga abu-abu berbeda, lima ukuran radius) tidak sempat muncul.

- Token wajib: warna, ukuran font, spasi, radius, shadow, durasi animasi.
- Jangan menulis nilai hex, px, atau ms langsung di dalam komponen.
- Jika memakai Tailwind, daftarkan token di konfigurasi tema, jangan menyebar nilai arbitrer seperti `w-[347px]` atau `text-[#3a5f2c]`.

## 2. Tipografi

Tipografi menentukan kepribadian halaman, jadi pilih dengan sengaja.

- Maksimal dua keluarga font. Jika dua, bedakan dengan jelas (misalnya serif untuk judul dan sans untuk isi). Satu keluarga dengan variasi weight juga baik.
- Ukuran teks isi minimal 16px (1rem). Gunakan `rem`, bukan `px`, agar mengikuti pengaturan pengguna.
- Pakai skala ukuran dengan rasio tetap (misalnya 1.25) dan `clamp()` untuk judul besar agar menyesuaikan layar.
- Panjang baris 45–75 karakter (`max-width: 65ch` untuk paragraf). Baris terlalu panjang melelahkan mata.
- Line-height isi 1.5–1.7, judul 1.1–1.3. Teks serif butuh sedikit lebih longgar daripada sans.
- Batasi hierarki: dalam satu layar, pembaca tidak perlu membedakan lebih dari 3–4 level ukuran.
- Sediakan font fallback, pakai `font-display: swap`, dan batasi 2–3 weight agar halaman tetap ringan.
- Hindari huruf kapital semua untuk teks panjang, paragraf rata tengah lebih dari dua baris, dan teks justify tanpa `hyphens: auto`.

## 3. Warna

- Susun palet dari: satu skala netral, satu warna primer, satu aksen (opsional), dan warna semantik (sukses, peringatan, error, info).
- Gunakan proporsi kira-kira 60% netral, 30% sekunder, 10% aksen. Aksen yang muncul di mana-mana berhenti berfungsi sebagai aksen.
- Kontras WCAG AA adalah batas minimum: teks biasa 4.5:1, teks besar (≥24px, atau ≥19px tebal) 3:1, ikon dan batas komponen UI 3:1. Hitung, jangan menebak.
- Jangan mengandalkan warna saja untuk makna. Error harus punya ikon atau teks, bukan hanya warna merah.
- Pilih palet dari dunia subjeknya (bahan, suasana, industri), bukan dari kebiasaan. Toko kopi, aplikasi keuangan, dan situs sekolah anak tidak boleh berakhir dengan palet yang sama.
- Dark mode, jika didukung, memakai set token sendiri (bukan sekadar membalik warna). Permukaan bertingkat lebih nyaman daripada hitam pekat dengan putih murni.

## 4. Spasi dan layout

- Pakai skala spasi berbasis 4px: 4, 8, 12, 16, 24, 32, 48, 64, 96. Nilai di luar skala biasanya tanda keputusan yang tidak disengaja.
- Prinsip kedekatan: jarak di dalam satu grup selalu lebih kecil daripada jarak antar grup. Ini yang membuat struktur terbaca tanpa garis pembatas.
- Jarak antar section 64–120px di desktop, 48–72px di mobile. Ruang kosong adalah bagian dari desain, bukan sisa.
- Container berlebar maksimum sekitar 1100–1280px, dengan padding samping 16px di mobile dan 24–32px di desktop.
- Pakai CSS Grid atau Flexbox dengan `gap`, bukan margin yang ditumpuk.
- Pilih satu sumbu alignment dan patuhi. Mencampur rata kiri dan rata tengah tanpa alasan membuat halaman terasa berantakan.
- Satu fokus per section, dan satu tombol utama per layar. Jika semuanya menonjol, tidak ada yang menonjol.
- Bagian pembuka (hero) adalah hal pertama yang dilihat orang. Buka dengan hal yang paling khas dari subjeknya: judul yang spesifik, gambar, demo, atau momen interaktif, bukan template judul + subjudul + dua tombol.

## 5. Responsif (mobile-first)

Mayoritas pengunjung membuka dari HP, jadi desain mulai dari lebar 360px lalu diperluas.

- Selalu sertakan `<meta name="viewport" content="width=device-width, initial-scale=1">`.
- Breakpoint acuan: 480, 768, 1024, 1280px. Tambahkan hanya jika konten benar-benar rusak di antaranya.
- Tidak boleh ada scroll horizontal pada halaman. Tabel atau kode yang lebar dibungkus container dengan `overflow-x: auto`.
- Target sentuh minimal 44×44px dengan jarak cukup antar target.
- Gambar: `max-width: 100%; height: auto`, tentukan `aspect-ratio` atau `width`/`height` agar layout tidak melompat, `loading="lazy"` untuk gambar di bawah layar pertama.
- Navigasi diciutkan di mobile. Gunakan `100dvh`, bukan `100vh`, untuk tinggi satu layar.
- Input teks berukuran font minimal 16px, supaya browser iOS tidak memperbesar halaman saat fokus.

## 6. Komponen

- **Tombol.** Ada hierarki jelas: primer, sekunder, tersier. Semua state ada: hover, `:focus-visible`, active, disabled, loading. Label berupa kata kerja spesifik ("Simpan perubahan"), bukan "Submit".
- **Form.** Label selalu terlihat (placeholder bukan pengganti label). Pesan error muncul dekat field, menjelaskan apa yang salah dan cara memperbaikinya. Pakai `type` dan `autocomplete` yang tepat (`email`, `tel`, dan sebagainya).
- **Kartu.** Pakai hanya jika isinya memang kumpulan item sejenis. Jangan membungkus semua konten menjadi kartu identik.
- **Navigasi.** Maksimal sekitar 7 item, halaman aktif ditandai jelas, tersedia di posisi yang sama di semua halaman.
- **Tabel dan data.** Header jelas, angka rata kanan, ada empty state dan loading state.
- **Modal.** Fokus terkunci di dalamnya, `Esc` menutup, tombol tutup terlihat. Jika bisa inline, jangan pakai modal.
- **Ikon.** Satu set dengan gaya dan ketebalan garis seragam. Jangan pakai emoji sebagai ikon antarmuka.
- **Radius dan shadow.** Tentukan 2–3 level yang mengikuti hierarki, lalu konsisten. Elemen yang berbeda fungsi boleh berbeda radius; elemen sejenis tidak.

## 7. Aksesibilitas (batas minimum)

- HTML semantik: `header`, `nav`, `main`, `section`, `footer`, `button` untuk aksi, `a` untuk navigasi. Satu `h1` per halaman dan heading berurutan tanpa lompat level.
- `alt` pada gambar yang membawa informasi; `alt=""` pada gambar dekoratif.
- Fokus keyboard harus terlihat. Jangan menulis `outline: none` tanpa pengganti yang kontrasnya setara. Semua fungsi bisa dijalankan tanpa mouse.
- Halaman panjang menyediakan skip link ke konten utama.
- Hormati `prefers-reduced-motion`.
- Atur `lang` pada `<html>` sesuai bahasa konten (`lang="id"` untuk bahasa Indonesia).
- Pakai ARIA hanya jika HTML semantik tidak cukup. ARIA yang salah lebih buruk daripada tidak ada.
- Teks tautan harus bermakna sendiri ("Lihat daftar harga"), bukan "klik di sini".

## 8. Motion

Gerak yang tidak diminta pengguna menarik perhatian, jadi pakailah hemat.

- Gerak untuk merespons aksi (membuka, memperluas, konfirmasi) selalu boleh. Gerak otomatis dibatasi pada satu momen utama, misalnya satu urutan saat halaman dimuat.
- Durasi 150–250ms untuk interaksi kecil, maksimal sekitar 500ms untuk transisi besar. Easing `ease-out` untuk elemen masuk.
- Animasikan `transform` dan `opacity` saja, bukan `width`, `height`, atau `top`, supaya tetap mulus.
- Hindari pola bawaan yang langsung terbaca sebagai buatan AI: setiap section fade-in sambil naik, dan setiap kartu bergeser saat di-hover.

## 9. Copywriting

Teks adalah bagian dari desain. Setiap kata ada supaya orang lebih mudah mengerti dan menggunakan halaman.

- Bahasa konten mengikuti user dan audiensnya. Jika user menulis dalam bahasa Indonesia, isi halaman juga dalam bahasa Indonesia.
- Nama hal menurut pemahaman pengguna, bukan struktur teknis. Pengguna "mengatur notifikasi", bukan "mengubah konfigurasi webhook".
- Satu aksi, satu nama, di seluruh alur. Tombol "Publikasikan" menghasilkan pesan "Berhasil dipublikasikan".
- Error menjelaskan apa yang terjadi dan langkah perbaikannya, tanpa meminta maaf berlebihan. Halaman kosong mengajak bertindak.
- Gunakan format lokal untuk audiens Indonesia: Rp1.500.000, 4 November 2026, 24 jam.
- Jangan meninggalkan lorem ipsum di hasil akhir. Tulis konten contoh yang realistis untuk subjeknya.
- Jangan mengarang testimoni, angka statistik, nama klien, atau logo seolah-olah nyata. Jika perlu konten contoh, tandai jelas sebagai contoh dan beri tahu user.

## 10. Hindari tampilan generik

Ini pola yang paling cepat membuat halaman terlihat dibuat otomatis. Semuanya sah jika memang dipilih untuk brief tertentu, tetapi jangan dipakai sebagai default.

- Gradien ungu-biru, blob, dan hiasan yang tidak mewakili apa pun.
- Semua konten dipotong menjadi kartu identik dengan radius dan bayangan yang sama.
- Emoji sebagai ikon fitur.
- Label huruf kapital kecil di atas setiap judul.
- Satu kata di judul diberi warna atau miring sebagai "aksen".
- Penomoran 01 / 02 / 03 untuk konten yang sebenarnya bukan urutan.
- Hero dengan angka statistik besar dan gradien sebagai pembuka.

Sebagai gantinya, tentukan satu elemen yang menjadi ciri halaman ini dan biarkan sisanya tenang dan disiplin. Buang dekorasi yang tidak melayani tujuan halaman.

## Checklist sebelum menyerahkan

- [ ] Tidak ada nilai warna, ukuran, atau jarak yang ditulis langsung di komponen; semua dari token.
- [ ] Palet dan font dipilih berdasarkan subjek, bukan default.
- [ ] Kontras teks memenuhi 4.5:1 (3:1 untuk teks besar dan komponen UI).
- [ ] Layout diperiksa di lebar 360px, 768px, dan 1280px tanpa scroll horizontal.
- [ ] Setiap elemen interaktif punya state hover, fokus, dan disabled, serta bisa dioperasikan dengan keyboard.
- [ ] Ada tepat satu `h1`, heading berurutan, gambar punya `alt` yang sesuai.
- [ ] Motion minimal, dan `prefers-reduced-motion` dihormati.
- [ ] Tidak ada lorem ipsum dan tidak ada data karangan yang tampak asli.
- [ ] Hanya ada satu aksi utama yang menonjol di tiap layar.
- [ ] Aturan di `references/aturan-proyek.md` sudah dipenuhi.

## Cara melaporkan hasil

Setelah selesai, tulis ringkasan 2–4 kalimat: keputusan desain utama (palet, font, ide layout) dan asumsi yang diambil. Tidak perlu menjelaskan seluruh checklist. Jika ada aturan yang sengaja dilanggar karena permintaan user, sebutkan satu kalimat saja.
