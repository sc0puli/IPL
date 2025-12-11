"""
Лабораторная работа №7 - Вариант 1
Скрипт для анализа библиотеки логических элементов в формате Liberty
"""

import re
import sys
from typing import Dict, List, Tuple


def parse_liberty_file(filepath: str) -> List[Dict]:
    """
    Парсит Liberty-файл и извлекает информацию о ячейках.
    
    Args:
        filepath: Путь к Liberty-файлу
        
    Returns:
        list: Список словарей с информацией о каждой ячейке
        
    Note:
        Каждый словарь содержит: имя, входы, выходы, площадь,
        мощность утечки и максимальную входную емкость
    """
    cells = []
    
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Ошибка: файл '{filepath}' не найден")
        return []
    except Exception as e:
        print(f"Ошибка при чтении файла: {e}")
        return []
    
    # Поиск всех ячеек (cell)
    cell_pattern = r'cell\s*\(\s*"?([^")\s]+)"?\s*\)\s*\{([^}]*(?:\{[^}]*\}[^}]*)*)\}'
    cell_matches = re.finditer(cell_pattern, content, re.DOTALL)
    
    for cell_match in cell_matches:
        cell_name = cell_match.group(1)
        cell_body = cell_match.group(2)
        
        cell_info = {
            'name': cell_name,
            'inputs': [],
            'outputs': [],
            'area': 0.0,
            'leakage_power': 0.0,
            'max_capacitance': 0.0
        }
        
        # Извлечение площади
        area_match = re.search(r'area\s*:\s*([\d.]+)', cell_body)
        if area_match:
            cell_info['area'] = float(area_match.group(1))
        
        # Извлечение мощности утечки
        leakage_match = re.search(r'cell_leakage_power\s*:\s*([\d.]+)', cell_body)
        if leakage_match:
            cell_info['leakage_power'] = float(leakage_match.group(1))
        
        # Поиск всех pin блоков
        pin_pattern = r'pin\s*\(\s*"?([^")\s]+)"?\s*\)\s*\{([^}]*(?:\{[^}]*\}[^}]*)*)\}'
        pin_matches = re.finditer(pin_pattern, cell_body, re.DOTALL)
        
        max_cap = 0.0
        for pin_match in pin_matches:
            pin_name = pin_match.group(1)
            pin_body = pin_match.group(2)
            
            # Определение направления
            direction_match = re.search(r'direction\s*:\s*"?(\w+)"?', pin_body)
            if direction_match:
                direction = direction_match.group(1).lower()
                
                if direction == 'input':
                    cell_info['inputs'].append(pin_name)
                    
                    # Извлечение емкости для входа
                    cap_match = re.search(r'capacitance\s*:\s*([\d.]+)', pin_body)
                    if cap_match:
                        cap_value = float(cap_match.group(1))
                        max_cap = max(max_cap, cap_value)
                
                elif direction == 'output':
                    cell_info['outputs'].append(pin_name)
        
        cell_info['max_capacitance'] = max_cap
        cells.append(cell_info)
    
    return cells


def analyze_cells(cells: List[Dict]) -> Dict:
    """
    Анализирует собранную информацию о ячейках.
    
    Args:
        cells: Список словарей с информацией о ячейках
        
    Returns:
        dict: Словарь с результатами анализа
    """
    if not cells:
        return {}
    
    analysis = {
        'total_cells': len(cells),
        'min_area_cell': min(cells, key=lambda x: x['area']),
        'max_area_cell': max(cells, key=lambda x: x['area']),
        'max_leakage_cell': max(cells, key=lambda x: x['leakage_power']),
        'max_capacitance_cell': max(cells, key=lambda x: x['max_capacitance']),
        'cells_with_many_inputs': [c for c in cells if len(c['inputs']) > 3]
    }
    
    return analysis


