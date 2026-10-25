#!/usr/bin/env bash
# Hanafubuki — применить оформление и последние версии своих плагинов на сервере одной командой.
#
#   curl -fsSL https://raw.githubusercontent.com/Hanafubuki-minecraft/hanafubuki-brand/main/server/apply.sh | bash
#
# Сервер должен быть ОСТАНОВЛЕН (или FORCE=1 — только файлы, применится при следующем рестарте).
# Перед изменениями делается бэкап в ~/hanafubuki-backup-<дата>.tar.gz, хранятся 2 последних (KEEP_BACKUPS=N).
# Другой путь к серверу:  ... | SERVER=/путь/к/серверу bash
set -euo pipefail

SERVER="${SERVER:-$HOME/crafty-4/servers/48251565-7035-40e5-91b3-37a7fb4e83d9}"
P="$SERVER/plugins"
ORG="Hanafubuki-minecraft"
RAW="https://raw.githubusercontent.com/$ORG/hanafubuki-brand/main"

say()  { printf '\033[38;5;218m❀\033[0m %s\n' "$*"; }
warn() { printf '\033[38;5;210m!\033[0m %s\n' "$*"; }

[ -d "$P" ] || { warn "Не найдена папка плагинов: $P (укажи SERVER=...)"; exit 1; }

if pgrep -f "paper.*\.jar" >/dev/null 2>&1 && [ "${FORCE:-0}" != "1" ]; then
  warn "Похоже, сервер запущен. Останови его в Crafty и запусти скрипт снова (или FORCE=1, если уверен)."
  exit 1
fi

# ---------- бэкап ----------
BACKUP="$HOME/hanafubuki-backup-$(date +%F-%H%M%S).tar.gz"
tar czf "$BACKUP" -C "$SERVER" --ignore-failed-read \
  server.properties server-icon.png \
  plugins/Hanafubuki plugins/HanafubukiBlueMapMarkers plugins/HanafubukiResourceWorld \
  plugins/AuthMe/config.yml plugins/AuthMe/messages plugins/Geyser-Spigot/config.yml \
  plugins/PlaceholderAPI/config.yml 2>/dev/null || true
say "Бэкап: $BACKUP"
# храним только последние ${KEEP_BACKUPS:-2} бэкапа
ls -1t "$HOME"/hanafubuki-backup-*.tar.gz 2>/dev/null | tail -n +$(( ${KEEP_BACKUPS:-2} + 1 )) | xargs -r rm -f

# ---------- плагины: последние релизы ----------
latest_tag() {  # без GitHub API (у него лимит запросов): берём тег из редиректа /releases/latest
  curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$ORG/$1/releases/latest" | sed 's#.*/tag/##'
}

install_plugin() {  # $1 repo, $2 имя ассета ({v} = версия без «v»), $3 итоговое имя jar, $4 шаблон старых jar
  local tag ver asset
  tag=$(latest_tag "$1") || true
  [ -n "${tag:-}" ] || { warn "Не нашёл релиз $1"; return; }
  ver="${tag#v}"
  asset="${2//\{v\}/$ver}"
  rm -f "$P"/$4
  curl -fsSL -o "$P/$3" "https://github.com/$ORG/$1/releases/download/$tag/$asset"
  say "$1 $tag → plugins/$3"
}

install_plugin hanafubuki-core-plugin      "untitled-1.0-SNAPSHOT.jar"          "hanafubuki-core-plugin.jar"   "hanafubuki-core-plugin*.jar"
install_plugin hanafubuki-bluemap-markers  "HanafubukiBlueMapMarkers-{v}.jar"   "HanafubukiBlueMapMarkers.jar" "HanafubukiBlueMapMarkers*.jar"
install_plugin hanafubuki-resource-world   "HanafubukiResourceWorld-{v}.jar"    "HanafubukiResourceWorld.jar"  "HanafubukiResourceWorld*.jar"
install_plugin hanafubuki-discord-msg-sync "HanafubukiDiscordSync-{v}.jar"      "HanafubukiDiscordSync.jar"    "HanafubukiDiscordSync*.jar"

