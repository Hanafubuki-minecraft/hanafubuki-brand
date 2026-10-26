# Сайты Hanafubuki

Исходники двух репозиториев GitHub Pages. Здесь они лежат, пока репозитории не созданы; после публикации правки вносятся уже в сами репозитории.

| Папка | Репозиторий | Домен |
|---|---|---|
| [`hanafubuki-site/`](hanafubuki-site/) | `Hanafubuki-minecraft/hanafubuki-site` | https://hanafubuki.samedy.xyz |
| [`hanafubuki-short/`](hanafubuki-short/) | `Hanafubuki-minecraft/hanafubuki-short` | https://hf.samedy.xyz → редирект на сайт |

## Опубликовать

```bash
export GH_TOKEN=...          # токен организации; в файлы не сохраняется
bash web/publish.sh          # создаст оба репо, запушит код, включит Pages и домены
bash web/hanafubuki-site/check-dns.sh   # сверит DNS четырёх доменов
```

Права fine-grained токена (только для Hanafubuki-minecraft): Repository → Administration, Contents, Pages, Workflows — Read and write. Если Pages не включатся через API, скрипт скажет, что нажать руками.

DNS, деплой, «Дальше» и чек-лист — в [`hanafubuki-site/README.md`](hanafubuki-site/README.md).
