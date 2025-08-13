// シンプルなローディング画面の制御
class LoadingScreen {
  constructor() {
    this.loadingScreen = document.getElementById('loading-screen');
  }

  // ローディング画面を非表示にする
  hide() {
    if (!this.loadingScreen) return;

    this.loadingScreen.style.opacity = '0';
    this.loadingScreen.style.transition = 'opacity 0.3s ease-out';

    setTimeout(() => {
      this.loadingScreen.style.display = 'none';
    }, 300);
  }

  // ローディング画面を表示する
  show() {
    if (!this.loadingScreen) return;

    this.loadingScreen.style.display = 'flex';
    this.loadingScreen.style.opacity = '1';
  }
}

// グローバルインスタンス
let loadingScreen;

// 初期化
function initializeLoadingScreen() {
  loadingScreen = new LoadingScreen();

  // ページ読み込み完了時にローディング画面を非表示
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      setTimeout(() => {
        loadingScreen.hide();
      }, 500);
    });
  } else {
    setTimeout(() => {
      loadingScreen.hide();
    }, 500);
  }
}

// Turbo対応
document.addEventListener('turbo:load', initializeLoadingScreen);
document.addEventListener('DOMContentLoaded', initializeLoadingScreen);

// ページ遷移時にローディング画面を表示
document.addEventListener('turbo:before-visit', () => {
  if (loadingScreen) {
    loadingScreen.show();
  }
});

// エクスポート
export { LoadingScreen, loadingScreen };
