// Кнопки «скопировать»: data-copy="текст" или data-copy-from="id элемента".
export function initCopy(text: Record<string, string>) {
  const toast = document.querySelector<HTMLElement>('.toast');
  let hide = 0;

  const say = (msg: string) => {
    if (!toast) return;
    toast.textContent = msg;
    toast.classList.add('is-on');
    clearTimeout(hide);
    hide = window.setTimeout(() => toast.classList.remove('is-on'), 1800);
  };

  const legacyCopy = (value: string) => {
    const ta = document.createElement('textarea');
    ta.value = value;
    ta.setAttribute('readonly', '');
    ta.style.position = 'fixed';
    ta.style.opacity = '0';
    document.body.appendChild(ta);
    ta.select();
    let ok = false;
    try { ok = document.execCommand('copy'); } catch { ok = false; }
    ta.remove();
    return ok;
  };

  document.addEventListener('click', async (e) => {
    const btn = (e.target as Element).closest<HTMLButtonElement>('[data-copy], [data-copy-from]');
    if (!btn) return;
    const from = btn.dataset.copyFrom;
    const value = from ? document.getElementById(from)?.textContent ?? '' : btn.dataset.copy ?? '';
    let ok = false;
    try {
      await navigator.clipboard.writeText(value);
      ok = true;
    } catch {
      ok = legacyCopy(value);
    }
    say(ok ? text.copied : text.copyFailed);
    if (ok) {
      btn.classList.add('is-done');
      setTimeout(() => btn.classList.remove('is-done'), 1500);
    }
  });
}
