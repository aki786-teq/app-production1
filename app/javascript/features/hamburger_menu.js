// ハンバーガーメニューの制御
export function setupHamburgerMenu() {
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
