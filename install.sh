#!/bin/ash

# Установщик Domain Catcher для OpenWrt / BusyBox ash.
# Скачивает основной скрипт в /usr/bin/dcatch и сразу запускает его.

SCRIPT_URL="${SCRIPT_URL:-https://raw.githubusercontent.com/doxfie/Domain-Catcher/main/domain-catcher.sh}"
TARGET="${TARGET:-/usr/bin/dcatch}"
EOF_MARK="# DCATCH-EOF"

echo "Domain Catcher installer"
echo "Скачиваю скрипт:"
echo "$SCRIPT_URL"
echo

if ! command -v wget >/dev/null 2>&1; then
	echo "Ошибка: wget не найден."
	echo "Установите wget или скачайте domain-catcher.sh вручную."
	exit 1
fi

fail() {
	echo "Ошибка: $1"
	rm -f "$NEW_FILE"
	exit 1
}

# Качаем рядом с целевым файлом и подменяем переименованием: прямая запись
# в "$TARGET" при обрыве связи оставила бы обрезанный исполняемый файл вместо
# рабочей установки, а mv в пределах одной ФС атомарен.
NEW_FILE="$(dirname "$TARGET")/.dcatch.new"
rm -f "$NEW_FILE"

wget -O "$NEW_FILE" "$SCRIPT_URL" || fail "не удалось скачать скрипт."

# Порог по размеру отсеивает страницы с ошибкой, маркер конца файла - обрыв
# закачки: без него обрубок на любых 16-94% проходил все проверки.
head -n 1 "$NEW_FILE" | grep -q '^#!/bin/ash' || fail "скачанный файл не похож на скрипт."
[ "$(wc -c < "$NEW_FILE")" -ge 10000 ] || fail "скачанный файл слишком мал."
tail -n 1 "$NEW_FILE" | grep -qx "$EOF_MARK" || fail "закачка оборвалась, файл неполный."

chmod +x "$NEW_FILE" || fail "не удалось сделать скрипт исполняемым."
mv "$NEW_FILE" "$TARGET" || fail "не удалось установить скрипт в $TARGET"

echo
echo "Скрипт установлен: $TARGET"
echo "Повторный запуск: dcatch"
echo "Запускаю..."
echo

[ -t 0 ] && exec "$TARGET"
[ -c /dev/tty ] && exec "$TARGET" < /dev/tty

echo "Интерактивный ввод недоступен."
echo "Запустите скрипт вручную: dcatch"
