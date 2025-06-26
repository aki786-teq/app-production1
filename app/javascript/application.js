// application.js

import "@hotwired/turbo-rails"
import "./controllers"

function applySelection(groupSelector, labelClass) {
  const radios = document.querySelectorAll(`[data-role='${groupSelector}']`);
  const labels = document.querySelectorAll(`.${labelClass}`);

  function updateSelection() {
    labels.forEach(label => {
      const radioId = label.getAttribute("for");
      const radio = document.getElementById(radioId);
      if (!radio) return;

      const isChecked = radio.checked;

      // やった/やってない用の色付け
      if (groupSelector === "stretch-option") {
        if (isChecked) {
          if (label.textContent.includes("✕")) {
            label.classList.add("text-red-600");
            label.classList.remove("text-green-600");
          } else {
            label.classList.add("text-green-600");
            label.classList.remove("text-red-600");
          }
          label.classList.add("scale-110");
        } else {
          label.classList.remove("text-green-600", "text-red-600", "scale-110");
        }

        const icon = label.querySelector(".icon-circle");
        if (icon) {
          if (isChecked) {
            if (label.textContent.includes("✕")) {
              icon.classList.add("border-red-500");
              icon.classList.remove("border-green-500");
            } else {
              icon.classList.add("border-green-500");
              icon.classList.remove("border-red-500");
            }
          } else {
            icon.classList.remove("border-green-500", "border-red-500");
          }
        }
      }

      // 前屈レベル用の色付け
      if (groupSelector === "level-option") {
        if (isChecked) {
          label.classList.add("border-indigo-500", "border-4", "scale-105", "brightness-100");
          label.classList.remove("border-gray-300");
          const img = label.querySelector(".level-image");
          if (img) {
            img.classList.add("opacity-100");
            img.classList.remove("opacity-80");
          }
        } else {
          label.classList.remove("border-indigo-500", "border-4", "scale-105", "brightness-100");
          const img = label.querySelector(".level-image");
          if (img) {
            img.classList.remove("opacity-100");
            img.classList.add("opacity-80");
          }
        }
      }
    });
  }

  radios.forEach(radio => {
    radio.addEventListener("change", updateSelection);
  });

  updateSelection();
}

// Turbo対応
document.addEventListener("turbo:render", () => {
  applySelection("stretch-option", "stretch-label");
  applySelection("level-option", "level-label");
});
