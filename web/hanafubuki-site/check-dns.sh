#!/usr/bin/env bash
# Сверяет DNS-записи четырёх доменов Hanafubuki с нужными. Нужен dig (пакет dnsutils / bind-tools).
# Запуск: bash check-dns.sh
set -u
IP=91.214.31.132
PAGES=hanafubuki-minecraft.github.io.
ok=0

check_cname() {
  local name="$1" got
  got="$(dig +short "$name" CNAME @1.1.1.1 | tr 'A-Z' 'a-z')"
  if [ "$got" = "$PAGES" ]; then echo "✓ $name CNAME → $got"
  else echo "✗ $name: нужен CNAME → ${PAGES%.} (только DNS, серое облако), сейчас: ${got:-нет CNAME; A: $(dig +short "$name" A @1.1.1.1 | tr '\n' ' ')}"; ok=1; fi
}
check_a() {
  local name="$1" got
  got="$(dig +short "$name" A @1.1.1.1 | tr '\n' ' ' | sed 's/ $//')"
  if [ "$got" = "$IP" ]; then echo "✓ $name A → $got"
  else echo "✗ $name: нужна A-запись → $IP (только DNS, без прокси Cloudflare), сейчас: ${got:-нет}"; ok=1; fi
}

check_cname hanafubuki.samedy.xyz
check_cname hf.samedy.xyz
check_a     mc.samedy.xyz
check_a     map.hanafubuki.samedy.xyz
exit $ok