def generate_report(filepath: str, cells: List[Dict], analysis: Dict, output_file: str):
    """
    Генерирует отчет с результатами анализа.
    
    Args:
        filepath: Путь к исходному файлу
        cells: Список всех ячеек
        analysis: Результаты анализа
        output_file: Путь к файлу отчета
    """
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write("=" * 80 + "\n")
            f.write("ОТЧЕТ ОБ АНАЛИЗЕ БИБЛИОТЕКИ LIBERTY\n")
            f.write("=" * 80 + "\n\n")
            
            f.write(f"Исходный файл: {filepath}\n")
            f.write(f"Общее количество ячеек: {analysis['total_cells']}\n\n")
            
            # Ячейка с минимальной площадью
            f.write("-" * 80 + "\n")
            f.write("ЯЧЕЙКА С МИНИМАЛЬНОЙ ПЛОЩАДЬЮ:\n")
            f.write("-" * 80 + "\n")
            write_cell_info(f, analysis['min_area_cell'])
            
            # Ячейка с максимальной площадью
            f.write("-" * 80 + "\n")
            f.write("ЯЧЕЙКА С МАКСИМАЛЬНОЙ ПЛОЩАДЬЮ:\n")
            f.write("-" * 80 + "\n")
            write_cell_info(f, analysis['max_area_cell'])
            
            # Ячейка с максимальной мощностью утечки
            f.write("-" * 80 + "\n")
            f.write("ЯЧЕЙКА С МАКСИМАЛЬНОЙ МОЩНОСТЬЮ УТЕЧКИ:\n")
            f.write("-" * 80 + "\n")
            write_cell_info(f, analysis['max_leakage_cell'])
            
            # Ячейка с максимальной емкостью входов
            f.write("-" * 80 + "\n")
            f.write("ЯЧЕЙКА С МАКСИМАЛЬНОЙ ВХОДНОЙ ЕМКОСТЬЮ:\n")
            f.write("-" * 80 + "\n")
            write_cell_info(f, analysis['max_capacitance_cell'])
            
            # Ячейки с количеством входов больше 3
            f.write("-" * 80 + "\n")
            f.write(f"ЯЧЕЙКИ С КОЛИЧЕСТВОМ ВХОДОВ > 3 ({len(analysis['cells_with_many_inputs'])} шт.):\n")
            f.write("-" * 80 + "\n")
            for cell in analysis['cells_with_many_inputs']:
                write_cell_info(f, cell)
                f.write("\n")
            
            f.write("=" * 80 + "\n")
            f.write("КОНЕЦ ОТЧЕТА\n")
            f.write("=" * 80 + "\n")
        
        print(f"Отчет успешно сохранен в файл: {output_file}")
    
    except Exception as e:
        print(f"Ошибка при сохранении отчета: {e}")


def write_cell_info(f, cell: Dict):
    """Записывает информацию о ячейке в файл"""
    f.write(f"  Имя ячейки: {cell['name']}\n")
    f.write(f"  Входы ({len(cell['inputs'])}): {', '.join(cell['inputs']) if cell['inputs'] else 'нет'}\n")
    f.write(f"  Выходы ({len(cell['outputs'])}): {', '.join(cell['outputs']) if cell['outputs'] else 'нет'}\n")
    f.write(f"  Площадь: {cell['area']}\n")
    f.write(f"  Мощность утечки: {cell['leakage_power']}\n")
    f.write(f"  Максимальная входная емкость: {cell['max_capacitance']}\n")


def main():
    """Главная функция программы"""
    
    # Запрос имени входного файла
    if len(sys.argv) > 1:
        input_file = sys.argv[1]
    else:
        input_file = input("Введите путь к Liberty-файлу: ").strip()
    
    if not input_file:
        print("Ошибка: не указан входной файл")
        return
    
    # Парсинг файла
    print(f"Анализ файла: {input_file}")
    cells = parse_liberty_file(input_file)
    
    if not cells:
        print("Не удалось извлечь информацию о ячейках")
        return
    
    print(f"Найдено ячеек: {len(cells)}")
    
    # Анализ ячеек
    analysis = analyze_cells(cells)
    
    # Генерация отчета
    output_file = input_file.rsplit('.', 1)[0] + '_report.txt'
    generate_report(input_file, cells, analysis, output_file)
    
    # Вывод краткой статистики на консоль
    print("\n" + "=" * 60)
    print("КРАТКАЯ СТАТИСТИКА:")
    print("=" * 60)
    print(f"Общее количество ячеек: {analysis['total_cells']}")
    print(f"Ячейка с мин. площадью: {analysis['min_area_cell']['name']} (area={analysis['min_area_cell']['area']})")
    print(f"Ячейка с макс. площадью: {analysis['max_area_cell']['name']} (area={analysis['max_area_cell']['area']})")
    print(f"Ячейка с макс. утечкой: {analysis['max_leakage_cell']['name']} (leakage={analysis['max_leakage_cell']['leakage_power']})")
    print(f"Ячейка с макс. емкостью: {analysis['max_capacitance_cell']['name']} (cap={analysis['max_capacitance_cell']['max_capacitance']})")
    print(f"Ячеек с входами > 3: {len(analysis['cells_with_many_inputs'])}")
    print("=" * 60)


if __name__ == "__main__":
    main()