# старый мост (DiscordMsgSync с токеном внутри jar) убираем, только когда у нового указан токен —
# иначе чат в Discord пропал бы
DS_CFG="$P/HanafubukiDiscordSync/config.yml"
if ls "$P"/discord-msg-sync*.jar >/dev/null 2>&1; then
  if [ -f "$DS_CFG" ] && grep -Eq "^\s*token:\s*['\"]?[A-Za-z0-9_.-]{20,}" "$DS_CFG"; then
    rm -f "$P"/discord-msg-sync*.jar
    say "Старый DiscordMsgSync убран — работает HanafubukiDiscordSync"
  else
    warn "Новый мост поставлен, но токен ещё не задан: впиши discord.token и discord.channel-id в"
    warn "  $DS_CFG (появится после запуска сервера), затем прогони скрипт снова — он уберёт старый мост"
  fi
fi

# ---------- Vanilla Tweaks: конфетти-криперы заменены сакура-криперами из core ----------
for d in "$SERVER"/world/datapacks/confetti\ creepers*.zip; do
  [ -e "$d" ] && rm -f "$d" && say "Убран датапак: $(basename "$d") — вместо конфетти теперь сакура (core → sakura-creepers)"
done

# ---------- палитра: светлее приглушённый и тихий текст (старые значения по умолчанию → новые) ----------
for f in "$P/Hanafubuki/config.yml" "$P/HanafubukiBlueMapMarkers/config.yml" "$P/HanafubukiResourceWorld/config.yml"; do
  [ -f "$f" ] && sed -i 's/"#A99BB5"/"#C9BED3"/; s/"#6F6480"/"#9488A6"/' "$f"
done

# ---------- датапак hanafubuki-tweaks (репо Hanafubuki-minecraft/hanafubuki-tweaks) ----------
TW_TAG=$(latest_tag hanafubuki-tweaks) || true
if [ -n "${TW_TAG:-}" ]; then
  rm -rf "$SERVER/world/datapacks/hanafubuki-tweaks" "$SERVER"/world/datapacks/hanafubuki-tweaks*.zip
  curl -fsSL -o "$SERVER/world/datapacks/hanafubuki-tweaks.zip" \
    "https://github.com/$ORG/hanafubuki-tweaks/releases/download/$TW_TAG/hanafubuki-tweaks-${TW_TAG#v}.zip"
  say "hanafubuki-tweaks $TW_TAG → world/datapacks/hanafubuki-tweaks.zip"
fi

# ---------- Anti-Xray (Paper): руды прячутся, X-ray видит кашу ----------
PWD_CFG="$SERVER/config/paper-world-defaults.yml"
if [ -f "$PWD_CFG" ]; then
  python3 - "$PWD_CFG" << 'PY'
import re, sys
path = sys.argv[1]
lines = open(path, encoding="utf-8").read().split("\n")
stack = []
want = {"anticheat.anti-xray.enabled": "true", "anticheat.anti-xray.engine-mode": "2"}
done = set()
for i, line in enumerate(lines):
    m = re.match(r"^(\s*)([A-Za-z0-9_\-]+):\s*(.*)$", line)
    if not m:
        continue
    indent, key, val = len(m.group(1)), m.group(2), m.group(3).strip()
    while stack and stack[-1][0] >= indent:
        stack.pop()
    full = ".".join([k for _, k in stack] + [key])
    if val == "":
        stack.append((indent, key)); continue
    if full in want:
        lines[i] = " " * indent + key + ": " + want[full]; done.add(full)
open(path, "w", encoding="utf-8").write("\n".join(lines))
print("ok" if len(done) == len(want) else "missing: " + ", ".join(set(want) - done))
PY
  say "Anti-Xray включён (engine-mode 2)"
fi

# ---------- тексты своих плагинов: пересоздать в новом стиле, язык ru ----------
rm -f  "$P/Hanafubuki/messages.yml"
rm -rf "$P/HanafubukiBlueMapMarkers/lang" "$P/HanafubukiResourceWorld/lang"
for f in "$P/HanafubukiBlueMapMarkers/config.yml" "$P/HanafubukiResourceWorld/config.yml"; do
  [ -f "$f" ] && sed -i 's/^language: .*/language: ru/' "$f"
done
say "Тексты плагинов Hanafubuki сброшены — создадутся заново в новом стиле (русский)"

