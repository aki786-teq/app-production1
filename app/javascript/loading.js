// シンプルなローディング画面の制御
const MIN_DISPLAY_MS = 400; // ローディングの最小表示時間（ms）

class LoadingScreen {
  constructor() {
    this.loadingScreen = document.getElementById('loading-screen');
    this.lastShowAt = 0;
    this.hideDelayTimerId = null;
    this.fadeTimerId = null;
  }

  // ローディング画面を非表示にする（最小表示時間を考慮）
  hide() {
    if (!this.loadingScreen) return;

    // 既存タイマーをクリア
    if (this.hideDelayTimerId) {
      clearTimeout(this.hideDelayTimerId);
      this.hideDelayTimerId = null;
    }
    if (this.fadeTimerId) {
      clearTimeout(this.fadeTimerId);
      this.fadeTimerId = null;
    }

    // 初回（lastShowAtが0）のときは従来どおり即フェードアウト
    if (this.lastShowAt === 0) {
      this.loadingScreen.style.pointerEvents = 'none';
      this.loadingScreen.style.opacity = '0';
      this.loadingScreen.style.transition = 'opacity 0.3s ease-out';
      this.fadeTimerId = setTimeout(() => {
        if (!this.loadingScreen) return;
        this.loadingScreen.style.display = 'none';
      }, 300);
      return;
    }

    const elapsed = Date.now() - this.lastShowAt;
    const wait = Math.max(0, MIN_DISPLAY_MS - elapsed);

    // クリックブロックを即時解除（見た目はwait後にフェードアウト）
    this.loadingScreen.style.pointerEvents = 'none';

    this.hideDelayTimerId = setTimeout(() => {
      if (!this.loadingScreen) return;
      this.loadingScreen.style.opacity = '0';
      this.loadingScreen.style.transition = 'opacity 0.3s ease-out';
      this.fadeTimerId = setTimeout(() => {
        if (!this.loadingScreen) return;
        this.loadingScreen.style.display = 'none';
      }, 300);
    }, wait);
  }

  // ローディング画面を表示する
  show() {
    if (!this.loadingScreen) return;

    // 表示前に既存タイマーをクリアしてブレを防ぐ
    if (this.hideDelayTimerId) {
      clearTimeout(this.hideDelayTimerId);
      this.hideDelayTimerId = null;
    }
    if (this.fadeTimerId) {
      clearTimeout(this.fadeTimerId);
      this.fadeTimerId = null;
    }

    this.loadingScreen.style.display = 'flex';
    this.loadingScreen.style.pointerEvents = 'auto';
    this.loadingScreen.style.opacity = '1';
    this.loadingScreen.style.transition = 'opacity 0.3s ease-out';
    this.lastShowAt = Date.now();
  }
}

// グローバルインスタンス
let loadingScreen;

// 初期化
function initializeLoadingScreen() {
  // 既存インスタンスがあれば再利用し、要素参照のみ更新
  if (loadingScreen) {
    const el = document.getElementById('loading-screen');
    if (loadingScreen.loadingScreen !== el) {
      loadingScreen.loadingScreen = el;
    }
  } else {
    loadingScreen = new LoadingScreen();
  }

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
document.addEventListener('turbo:load', () => {
  initializeLoadingScreen();
});
// TurboがDOMを書き換えた直後にも参照を再取得して非表示を保証
document.addEventListener('turbo:render', () => {
  initializeLoadingScreen();
  if (loadingScreen) loadingScreen.hide();
});
document.addEventListener('DOMContentLoaded', initializeLoadingScreen);

// ページ遷移時にローディング画面を表示
document.addEventListener('turbo:before-visit', () => {
  if (loadingScreen) {
    loadingScreen.show();
  }
});

// フォーム送信終了時にローディングを必ず非表示（成功/失敗に関わらず）
document.addEventListener('turbo:submit-end', () => {
  try { if (loadingScreen) loadingScreen.hide(); } catch (_) {}
});

// Turboリクエスト終了時にも非表示（422等の異常含む）
document.addEventListener('turbo:request-end', () => {
  try { if (loadingScreen) loadingScreen.hide(); } catch (_) {}
});

// bfcache復帰時にも非表示
window.addEventListener('pageshow', () => {
  try { if (loadingScreen) loadingScreen.hide(); } catch (_) {}
});

// エクスポート
export { LoadingScreen, loadingScreen };
