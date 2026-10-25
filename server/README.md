# server/

Скрипт, который приводит сервер Hanafubuki к единому оформлению и ставит последние версии наших плагинов.

```bash
curl -fsSL https://raw.githubusercontent.com/Hanafubuki-minecraft/hanafubuki-brand/main/server/apply.sh | bash
```

Сервер должен быть остановлен. Скрипт:

- делает бэкап затронутых файлов в `~/hanafubuki-backup-<дата>.tar.gz`;
- ставит последние релизы `hanafubuki-core-plugin`, `hanafubuki-bluemap-markers`, `hanafubuki-resource-world`;
- пересоздаёт их тексты в стиле [`STYLE.md`](../STYLE.md) на русском;
- оформляет сообщения AuthMe о входе и оставляет одно приветствие;
- убирает датапак Vanilla Tweaks «Confetti Creepers» — его заменяют сакура-криперы из core;
- отключает уведомления PlaceholderAPI об обновлениях;
- ставит имя сервера в Geyser, описание (MOTD) и иконку из [`export/minecraft/server-icon.png`](../export/minecraft/server-icon.png).

Путь к серверу по умолчанию — Crafty на nixserver; другой: `... | SERVER=/путь bash`.
