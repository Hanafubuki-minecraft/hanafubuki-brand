#!/usr/bin/env bash
# Создаёт репозитории hanafubuki-site и hanafubuki-short в организации Hanafubuki-minecraft,
# пушит в них код из этой папки и включает GitHub Pages (Source: GitHub Actions + custom domain).
#
# Запуск (токен берётся только из окружения и никуда не записывается):
#   export GH_TOKEN=...        # fine-grained токен организации: Administration, Contents, Pages, Workflows — Read and write
#   bash web/publish.sh
#
# Повторный запуск безопасен: существующие репозитории не пересоздаются, код дописывается новым коммитом.
set -euo pipefail

ORG=Hanafubuki-minecraft
HERE="$(cd "$(dirname "$0")" && pwd)"
: "${GH_TOKEN:?Сначала export GH_TOKEN=...}"
command -v gh >/dev/null || { echo "Нужен GitHub CLI: https://cli.github.com"; exit 1; }

publish() {
  local repo="$1" dir="$2" domain="$3" desc="$4"
  echo "❀ $ORG/$repo"

  if gh api "repos/$ORG/$repo" >/dev/null 2>&1; then
    echo "  репозиторий уже есть"
  else
    gh api -X POST "orgs/$ORG/repos" -f name="$repo" -f description="$desc" -F private=false \
      -f homepage="https://$domain" >/dev/null
    echo "  репозиторий создан"
  fi

  local tmp; tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN
  git clone -q "https://x-access-token:${GH_TOKEN}@github.com/$ORG/$repo.git" "$tmp/repo" 2>/dev/null \
    || git init -q -b main "$tmp/repo"
  # Копируем содержимое папки (без node_modules и сборки).
  (cd "$dir" && tar --exclude=node_modules --exclude=dist --exclude=.astro -cf - .) | (cd "$tmp/repo" && tar -xf -)
  (
    cd "$tmp/repo"
    git checkout -q -B main
    git add -A
    if git diff --cached --quiet; then
      echo "  изменений нет"
    else
      git -c user.name="Hanafubuki" -c user.email="noreply@github.com" commit -q -m "Update site"
      git push -q "https://x-access-token:${GH_TOKEN}@github.com/$ORG/$repo.git" main 2>&1 | sed "s/${GH_TOKEN}/***/g"
      echo "  код запушен в main"
    fi
  )

  # GitHub Pages: источник — GitHub Actions.
  if gh api "repos/$ORG/$repo/pages" >/dev/null 2>&1; then
    gh api -X PUT "repos/$ORG/$repo/pages" -f build_type=workflow >/dev/null 2>&1 || true
  elif ! gh api -X POST "repos/$ORG/$repo/pages" -f build_type=workflow >/dev/null 2>&1; then
    echo "  ⚠ не получилось включить Pages через API — включи руками: Settings → Pages → Source: GitHub Actions"
    return
  fi
  if gh api -X PUT "repos/$ORG/$repo/pages" -f cname="$domain" >/dev/null 2>&1; then
    echo "  Pages включены, custom domain: $domain"
  else
    echo "  ⚠ домен не задан через API — Settings → Pages → Custom domain: $domain"
  fi
  # Enforce HTTPS доступен только после выпуска сертификата (обычно минуты — до суток после DNS-проверки).
  if gh api -X PUT "repos/$ORG/$repo/pages" -F https_enforced=true >/dev/null 2>&1; then
    echo "  Enforce HTTPS включён"
  else
    echo "  … Enforce HTTPS пока недоступен (сертификат ещё выпускается) — включи позже: Settings → Pages → Enforce HTTPS"
  fi
  # Если push был раньше включения Pages, первый деплой мог упасть — перезапускаем.
  gh workflow run deploy.yml -R "$ORG/$repo" --ref main >/dev/null 2>&1 && echo "  деплой запущен" || true
}

publish hanafubuki-site  "$HERE/hanafubuki-site"  hanafubuki.samedy.xyz "❀ Сайт Minecraft-сервера Hanafubuki"
publish hanafubuki-short "$HERE/hanafubuki-short" hf.samedy.xyz         "Короткая ссылка hf.samedy.xyz → hanafubuki.samedy.xyz"

echo
echo "Готово. Деплой: https://github.com/$ORG/hanafubuki-site/actions"
