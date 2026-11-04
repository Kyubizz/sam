/**
 * EduLimbah - StPageFlip Initialization
 * (js/flipbook.js)
 */

document.addEventListener("DOMContentLoaded", function () {
  const flipbookWrapper = document.getElementById("flipbookWrapper");
  const bookElement = document.getElementById("demoBook");
  let isBookInitialized = false;

  function initPageFlip() {
    if (isBookInitialized || !bookElement) return;

    if (typeof St !== "undefined" && typeof St.PageFlip !== "undefined") {
      try {
        const pageFlip = new St.PageFlip(bookElement, {
          width: 310,
          height: 420,
          size: "fixed",
          minWidth: 280,
          maxWidth: 400,
          minHeight: 400,
          maxHeight: 500,
          maxShadowOpacity: 0.2,
          showCover: true,
          mobileScrollSupport: false,
          usePortrait: true, // Tampilkan 1 halaman agar konsisten & rapi
        });

        // Muat halaman buku dari elemen HTML
        pageFlip.loadFromHTML(bookElement.querySelectorAll(".page"));

        // Tampilkan elemen buku setelah siap
        bookElement.style.display = "block";
        isBookInitialized = true;
      } catch (err) {
        console.error("Gagal menginisialisasi StPageFlip:", err);
      }
    } else {
      console.warn("Library StPageFlip belum selesai dimuat.");
    }
  }

  if (flipbookWrapper) {
    // Inisialisasi saat kartu accordion dibuka
    flipbookWrapper.addEventListener("toggle", function () {
      if (flipbookWrapper.open && !isBookInitialized) {
        initPageFlip();
      }
    });

    // Jika sudah terbuka secara default
    if (flipbookWrapper.open) {
      initPageFlip();
    }
  } else if (bookElement) {
    // Jika elemen ada di luar accordion
    initPageFlip();
  }
});

