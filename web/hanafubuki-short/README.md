# ❀ hanafubuki-short

Короткая ссылка **https://hf.samedy.xyz** → **https://hanafubuki.samedy.xyz**.

GitHub Pages даёт один custom domain на репозиторий, поэтому редирект живёт отдельно от [сайта](https://github.com/Hanafubuki-minecraft/hanafubuki-site).

Редирект мгновенный и сохраняет путь, параметры и якорь: `hf.samedy.xyz/#rules` → `hanafubuki.samedy.xyz/#rules`. Работает через `location.replace` и запасной `<meta http-equiv="refresh">` (без JavaScript ведёт на главную). Любой несуществующий путь отдаёт `404.html` — копию `index.html`, которую workflow делает при деплое.

| Файл | Что |
|---|---|
| `site/index.html` | страница-редирект |
| `site/CNAME` | `hf.samedy.xyz` |
| `.github/workflows/deploy.yml` | деплой на Pages на каждый пуш в `main` |

## Настройка один раз

1. DNS: `hf` — CNAME → `hanafubuki-minecraft.github.io`, только DNS (серое облако).
2. Settings → Pages → Source: **GitHub Actions**.
3. Settings → Pages → Custom domain: `hf.samedy.xyz` → Save.
4. Когда сертификат выпустится — **Enforce HTTPS**.
