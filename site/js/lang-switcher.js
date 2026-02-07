const LANGS = ['en', 'hr'];
const langPattern = new RegExp(`^/(${LANGS.slice(1).join('|')})(/|$)`);
const currentLang = document.documentElement.lang;

document.querySelectorAll('.lang-link').forEach(link => {
  const lang = link.dataset.lang;
  const path = location.pathname.replace(langPattern, '/') || '/';
  link.href = lang === 'en' ? path : '/' + lang + path;
  if (lang === currentLang) link.classList.add('selected');

  link.onclick = async (e) => {
    e.preventDefault();
    const res = await fetch(link.href, { method: 'HEAD' });
    if (res.ok) {
      location.href = link.href;
    } else {
      showToast(`Page not available in selected language "${lang}".`);
    }
  };
});

document.querySelectorAll('.lang-label').forEach(label => {
  label.hidden = label.dataset.lang !== currentLang;
});

function showToast(msg) {
  const toast = document.createElement('div');
  toast.className = 'toast toast-bottom toast-center';
  toast.innerHTML = `<div class="alert alert-info"><span>${msg}</span></div>`;
  document.body.appendChild(toast);
  setTimeout(() => toast.remove(), 3000);
}
