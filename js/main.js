/**
 * EduLimbah - Main Application Script
 * (js/main.js)
 */

document.addEventListener("DOMContentLoaded", function () {
  // Highlight link navigasi aktif berdasarkan URL saat ini
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

  // Opsional: Perilaku eksklusif accordion jika ada beberapa details dalam satu grup
  const accordions = document.querySelectorAll("details.expandable-card");
  accordions.forEach((details) => {
    details.addEventListener("toggle", function () {
      if (details.open) {
        // Bisa diaktifkan jika ingin hanya 1 accordion terbuka sekaligus
      }
    });
  });
});

