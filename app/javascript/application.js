import "@hotwired/turbo-rails"
import "./controllers"
import "./loading"
import { setupHamburgerMenu } from "./features/hamburger_menu"
import { setupCheerButtons, playCheerAnimation, resetCheerButtons } from "./features/animations"

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

  // ラジオボタンのchangeイベントリスナー
  newRadios.forEach(radio => {
    radio.addEventListener("change", updateSelection);
  });

  // 初期状態を更新
  updateSelection();
}

function initializeForm() {
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

// Turbo対応イベント
document.addEventListener("turbo:load", () => {
  setupHamburgerMenu();
  setupCheerButtons();
});
document.addEventListener("turbo:render", () => {
  initializeForm();
  setupHamburgerMenu();
  setupCheerButtons();
});
document.addEventListener("turbo:before-cache", () => {
  resetListeners();
  resetCheerButtons();
});
document.addEventListener("turbo:before-visit", resetListeners);

// 初回読み込み対応
document.addEventListener("DOMContentLoaded", () => {
  initializeForm();
  setupHamburgerMenu();
});

// イベント委譲を使用してより確実にイベントを捕捉
document.addEventListener("click", (e) => {
  // フォームのラベルクリックを確実に拾う（委譲）
  const choiceLabel = e.target.closest(".stretch-label, .level-label");
  if (choiceLabel) {
    const radioId = choiceLabel.getAttribute("for");
    const radio = document.getElementById(radioId);
    if (radio) {
      e.preventDefault();
      e.stopPropagation();
      // 標準clickでcheckedとイベントを確実に反映
      radio.click();
    }
    return;
  }
  // 応援ボタンのクリック
  const cheerBtn = e.target.closest("[id^='cheer-button-']");
  if (cheerBtn && cheerBtn.dataset.turboMethod === "post") {
    playCheerAnimation(cheerBtn);
  }

  // カード全体クリックで遷移（ネストリンク回避）
  const card = e.target.closest("[data-navigate-to]");
  if (card) {
    // 内部のリンクやボタンがクリックされた場合は何もしない
    if (e.target.closest("a, button, [role='button'], input, label")) return;
    const url = card.getAttribute("data-navigate-to");
    if (url) {
      e.preventDefault();
      if (window.Turbo && typeof Turbo.visit === "function") {
        Turbo.visit(url);
      } else {
        window.location.href = url;
      }
    }
  }
});
