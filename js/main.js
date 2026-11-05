/**
 * EduLimbah - Main Application Script (Vanilla JS Murni)
 * (js/main.js)
 */

(function initThemeImmediate() {
  const savedTheme = localStorage.getItem("edulimbah-theme") || "neon";
  if (savedTheme === "light") {
    document.documentElement.setAttribute("data-theme", "light");
  } else {
    document.documentElement.removeAttribute("data-theme");
  }
})();

document.addEventListener("DOMContentLoaded", function () {
  // 1. Tandai tautan navigasi aktif pada Floating Glass Dock
  const currentPath = window.location.pathname.split("/").pop() || "index.html";
  const navLinks = document.querySelectorAll(".nav-links a");

  navLinks.forEach((link) => {
    const href = link.getAttribute("href");
    if (href === currentPath || (currentPath === "" && href === "index.html")) {
      link.classList.add("active");
      link.setAttribute("aria-current", "page");
    } else {
      link.classList.remove("active");
      link.removeAttribute("aria-current");
    }
  });

  // 2. Tombol Ganti Tema (Mode Neon Gelap vs Mode Mint Terang Portal Kesehatan)
  const navInner = document.querySelector(".nav-inner");
  if (navInner && !document.getElementById("themeToggleBtn")) {
    const toggleBtn = document.createElement("button");
    toggleBtn.id = "themeToggleBtn";
    toggleBtn.type = "button";
    toggleBtn.className = "theme-toggle-btn";

    function updateToggleAppearance() {
      const isLight = document.documentElement.getAttribute("data-theme") === "light";
      if (isLight) {
        toggleBtn.setAttribute("aria-label", "Aktifkan tampilan mode neon gelap");
        toggleBtn.innerHTML = `
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path>
          </svg>
          <span>Mode Neon</span>
        `;
      } else {
        toggleBtn.setAttribute("aria-label", "Aktifkan tampilan mode mint terang");
        toggleBtn.innerHTML = `
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <circle cx="12" cy="12" r="5"></circle>
            <line x1="12" y1="1" x2="12" y2="3"></line>
            <line x1="12" y1="21" x2="12" y2="23"></line>
            <line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line>
            <line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line>
            <line x1="1" y1="12" x2="3" y2="12"></line>
            <line x1="21" y1="12" x2="23" y2="12"></line>
            <line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line>
            <line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line>
          </svg>
          <span>Mode Mint Terang</span>
        `;
      }
    }

    updateToggleAppearance();

    toggleBtn.addEventListener("click", function () {
      const isLight = document.documentElement.getAttribute("data-theme") === "light";
      if (isLight) {
        document.documentElement.removeAttribute("data-theme");
        localStorage.setItem("edulimbah-theme", "neon");
      } else {
        document.documentElement.setAttribute("data-theme", "light");
        localStorage.setItem("edulimbah-theme", "light");
      }
      updateToggleAppearance();
    });

    navInner.appendChild(toggleBtn);
  }

  // 3. Alat Interaktif Pembuka: Cek Cepat Wadah Limbah Medis
  const chipButtons = document.querySelectorAll(".chip-btn[data-waste]");
  const resultBox = document.getElementById("quickCheckerResult");

  const wasteData = {
    jarum: {
      title: "Jarum Suntik, Spuit, dan Lancet",
      badge: "Safety Box (Anti-Tusuk)",
      badgeClass: "tag-red",
      borderColor: "var(--color-waste-red)",
      desc: "Masukkan langsung tanpa menutup ulang jarum ke dalam Safety Box atau botol plastik kaku bertutup ulir hingga batas maksimal 3/4 penuh."
    },
    perban: {
      title: "Perban Berdarah dan Kapas Luka",
      badge: "Kantong Kuning (Infeksius)",
      badgeClass: "tag-yellow",
      borderColor: "var(--color-waste-yellow)",
      desc: "Gunakan sarung tangan sekali pakai, masukkan ke kantong kuning atau plastik dua lapis (double bag), semprot disinfektan, lalu ikat leher angsa."
    },
    obat: {
      title: "Tablet, Kapsul, atau Sirup Kedaluwarsa",
      badge: "Kantong Cokelat (Farmasi)",
      badgeClass: "tag-brown",
      borderColor: "var(--color-waste-brown)",
      desc: "Keluarkan dari kemasan, gerus tablet dan campur dengan tanah atau ampas kopi dalam wadah tertutup. Gunting kemasan dan coret nama pasien."
    },
    masker: {
      title: "Masker dan Sarung Tangan Pasien Infeksius",
      badge: "Kantong Kuning (Infeksius)",
      badgeClass: "tag-yellow",
      borderColor: "var(--color-waste-yellow)",
      desc: "Gunting tali masker agar tidak disalahgunakan kembali, semprot cairan disinfektan, dan satukan di dalam kantong limbah infeksius tertutup rapat."
    },
    ampul: {
      title: "Pecahan Kaca Ampul dan Vial Obat",
      badge: "Safety Box (Benda Tajam)",
      badgeClass: "tag-red",
      borderColor: "var(--color-waste-red)",
      desc: "Jangan dipungut dengan tangan kosong. Masukkan pecahan kaca medis ke dalam wadah kaku tahan tusuk (Safety Box) bersama limbah benda tajam."
    },
    kardus: {
      title: "Kardus Obat dan Bungkus Spuit Bersih",
      badge: "Kantong Hitam (Domestik)",
      badgeClass: "tag-black",
      borderColor: "var(--color-waste-black)",
      desc: "Kemasan kertas atau plastik yang tidak terkontaminasi cairan tubuh termasuk limbah domestik. Rusak label kemasan sebelum dibuang ke kantong hitam."
    }
  };

  if (chipButtons.length > 0 && resultBox) {
    chipButtons.forEach((btn) => {
      btn.addEventListener("click", function () {
        chipButtons.forEach((b) => b.classList.remove("active"));
        btn.classList.add("active");

        const key = btn.getAttribute("data-waste");
        const info = wasteData[key];
        if (info) {
          resultBox.style.borderLeftColor = info.borderColor;
          resultBox.innerHTML = `
            <span class="tag ${info.badgeClass}">${info.badge}</span>
            <strong>${info.title}</strong>
            <p>${info.desc}</p>
          `;
        }
      });
    });
  }

  // 4. Filter Tab Interaktif pada Modul Praktik & Buku Digital
  const filterTabs = document.querySelectorAll(".filter-tab-btn[data-filter]");
  const moduleCards = document.querySelectorAll(".expandable-card[data-category]");

  if (filterTabs.length > 0 && moduleCards.length > 0) {
    filterTabs.forEach((tab) => {
      tab.addEventListener("click", function () {
        filterTabs.forEach((t) => t.classList.remove("active"));
        tab.classList.add("active");

        const targetCat = tab.getAttribute("data-filter");
        moduleCards.forEach((card) => {
          const cardCat = card.getAttribute("data-category");
          if (targetCat === "all" || cardCat === targetCat) {
            card.removeAttribute("hidden");
            if (targetCat !== "all") {
              card.setAttribute("open", "");
            }
          } else {
            card.setAttribute("hidden", "");
          }
        });
      });
    });
  }
});
