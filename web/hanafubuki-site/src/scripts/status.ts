// Живой статус сервера через api.mcsrvstat.us.
// Результат кэшируется в памяти; обновление — раз в refreshSeconds, пока вкладка открыта.
// Любая ошибка сети тихо превращается в «Не удалось узнать» — без сообщений в консоли.

interface StatusConfig { javaApi: string; bedrockApi: string; refreshSeconds: number }
interface Result { state: 'online' | 'offline' | 'unknown'; players?: string; version?: string }

const cache = new Map<string, { at: number; result: Result }>();

async function fetchStatus(url: string, maxAgeMs: number): Promise<Result> {
  const hit = cache.get(url);
  if (hit && Date.now() - hit.at < maxAgeMs) return hit.result;

  let result: Result = { state: 'unknown' };
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), 8000);
  try {
    const res = await fetch(url, { signal: ctrl.signal, cache: 'no-store' });
    if (res.ok) {
      const d = await res.json();
      if (d && d.online === true) {
        const online = d.players?.online;
        const max = d.players?.max;
        result = {
          state: 'online',
          players: typeof online === 'number' ? (typeof max === 'number' ? `${online} / ${max}` : String(online)) : undefined,
          version: typeof d.version === 'string' ? d.version.replace(/§./g, '').trim().slice(0, 40) : undefined,
        };
      } else if (d && d.online === false) {
        result = { state: 'offline' };
      }
    }
  } catch {
    /* сеть, таймаут или CORS — показываем «не удалось узнать» */
  } finally {
    clearTimeout(timer);
  }
  cache.set(url, { at: Date.now(), result });
  return result;
}

export function startStatus(cfg: StatusConfig, text: Record<string, string>) {
  const cards = {
    java: document.querySelector<HTMLElement>('[data-status="java"]'),
    bedrock: document.querySelector<HTMLElement>('[data-status="bedrock"]'),
  };
  const period = Math.max(30, cfg.refreshSeconds) * 1000;

  const render = (card: HTMLElement | null, r: Result) => {
    if (!card) return;
    card.dataset.state = r.state;
    card.querySelector('.status__state')!.textContent = text[r.state];
    card.querySelector('[data-field="players"]')!.textContent = r.players ?? '—';
    card.querySelector('[data-field="version"]')!.textContent = r.version ?? '—';
  };

  const refresh = async () => {
    const [j, b] = await Promise.all([
      fetchStatus(cfg.javaApi, period - 1000),
      fetchStatus(cfg.bedrockApi, period - 1000),
    ]);
    render(cards.java, j);
    render(cards.bedrock, b);
  };

  let timer = 0;
  const schedule = () => {
    clearInterval(timer);
    if (!document.hidden) {
      refresh();
      timer = window.setInterval(refresh, period);
    }
  };
  document.addEventListener('visibilitychange', schedule);
  schedule();
}
