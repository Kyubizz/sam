/**
 * EduLimbah - Real 3D Two-Page Spread Book Flip Engine (Vanilla JS Murni)
 * Merakit elemen .page menjadi lembaran kertas 2 sisi (.book-sheet) yang
 * berputar 180 derajat melewati punggung buku (spine) seperti buku fisik.
 * (js/flipbook.js)
 */

document.addEventListener("DOMContentLoaded", function () {
  const bookElement = document.getElementById("demoBook");
  if (!bookElement) return;

  const rawPages = Array.from(bookElement.querySelectorAll(".page"));
  if (rawPages.length === 0) return;

  // Jika jumlah halaman ganjil atau hanya 4 halaman, tambahkan halaman pelengkap
  // agar terbentuk pasangan lembar 2 sisi yang utuh (Sampul Depan -> Isi Kiri/Kanan -> Sampul Belakang)
  const pageContents = rawPages.map((page) => ({
    html: page.innerHTML,
    isCover: page.classList.contains("cover")
  }));

  if (pageContents.length === 4) {
    // Sisipkan Halaman 3 (Langkah Pencegahan di Rumah) sebelum Kesimpulan, lalu tambahkan Sampul Belakang
    const conclusionPage = pageContents.pop();
    pageContents.push({
      isCover: false,
      html: `
        <div class="page-content">
          <div>
            <h3 class="page-title">Langkah Pencegahan di Rumah</h3>
            <p class="page-text">
              <strong>1. Sediakan Wadah Terpisah</strong><br>
              Gunakan botol plastik kaku bertutup ulir untuk jarum suntik dan kantong plastik berlapis untuk perban bekas luka.
              <br><br>
              <strong>2. Serahkan ke Faskes Resmi</strong><br>
              Jangan titipkan limbah medis ke gerobak sampah warga. Bawa ke Puskesmas atau RSUD yang memiliki TPS B3 berizin.
            </p>
          </div>
          <div class="page-number"><span>Halaman 3</span><span>EduLimbah</span></div>
        </div>
      `
    });
    pageContents.push(conclusionPage);
    pageContents.push({
      isCover: true,
      html: `
        <div class="page-content page-content-centered">
          <svg class="cover-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path>
            <path d="m9 12 2 2 4-4"></path>
          </svg>
          <h2 class="cover-title">Lindungi Keluarga & Lingkungan</h2>
          <p class="cover-subtitle">EduLimbah • Panduan Limbah B3 Medis</p>
        </div>
      `
    });
  } else if (pageContents.length % 2 !== 0) {
    pageContents.push({
      isCover: true,
      html: `
        <div class="page-content page-content-centered">
          <h2 class="cover-title">EduLimbah</h2>
          <p class="cover-subtitle"> Akhir Buku Panduan</p>
        </div>
      `
    });
  }

  const totalSheets = pageContents.length / 2;
  let currentSheet = 0; // 0 = tertutup depan, 1..totalSheets-1 = terbuka 2 halaman, totalSheets = tertutup belakang

  // Bangun panggung 3D buku (.book-stage) dan punggung buku (.book-spine)
  const stage = document.createElement("div");
  stage.className = "book-stage";
  stage.setAttribute("data-state", "closed-front");

  const spine = document.createElement("div");
  spine.className = "book-spine";
  spine.setAttribute("aria-hidden", "true");
  stage.appendChild(spine);

  const sheets = [];

  for (let i = 0; i < totalSheets; i++) {
    const frontData = pageContents[i * 2];
    const backData = pageContents[i * 2 + 1];

    const sheet = document.createElement("div");
    sheet.className = "book-sheet";
    sheet.dataset.sheetIndex = String(i);

    const frontFace = document.createElement("div");
    frontFace.className = "sheet-face sheet-front" + (frontData.isCover ? " cover" : "");
    frontFace.innerHTML = frontData.html;

    const backFace = document.createElement("div");
    backFace.className = "sheet-face sheet-back" + (backData.isCover ? " cover" : "");
    backFace.innerHTML = backData.html;

    sheet.appendChild(frontFace);
    sheet.appendChild(backFace);

    // Klik pada lembar kanan membalik maju; klik pada lembar kiri membalik mundur
    sheet.addEventListener("click", function (e) {
      e.stopPropagation();
      const isFlipped = sheet.classList.contains("is-flipped");
      if (!isFlipped) {
        goToSheet(i + 1);
      } else {
        goToSheet(i);
      }
    });

    sheets.push(sheet);
    stage.appendChild(sheet);
  }

  bookElement.innerHTML = "";
  bookElement.appendChild(stage);

  // Buat kontrol navigasi buku
  const controls = document.createElement("div");
  controls.className = "flipbook-controls";
  controls.innerHTML = `
    <button type="button" class="flip-nav-btn" id="prevPageBtn" aria-label="Balik ke lembar sebelumnya">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
        <polyline points="15 18 9 12 15 6"></polyline>
      </svg>
      <span>Sebelumnya</span>
    </button>
    <div class="flip-status">
      <span id="flipPageIndicator" aria-live="polite">Sampul Depan</span>
      <div class="flip-dots" id="flipDotsContainer"></div>
    </div>
    <button type="button" class="flip-nav-btn" id="nextPageBtn" aria-label="Buka lembar berikutnya">
      <span>Buka Lembar</span>
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
        <polyline points="9 18 15 12 9 6"></polyline>
      </svg>
    </button>
  `;

  bookElement.parentElement.appendChild(controls);

  const prevBtn = document.getElementById("prevPageBtn");
  const nextBtn = document.getElementById("nextPageBtn");
  const indicator = document.getElementById("flipPageIndicator");
  const dotsContainer = document.getElementById("flipDotsContainer");

  // Buat titik indikator bukaan buku (0 .. totalSheets)
  const dots = [];
  for (let s = 0; s <= totalSheets; s++) {
    const dot = document.createElement("button");
    dot.type = "button";
    dot.className = "flip-dot";
    dot.setAttribute("aria-label", `Buka tampilan buku ke-${s + 1}`);
    dot.addEventListener("click", (e) => {
      e.stopPropagation();
      goToSheet(s);
    });
    dotsContainer.appendChild(dot);
    dots.push(dot);
  }

  function updateBookState(turningIndex) {
    // Atur posisi panggung buku (tertutup depan, terbuka 2 halaman, atau tertutup belakang)
    if (currentSheet === 0) {
      stage.setAttribute("data-state", "closed-front");
    } else if (currentSheet === totalSheets) {
      stage.setAttribute("data-state", "closed-back");
    } else {
      stage.setAttribute("data-state", "open");
    }

    // Atur rotasi 3D dan urutan tumpukan (z-index) setiap lembar kertas
    sheets.forEach((sheet, idx) => {
      const isFlipped = idx < currentSheet;
      sheet.classList.toggle("is-flipped", isFlipped);

      if (idx === turningIndex) {
        // Lembar yang sedang melayang berputar selalu berada paling atas
        sheet.style.zIndex = String(totalSheets + 5);
      } else if (isFlipped) {
        // Tumpukan kiri: lembar yang baru dibalik berada di atas lembar sebelumnya
        sheet.style.zIndex = String(idx + 1);
      } else {
        // Tumpukan kanan: lembar paling awal berada paling atas
        sheet.style.zIndex = String(totalSheets - idx);
      }
    });

    // Setelah animasi selesai, rapikan z-index lembar yang baru berputar
    if (typeof turningIndex === "number") {
      setTimeout(() => {
        sheets.forEach((sheet, idx) => {
          const isFlipped = idx < currentSheet;
          sheet.style.zIndex = isFlipped
            ? String(idx + 1)
            : String(totalSheets - idx);
        });
      }, 450);
    }

    // Perbarui titik aktif
    dots.forEach((dot, idx) => {
      dot.classList.toggle("active", idx === currentSheet);
    });

    // Perbarui label status halaman
    if (indicator) {
      if (currentSheet === 0) {
        indicator.textContent = "Sampul Depan (Klik untuk Membuka)";
      } else if (currentSheet === totalSheets) {
        indicator.textContent = "Sampul Belakang";
      } else {
        const leftPageNum = currentSheet * 2 - 1;
        const rightPageNum = currentSheet * 2;
        indicator.textContent = `Terbuka: Hal. ${leftPageNum} & ${rightPageNum}`;
      }
    }

    if (prevBtn) prevBtn.disabled = currentSheet === 0;
    if (nextBtn) nextBtn.disabled = currentSheet === totalSheets;
  }

  function goToSheet(targetSheet) {
    if (targetSheet < 0 || targetSheet > totalSheets || targetSheet === currentSheet) return;
    const turningIndex = targetSheet > currentSheet ? currentSheet : targetSheet;
    currentSheet = targetSheet;
    updateBookState(turningIndex);
  }

  if (prevBtn) {
    prevBtn.addEventListener("click", function (e) {
      e.stopPropagation();
      goToSheet(currentSheet - 1);
    });
  }

  if (nextBtn) {
    nextBtn.addEventListener("click", function (e) {
      e.stopPropagation();
      goToSheet(currentSheet + 1);
    });
  }

  // Inisialisasi tampilan awal buku
  updateBookState();
});
