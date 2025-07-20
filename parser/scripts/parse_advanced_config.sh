
#!/bin/bash
# parse_advanced_config.sh

config_file="config.json"
input_csv="input.csv"
output_csv="output.csv"

# Проверка зависимостей
command -v jq >/dev/null 2>&1 || { 
    echo >&2 "Установите jq: brew install jq"
    exit 1
}

[ -f "$config_file" ] || { echo "Файл $config_file не найден"; exit 1; }
[ -f "$input_csv" ] || { echo "Файл $input_csv не найден"; exit 1; }

# Извлечение параметров (без ассоциативных массивов)
chip=$(jq -r '.chip_number' "$config_file")
analyte=$(jq -r '.analyte' "$config_file")
date=$(jq -r '.date' "$config_file")
temp=$(jq -r '.temperature' "$config_file")
humidity=$(jq -r '.humidity' "$config_file")

# Проверка параметров
[ -z "$chip" ] && { echo "Ошибка: chip_number"; exit 1; }
[ -z "$analyte" ] && { echo "Ошибка: analyte"; exit 1; }
[ -z "$date" ] && { echo "Ошибка: date"; exit 1; }
[ -z "$temp" ] && { echo "Ошибка: temperature"; exit 1; }
[ -z "$humidity" ] && { echo "Ошибка: humidity"; exit 1; }

# Запуск обработки
gawk -v chip="$chip" \
    -v analyte="$analyte" \
    -v date="$date" \
    -v temp="$temp" \
    -v humidity="$humidity" \
    -f advanced_script.awk "$input_csv" > "$output_csv"

echo "Анализ завершен. Результаты в $output_csv"

