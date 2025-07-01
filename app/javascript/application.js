// application.js

import "@hotwired/turbo-rails"
import "./controllers"

// グローバル変数でリスナー管理
let listenersAttached = false;

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
              icon.classList.remove("border-green-500", "border-stone-300");
            } else {
              icon.classList.add("border-green-500");
              icon.classList.remove("border-red-500", "border-stone-300");
            }
          } else {
            icon.classList.remove("border-green-500", "border-red-500");
            icon.classList.add("border-stone-300");
          }
        }
      }

      // 前屈レベル用の色付け
      if (groupSelector === "level-option") {
        if (isChecked) {
          label.classList.add("border-orange-500", "border-2", "scale-105", "brightness-100");
        } else {
          label.classList.remove("border-orange-500", "border-2", "scale-105", "brightness-100");
        }
      }
    });
  }

  // 既存のリスナーを削除してから新しいリスナーを追加
  radios.forEach(radio => {
    // 既存のリスナーをクローンで削除
    const newRadio = radio.cloneNode(true);
    radio.parentNode.replaceChild(newRadio, radio);
  });

  // 新しい要素を再取得
  const newRadios = document.querySelectorAll(`[data-role='${groupSelector}']`);
  const newLabels = document.querySelectorAll(`.${labelClass}`);

  // ラベルクリックでの選択解除機能を追加
  newLabels.forEach(label => {
    label.addEventListener("click", (e) => {
      const radioId = label.getAttribute("for");
      const radio = document.getElementById(radioId);
      if (!radio) return;

      // 既に選択されている場合は選択解除
      if (radio.checked) {
        e.preventDefault();
        radio.checked = false;
        // changeイベントを手動で発火
        radio.dispatchEvent(new Event('change', { bubbles: true }));
      }
    });
  });

  // ラジオボタンのchangeイベントリスナー
  newRadios.forEach(radio => {
    radio.addEventListener("change", updateSelection);
  });

  // 初期状態を更新
  updateSelection();
}

function initializeForm() {
  // 二重初期化を防ぐ
  if (listenersAttached) {
    return;
  }

  try {
    applySelection("stretch-option", "stretch-label");
    applySelection("level-option", "level-label");
    listenersAttached = true;
  } catch (error) {
    console.error("フォーム初期化エラー:", error);
    listenersAttached = false;
  }
}

function resetListeners() {
  listenersAttached = false;
}

// Turbo対応のイベントリスナー
document.addEventListener("turbo:load", initializeForm);
document.addEventListener("turbo:render", initializeForm);
document.addEventListener("turbo:before-cache", resetListeners);
document.addEventListener("turbo:before-visit", resetListeners);

// 初回読み込み対応
document.addEventListener("DOMContentLoaded", initializeForm);