# ---------- AuthMe ----------
AM="$P/AuthMe/messages/messages_ru.yml"
if [ -f "$P/AuthMe/config.yml" ]; then
  sed -i 's/^\(\s*messagesLanguage:\).*/\1 ru/' "$P/AuthMe/config.yml"
  python3 - "$P/AuthMe/config.yml" << 'PY'
import re, sys
path = sys.argv[1]
lines = open(path, encoding="utf-8").read().split("\n")
stack = []
for i, line in enumerate(lines):
    m = re.match(r"^(\s*)([A-Za-z0-9_\-]+):\s*(.*)$", line)
    if not m:
        continue
    indent, key, val = len(m.group(1)), m.group(2), m.group(3).strip()
    while stack and stack[-1][0] >= indent:
        stack.pop()
    full = ".".join([k for _, k in stack] + [key])
    if val == "":
        stack.append((indent, key)); continue
    if full == "settings.registration.messageInterval":
        lines[i] = " " * indent + "messageInterval: 30"
open(path, "w", encoding="utf-8").write("\n".join(lines))
PY
fi
if [ -f "$AM" ]; then
  python3 - "$AM" << 'PY'
import re, sys
path = sys.argv[1]
lines = open(path, encoding="utf-8").read().split("\n")
section = None
out = []
for line in lines:
    m = re.match(r"^([A-Za-z0-9_]+):\s*$", line)
    if m:
        section = m.group(1)
    def setv(value):
        key = line.split(":", 1)[0]
        return f"{key}: '{value}'"
    s = line.strip()
    if section == "login" and s.startswith("success:"):
        line = setv("&d❀ &fДобро пожаловать на &dHanafubuki&f!")
    elif section == "registration" and s.startswith("success:"):
        line = setv("")  # после регистрации AuthMe сразу входит — приветствие придёт одно, от входа
    elif section == "session" and s.startswith("valid_session:"):
        line = setv("")
    elif s.startswith("success:") and "Bedrock" in s:
        line = setv("&d❀ &fДобро пожаловать на &dHanafubuki&f!")
    out.append(line)
# цвета сервера: тёмно-зелёный → зелёный, бирюзовые подсказки → приглушённый серый, голубой → белый
text = "\n".join(out).replace("&2", "&a").replace("&3", "&7").replace("&b", "&f")
open(path, "w", encoding="utf-8").write(text)
PY
  say "AuthMe: приветствия в стиле сервера, одно сообщение при входе"
else
  warn "AuthMe: $AM ещё не создан — запусти сервер один раз и прогони скрипт снова"
fi

# ---------- PlaceholderAPI: без уведомлений об обновлениях ----------
[ -f "$P/PlaceholderAPI/config.yml" ] && sed -i 's/^check_updates: true/check_updates: false/' "$P/PlaceholderAPI/config.yml"

# ---------- Geyser: имя сервера ----------
if [ -f "$P/Geyser-Spigot/config.yml" ]; then
  sed -i 's/^\(\s*server-name:\).*/\1 Hanafubuki/' "$P/Geyser-Spigot/config.yml"
  say "Geyser: имя сервера Hanafubuki"
fi

# ---------- описание (MOTD) и иконка ----------
python3 - "$SERVER/server.properties" << 'PY'
import sys
path = sys.argv[1]
# Две строки описания в списке серверов (Java; Bedrock получает его через Geyser)
motd = ("§d❀ §fHanafubuki §8· §7vanilla+\n"
        "§7Java §8& §7Bedrock §8· §dсакура, уют и долгая игра")
esc = "".join(c if 32 <= ord(c) < 127 else ("\\n" if c == "\n" else f"\\u{ord(c):04X}") for c in motd)
lines = open(path, encoding="latin-1").read().split("\n")
done = False
for i, l in enumerate(lines):
    if l.startswith("motd="):
        lines[i] = "motd=" + esc; done = True
if not done:
    lines.append("motd=" + esc)
open(path, "w", encoding="latin-1").write("\n".join(lines))
PY
curl -fsSL -o "$SERVER/server-icon.png" "$RAW/export/minecraft/server-icon.png"
say "Описание сервера и иконка обновлены"

echo
say "Готово. Запускай сервер в Crafty."
say "Если что-то пошло не так — откат: tar xzf $BACKUP -C \"$SERVER\""
