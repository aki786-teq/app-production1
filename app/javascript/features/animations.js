import mojs from "@mojs/core";

// 応援ボタンのクリックアニメーション
export function setupCheerButtons() {
  // 実際の処理はクリックイベント委譲で行われるため、ここではセットアップ完了だけを示すことも可能
}

// 応援ボタンにburstアニメーションを再生
export function playCheerAnimation(cheerBtn) {
  if (!cheerBtn) return;

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

// Turboキャッシュ前にデータ属性をリセット
export function resetCheerButtons() {
  document.querySelectorAll("[id^='cheer-button-']").forEach((cheerBtn) => {
    delete cheerBtn.dataset.cheerSetup;
  });
}
