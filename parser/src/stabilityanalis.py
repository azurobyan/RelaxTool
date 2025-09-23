#!/usr/bin/env python3
import csv
import itertools
import sys
import argparse
from pathlib import Path
import math

def parse_float(value):
    """Пытается преобразовать значение в float, иначе возвращает None"""
    if value is None or value == '' or value == 'N/A' or value == 'None':
        return None
    try:
        return float(value)
    except (ValueError, TypeError):
        return None

def calculate_value(a, b, normalize=False):
    """Вычисляет значение в зависимости от режима (нормализация или нет)"""
    if a is None or b is None:
        return None
    
    if normalize:
        # Вычисляем среднее значение пары
        mean_val = (a + b) / 2
        if mean_val == 0:
            # Избегаем деления на ноль
            return None
        
        # Вычисляем корень из квадратичного отклонения, деленный на среднее
        return math.sqrt((a - b) ** 2) / mean_val
    else:
        # Обычное квадратичное отклонение
        return (a - b) ** 2

def main():
    parser = argparse.ArgumentParser(
        description='Calculate squared deviations between T_Pulse pairs for S# channels',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s -i input.csv -o output.csv
  %(prog)s -i input.csv -o output.csv -n 20
  %(prog)s -i input.csv -o output.csv --normalize
  %(prog)s -i input.csv  # output to stdout
        """
    )
    
    parser.add_argument('-i', '--input', required=True, 
                       help='Input CSV file (required)')
    parser.add_argument('-o', '--output', 
                       help='Output CSV file (if not specified, print to stdout)')
    parser.add_argument('-n', '--num-channel', type=int, default=38,
                       help='Number of S# channels (default: 38)')
    parser.add_argument('-N', '--normalize', action='store_true',
                       help='Normalize values: sqrt(squared deviation) / mean of pair')
    
    args = parser.parse_args()
    
    # Проверяем существование входного файла
    input_file = Path(args.input)
    if not input_file.exists():
        print(f"Error: Input file '{args.input}' not found", file=sys.stderr)
        sys.exit(1)
    
    # Чтение данных из файла
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            reader = csv.reader(f, delimiter=';')
            rows = list(reader)
    except Exception as e:
        print(f"Error reading input file: {e}", file=sys.stderr)
        sys.exit(1)
    
    # Находим индексы строк, содержащих T_Pulse#
    pulse_rows = []
    pulse_indices = []

    for i, row in enumerate(rows):
        if len(row) > 0 and row[0].startswith('T_Pulse#'):
            pulse_rows.append(row)
            pulse_indices.append(i)

    if len(pulse_rows) == 0:
        print("Error: No T_Pulse# rows found in the input file", file=sys.stderr)
        sys.exit(1)
    
    print(f"Found {len(pulse_rows)} T_Pulse rows", file=sys.stderr)
    
    # Определяем индексы столбцов S# (с 2 до 2+num_channel)
    s_columns_indices = list(range(2, 2 + args.num_channel))
    print(f"Processing {len(s_columns_indices)} S# channels", file=sys.stderr)
    
    # Создаем словарь для хранения данных: ключ - индекс столбца, значение - список значений для этого столбца
    column_data = {idx: [] for idx in s_columns_indices}

    # Заполняем данные для каждого столбца S#
    for row in pulse_rows:
        for idx in s_columns_indices:
            if idx < len(row):
                value = parse_float(row[idx])
                column_data[idx].append(value)
            else:
                column_data[idx].append(None)

    # Вычисляем отклонения для каждого столбца
    results = {}

    for idx in s_columns_indices:
        values = column_data[idx]
        deviations = []
        
        # Генерируем все уникальные пары индексов
        pairs = list(itertools.combinations(range(len(values)), 2))
        
        for i, j in pairs:
            value = calculate_value(values[i], values[j], args.normalize)
            pair_name = f"T_Pulse#{i+1}-T_Pulse#{j+1}"
            deviations.append((pair_name, value))
        
        results[idx] = deviations

    # Получаем все уникальные пары и сортируем их
    all_pairs = list(set([pair for idx in s_columns_indices for pair, _ in results[idx]]))
    
    def pair_sort_key(pair_str):
        """Функция для сортировки пар импульсов"""
        parts = pair_str.replace('T_Pulse#', '').split('-')
        return (int(parts[0]), int(parts[1]))
    
    all_pairs.sort(key=pair_sort_key)

    # Подготавливаем выходные данные
    output_data = []
    
    # Заголовок
    header = ['Pair'] + [f'S#{i-1}' for i in s_columns_indices]
    output_data.append(header)
    
    # Данные для каждой пары
    for pair in all_pairs:
        row_data = [pair]
        for idx in s_columns_indices:
            # Находим значение для этой пары в текущем столбце
            value = None
            for p, v in results[idx]:
                if p == pair:
                    value = v
                    break
            row_data.append(value if value is not None else 'nan')
        output_data.append(row_data)

    # Вывод результатов
    if args.output:
        # Записываем в файл
        try:
            with open(args.output, 'w', newline='', encoding='utf-8') as f:
                writer = csv.writer(f, delimiter=';')
                writer.writerows(output_data)
            print(f"Results saved to: {args.output}", file=sys.stderr)
        except Exception as e:
            print(f"Error writing output file: {e}", file=sys.stderr)
            sys.exit(1)
    else:
        # Выводим в stdout
        writer = csv.writer(sys.stdout, delimiter=';')
        writer.writerows(output_data)

    # Статистика для stderr
    print(f"\nProcessing statistics:", file=sys.stderr)
    print(f"Mode: {'Normalized' if args.normalize else 'Squared deviation'}", file=sys.stderr)
    print(f"Total pulse pairs: {len(all_pairs)}", file=sys.stderr)
    
    for idx in s_columns_indices[:3]:  # Показываем статистику для первых 3 каналов
        values = column_data[idx]
        valid_values = [v for v in values if v is not None]
        valid_pairs = sum(1 for pair_data in results[idx] if pair_data[1] is not None)
        
        print(f"S#{idx-1}: {len(valid_values)} valid values, {valid_pairs} valid pairs", file=sys.stderr)

if __name__ == "__main__":
    main()
