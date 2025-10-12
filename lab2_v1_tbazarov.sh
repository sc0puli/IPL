#!/bin/bash

# Функция для вывода справки
show_help() {
    cat << EOF
Использование: $(basename "$0") [ОПЦИИ] ПУТЬ_К_ДИРЕКТОРИИ

Анализирует Verilog-файлы в указанной директории и предоставляет статистику по модулям.

Обязательные аргументы:
  ПУТЬ_К_ДИРЕКТОРИИ    Директория для анализа

Опции:
  -h, --help          Показать эту справку и выйти
  -v, --verbose       Включить подробный вывод

Примеры:
  $(basename "$0") /path/to/sg13g2_Verilog
  $(basename "$0") -v /path/to/sg13g2_Verilog
EOF
}

# Функция для вывода ошибок
error_exit() {
    echo "Ошибка: $1" >&2
    exit 1
}

# Функция для проверки существования директории
validate_directory() {
    local dir_path="$1"
    
    if [ ! -e "$dir_path" ]; then
        error_exit "Путь '$dir_path' не существует."
    fi
    
    if [ ! -d "$dir_path" ]; then
        error_exit "'$dir_path' не является директорией."
    fi
    
    if [ ! -r "$dir_path" ]; then
        error_exit "Нет прав на чтение директории '$dir_path'."
    fi
}

# Функция для извлечения имен модулей из Verilog-файла
extract_modules() {
    local verilog_file="$1"
    
    # Извлекаем имена модулей с помощью регулярного выражения
    # Учитываем различные варианты объявления модулей
    grep -E "^\s*module\s+\w+" "$verilog_file" | \
    sed -E 's/^\s*module\s+([[:alnum:]_]+).*/\1/'
}

# Обработка аргументов командной строки
VERBOSE=false
TARGET_DIR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -*)
            error_exit "Неизвестная опция: $1"
            ;;
        *)
            if [ -z "$TARGET_DIR" ]; then
                TARGET_DIR="$1"
                shift
            else
                error_exit "Слишком много аргументов. Используйте --help для справки."
            fi
            ;;
    esac
done

# Проверка наличия обязательного аргумента
if [ -z "$TARGET_DIR" ]; then
    error_exit "Не указана целевая директория. Используйте --help для справки."
fi

# Проверка валидности директории
validate_directory "$TARGET_DIR"

if [ "$VERBOSE" = true ]; then
    echo "Анализ директории: $TARGET_DIR"
    echo "Поиск Verilog-файлов..."
fi

# Поиск всех Verilog-файлов в директории и поддиректориях
VERILOG_FILES=$(find "$TARGET_DIR" -type f -name "*.v" 2>/dev/null)

if [ -z "$VERILOG_FILES" ]; then
    error_exit "В указанной директории не найдено Verilog-файлов (*.v)."
fi

if [ "$VERBOSE" = true ]; then
    echo "Найдено $(echo "$VERILOG_FILES" | wc -l) Verilog-файлов."
    echo "Извлечение имен модулей..."
fi

# Временные файлы для результатов
ALL_MODULES_FILE=$(mktemp)
RM_MODULES_FILE=$(mktemp)

# Обработка каждого Verilog-файла
while IFS= read -r verilog_file; do
    if [ "$VERBOSE" = true ]; then
        echo "Обработка файла: $verilog_file"
    fi
    
    # Извлекаем модули из текущего файла и добавляем в общий список
    extract_modules "$verilog_file" >> "$ALL_MODULES_FILE"
done <<< "$VERILOG_FILES"

# Сортируем и оставляем только уникальные имена модулей
sort "$ALL_MODULES_FILE" | uniq > "${ALL_MODULES_FILE}.sorted"
mv "${ALL_MODULES_FILE}.sorted" "$ALL_MODULES_FILE"

# Извлекаем модули с префиксом RM_
grep "^RM_" "$ALL_MODULES_FILE" > "$RM_MODULES_FILE"

# Подсчет результатов
TOTAL_MODULES_COUNT=$(wc -l < "$ALL_MODULES_FILE")
RM_MODULES_COUNT=$(wc -l < "$RM_MODULES_FILE")

# Вывод результатов
echo "=========================================="
echo "РЕЗУЛЬТАТЫ АНАЛИЗА VERILOG-МОДУЛЕЙ"
echo "=========================================="
echo "Общее количество уникальных модулей: $TOTAL_MODULES_COUNT"
echo "Количество модулей с префиксом 'RM_': $RM_MODULES_COUNT"
echo ""
echo "Список модулей с префиксом 'RM_':"

if [ "$RM_MODULES_COUNT" -eq 0 ]; then
    echo "  Не найдено модулей с префиксом 'RM_'"
else
    # Форматированный вывод модулей с префиксом RM_
    while IFS= read -r module_name; do
        echo "  - $module_name"
    done < "$RM_MODULES_FILE"
fi

# Очистка временных файлов
rm -f "$ALL_MODULES_FILE" "$RM_MODULES_FILE"

if [ "$VERBOSE" = true ]; then
    echo ""
    echo "Анализ завершен успешно."
fi

exit 0
