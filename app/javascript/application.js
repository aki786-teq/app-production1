import "@hotwired/turbo-rails"
import "./controllers"
import "./loading"
import mojs from "@mojs/core"

// グローバル変数でリスナー管理
let listenersAttached = false;

// ハンバーガーメニューの制御
function setupHamburgerMenu() {
  const hamburger = document.querySelector('.hamburger');
  const nav = document.querySelector('.nav');

  if (hamburger && nav) {
    // 既存のリスナーを削除してから新しいリスナーを追加
    const newHamburger = hamburger.cloneNode(true);
    hamburger.parentNode.replaceChild(newHamburger, hamburger);

    const finalHamburger = document.querySelector('.hamburger');

    finalHamburger.addEventListener('click', (e) => {
      e.preventDefault();
      e.stopPropagation();

      finalHamburger.classList.toggle('active');
      nav.classList.toggle('active');

      const isOpen = finalHamburger.classList.contains('active');
      finalHamburger.setAttribute('aria-expanded', isOpen);
      nav.setAttribute('aria-hidden', !isOpen);
    });
  }
}

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

// Turbo対応のイベントリスナー
document.addEventListener("turbo:load", () => {
  setupHamburgerMenu();
});
document.addEventListener("turbo:render", () => {
  initializeForm();
  setupHamburgerMenu();
});
document.addEventListener("turbo:before-cache", resetListeners);
document.addEventListener("turbo:before-visit", resetListeners);

// 初回読み込み対応
document.addEventListener("DOMContentLoaded", () => {
  initializeForm();
  setupHamburgerMenu();
});

// mojsで応援ボタンに効果
document.addEventListener("turbo:load", () => {
  setupCheerButtons();
});

// Turbo Stream後に確実にイベントリスナーを再設定
document.addEventListener("turbo:render", () => {
  setupCheerButtons();
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
  // 応援ボタンのクリックかチェック
  if (e.target.closest("[id^='cheer-button-']")) {
    const cheerBtn = e.target.closest("[id^='cheer-button-']");
    const method = cheerBtn.dataset.turboMethod;

    if (method === "post") {
      const rect = cheerBtn.getBoundingClientRect();

      const burst = new mojs.Burst({
        left: 0,
        top: 0,
        x: rect.left + rect.width / 2 + window.scrollX,
        y: rect.top + rect.height / 2 + window.scrollY,
        radius: { 0: 40 },
        count: 7,
        rotate: { 0: 90 },
        opacity: { 1: 0 },
        children: {
          shape: "circle",
          radius: 2,
          fill: "orangered",
          duration: 2000,
          easing: "cubic.out",
        },
      });

      burst.play();
    }
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

function setupCheerButtons() {
  // 実処理はイベント委譲に移行済み
  // console.debug("Cheer buttons setup completed");
}

// 応援ボタンのリスナー管理をリセット
document.addEventListener("turbo:before-cache", () => {
  document.querySelectorAll("[id^='cheer-button-']").forEach((cheerBtn) => {
    delete cheerBtn.dataset.cheerSetup;
  });
});