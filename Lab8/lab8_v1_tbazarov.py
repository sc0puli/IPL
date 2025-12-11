#!/usr/bin/env python3
# lab8_v1_user.py
"""
Лабораторная работа №8 — Вариант 1
Скрипт анализирует библиотеку ячеек ввода-вывода в формате LEF и собирает статистику.

Требования:
- GUI с возможностью выбора LEF-файла (диалог)
- Парсинг LEF через регулярные выражения
- Классы LEFIOCell и LEFIOLibrary
- Методы проверки (has_inputs, has_outputs, has_power, has_ground)
- Гистограмма распределения типов ячеек (Matplotlib)
- Отчёт в текстовом поле приложения (полная информация о ячейках, имя файла, общее число)
- Использование NumPy для численных расчётов
- Обработка исключений (как минимум при работе с файлами)
"""

import sys
import re
from collections import Counter, defaultdict
from typing import List, Optional, Dict

import numpy as np
import matplotlib.pyplot as plt

from PyQt5.QtWidgets import (
    QApplication, QMainWindow, QTextEdit, QFileDialog,
    QAction, QWidget, QVBoxLayout, QPushButton, QMessageBox, QLabel
)
from PyQt5.QtCore import Qt


class LEFIOCell:
    """
    Класс, представляющий одну IO-ячейку из LEF.

    Атрибуты:
        name: имя ячейки
        inputs: список имен пинов с направлением INPUT
        outputs: список имен пинов с направлением OUTPUT
        power_buses: список имен пинов с USE POWER
        ground_buses: список имен пинов с USE GROUND
        cell_class: тип ячейки (значение атрибута CLASS, если найдено)
        raw: сырой текст описания ячейки (для полного вывода)
    """

    def __init__(self, name: str, raw_text: str = ""):
        self.name: str = name
        self.inputs: List[str] = []
        self.outputs: List[str] = []
        self.power_buses: List[str] = []
        self.ground_buses: List[str] = []
        self.cell_class: Optional[str] = None
        self.raw: str = raw_text

    def has_inputs(self) -> bool:
        """Возвращает True, если есть хотя бы один вход."""
        return len(self.inputs) > 0

    def has_outputs(self) -> bool:
        """Возвращает True, если есть хотя бы один выход."""
        return len(self.outputs) > 0

    def has_power(self) -> bool:
        """Возвращает True, если есть шины питания (USE POWER)."""
        return len(self.power_buses) > 0

    def has_ground(self) -> bool:
        """Возвращает True, если есть шины земли (USE GROUND)."""
        return len(self.ground_buses) > 0

    def summary(self) -> str:
        """Короткий текстовый отчёт по ячейке."""
        return (f"Name: {self.name}\n"
                f"  Class: {self.cell_class}\n"
                f"  Inputs ({len(self.inputs)}): {', '.join(self.inputs) if self.inputs else '-'}\n"
                f"  Outputs ({len(self.outputs)}): {', '.join(self.outputs) if self.outputs else '-'}\n"
                f"  Power buses ({len(self.power_buses)}): {', '.join(self.power_buses) if self.power_buses else '-'}\n"
                f"  Ground buses ({len(self.ground_buses)}): {', '.join(self.ground_buses) if self.ground_buses else '-'}\n")


class LEFIOLibrary:
    """
    Класс, содержащий список LEFIOCell и реализующий методы поиска/анализа.
    """

    def __init__(self):
        self.cells: List[LEFIOCell] = []
        self.filename: Optional[str] = None

    def add_cell(self, cell: LEFIOCell):
        self.cells.append(cell)

    def total_cells(self) -> int:
        return len(self.cells)

    def cells_only_power_ground(self) -> List[LEFIOCell]:
        """Ячейки, содержащие только шины земли и питания (и НЕ входы/выходы)."""
        res = [c for c in self.cells if (not c.has_inputs() and not c.has_outputs()) and (c.has_power() or c.has_ground())]
        return res

    def cells_only_inputs_and_power_ground(self) -> List[LEFIOCell]:
        """Ячейки, содержащие только входы и шины питания/земли (без выходов)."""
        res = [c for c in self.cells if c.has_inputs() and (not c.has_outputs()) and (c.has_power() or c.has_ground())]
        return res

    def cells_only_outputs_and_power_ground(self) -> List[LEFIOCell]:
        """Ячейки, содержащие только выходы и шины питания/земли (без входов)."""
        res = [c for c in self.cells if c.has_outputs() and (not c.has_inputs()) and (c.has_power() or c.has_ground())]
        return res

    def cells_inputs_outputs_and_power_ground(self) -> List[LEFIOCell]:
        """Ячейки, содержащие входы, выходы и шины питания/земли."""
        res = [c for c in self.cells if c.has_inputs() and c.has_outputs() and (c.has_power() or c.has_ground())]
        return res

    def map_groups_to_types(self) -> Dict[str, List[str]]:
        """
        Устанавливает соответствие между группами (по наличию сигналов) и их типом (cell_class).
        Возвращает словарь: ключ = группа, значение = список типов cell_class встречающихся в этой группе.
        """
        groups = {
            'only_power_ground': self.cells_only_power_ground(),
            'inputs_and_power_ground': self.cells_only_inputs_and_power_ground(),
            'outputs_and_power_ground': self.cells_only_outputs_and_power_ground(),
            'inputs_outputs_power_ground': self.cells_inputs_outputs_and_power_ground()
        }
        mapping = {}
        for gname, cells in groups.items():
            types = sorted({c.cell_class or 'UNKNOWN' for c in cells})
            mapping[gname] = types
        return mapping

    def distribution_by_type(self) -> Dict[str, int]:
        """Распределение по полю cell_class (тип ячейки)."""
        types = [c.cell_class if c.cell_class else 'UNKNOWN' for c in self.cells]
        cnt = dict(Counter(types))
        return cnt

    def full_report(self) -> str:
        """Форматированный отчёт по всему анализу (строка)."""
        lines = []
        lines.append(f"File: {self.filename or '---'}")
        lines.append(f"Total cells: {self.total_cells()}")
        lines.append("")
        lines.append("Cells by type:")
        for t, n in self.distribution_by_type().items():
            lines.append(f"  {t}: {n}")
        lines.append("")
        # Groups with full info
        groups = {
            'Cells containing only power and ground buses': self.cells_only_power_ground(),
            'Cells containing only inputs and power/ground': self.cells_only_inputs_and_power_ground(),
            'Cells containing only outputs and power/ground': self.cells_only_outputs_and_power_ground(),
            'Cells containing inputs, outputs and power/ground': self.cells_inputs_outputs_and_power_ground()
        }
        for title, cells in groups.items():
            lines.append(f"{title} (count = {len(cells)}):")
            for c in cells:
                # include full info for each cell
                for l in c.summary().splitlines():
                    lines.append("    " + l)
            lines.append("")
        return "\n".join(lines)


# --------------------------
# LEF parser utility
# --------------------------

def parse_lef(content: str) -> LEFIOLibrary:
    """
    Простейший парсер LEF-файла, ориентированный на извлечение MACRO/CELL блоков и PIN-ов с DIRECTION/USE и
    атрибута CLASS.
    Возвращает объект LEFIOLibrary с заполненными LEFIOCell.
    """
    lib = LEFIOLibrary()

    # Попробуем найти блоки MACRO ... END MACRO или CELL ... END CELL
    # Поддерживаем оба варианта, т.к. различные LEF-генераторы используют разные ключевые слова.
    # Используем DOTALL, чтобы поймать многострочные блоки.
    block_pattern = re.compile(r'\b(MACRO|CELL)\s+(\S+)(.*?)(?:\nEND\s+\1\b|\nEND\b)', re.IGNORECASE | re.DOTALL)
    pin_block_pattern = re.compile(r'\bPIN\s+(\S+)(.*?)(?=\bPIN\s+\S+|\nEND\s+\w+|\nEND\b)', re.IGNORECASE | re.DOTALL)
    direction_pattern = re.compile(r'\bDIRECTION\s+(\w+)', re.IGNORECASE)
    use_pattern = re.compile(r'\bUSE\s+(\w+)', re.IGNORECASE)
    class_pattern = re.compile(r'\bCLASS\s+(\w+)', re.IGNORECASE)

    for mb in block_pattern.finditer(content):
        block_type = mb.group(1)
        name = mb.group(2)
        block_text = mb.group(3)
        cell = LEFIOCell(name=name, raw_text=block_text)

        # CLASS может находиться прямо после имени или внутри блока
        mclass = class_pattern.search(block_text)
        if mclass:
            cell.cell_class = mclass.group(1).upper()
        else:
            # попытка найти CLASS на той же строке, где имя (редко)
            header_class = re.search(r'\bCLASS\s+(\w+)', mb.group(0), re.IGNORECASE)
            if header_class:
                cell.cell_class = header_class.group(1).upper()

        # Поиск PIN-блоков
        for pb in pin_block_pattern.finditer(block_text):
            pin_name = pb.group(1)
            pin_text = pb.group(2)
            # direction
            md = direction_pattern.search(pin_text)
            if md:
                dir_val = md.group(1).upper()
                if dir_val.startswith('IN'):  # INPUT or INOUT treat as input? we'll treat INOUT separately
                    cell.inputs.append(pin_name)
                elif dir_val.startswith('OUT'):
                    cell.outputs.append(pin_name)
                elif dir_val.upper() == 'INOUT':
                    # INOUT добавим и в inputs и в outputs (на всякий случай)
                    cell.inputs.append(pin_name)
                    cell.outputs.append(pin_name)
                else:
                    # неизвестная DIRECTION — не добавляем
                    pass
            # use (POWER/GROUND)
            for mu in use_pattern.finditer(pin_text):
                use_val = mu.group(1).upper()
                if use_val == 'POWER':
                    cell.power_buses.append(pin_name)
                elif use_val == 'GROUND':
                    cell.ground_buses.append(pin_name)
                # возможны другие варианты (e.g. SIGNAL) — игнорируем

        # Дополнительный - поиск отдельных строк PORT/USE вне PIN (иногда POWER/GROUND указывают отдельно)
        # Найдём все явные упоминания USE POWER/GROUND рядом с именами
        # (в простом варианте - уже покрыто PIN USE)
        lib.add_cell(cell)

    return lib


# --------------------------
# GUI приложение
# --------------------------

class MainWindow(QMainWindow):
    """
    Главное окно приложения: меню для открытия файла, кнопка "Анализ", текстовое поле для отчёта,
    и небольшая метка состояния.
    """

    def __init__(self):
        super().__init__()
        self.setWindowTitle("Lab8 — Variant 1 LEF IO Analyzer")
        self.resize(900, 700)

        # Центральный виджет
        central = QWidget()
        self.setCentralWidget(central)
        layout = QVBoxLayout(central)

        # Кнопка Анализ
        self.btn_open = QPushButton("Открыть LEF-файл...")
        self.btn_open.clicked.connect(self.on_open_file)
        layout.addWidget(self.btn_open)

        self.btn_analyze = QPushButton("Анализ")
        self.btn_analyze.clicked.connect(self.on_analyze)
        self.btn_analyze.setEnabled(False)
        layout.addWidget(self.btn_analyze)

        # Текстовое поле
        self.text = QTextEdit()
        self.text.setReadOnly(True)
        layout.addWidget(self.text, stretch=1)

        # Статусная метка
        self.status_label = QLabel("Файл: не выбран")
        self.statusBar().addWidget(self.status_label)

        # Меню
        menubar = self.menuBar()
        file_menu = menubar.addMenu("&File")
        open_act = QAction("&Open LEF...", self)
        open_act.setShortcut("Ctrl+O")
        open_act.triggered.connect(self.on_open_file)
        file_menu.addAction(open_act)

        exit_act = QAction("&Exit", self)
        exit_act.setShortcut("Ctrl+Q")
        exit_act.triggered.connect(self.close)
        file_menu.addAction(exit_act)

        # Данные
        self.library: Optional[LEFIOLibrary] = None
        self.current_file: Optional[str] = None

    def on_open_file(self):
        """Обработка открытия файла через стандартный диалог."""
        try:
            fname, _ = QFileDialog.getOpenFileName(self, "Open LEF file", "", "LEF files (*.lef *.LEF);;All files (*.*)")
            if not fname:
                return
            self.current_file = fname
            self.status_label.setText(f"Файл: {fname}")
            self.text.clear()
            self.text.append(f"Файл {fname} выбран. Нажмите 'Анализ' для запуска обработки.")
            self.btn_analyze.setEnabled(True)
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Ошибка при выборе файла:\n{e}")

    def on_analyze(self):
        """Главная логика: читаем файл, парсим, строим статистику и отображаем отчёт + гистограмму."""
        if not self.current_file:
            QMessageBox.warning(self, "Warning", "Сначала выберите LEF-файл.")
            return

        try:
            with open(self.current_file, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Ошибка при чтении файла:\n{e}")
            return

        try:
            lib = parse_lef(content)
            lib.filename = self.current_file
            self.library = lib
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Ошибка при парсинге файла:\n{e}")
            return

        # Формирование отчёта в текстовом поле
        try:
            report = lib.full_report()
            self.text.clear()
            self.text.setPlainText(report)
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Ошибка при формировании отчёта:\n{e}")
            return

        # Построение гистограммы распределения типов ячеек
        try:
            dist = lib.distribution_by_type()
            if dist:
                types = list(dist.keys())
                counts = np.array([dist[t] for t in types])
                # Построим гистограмму (bar chart)
                fig, ax = plt.subplots()
                ax.bar(range(len(types)), counts)
                ax.set_xticks(range(len(types)))
                ax.set_xticklabels(types, rotation=45, ha='right')
                ax.set_ylabel('Number of cells')
                ax.set_title('Distribution of cell types in LEF file')
                plt.tight_layout()
                plt.show()
            else:
                QMessageBox.information(self, "Info", "Распределение типов пусто — не найдено ячеек.")
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Ошибка при построении гистограммы:\n{e}")

        # Также можно показать небольшое соответствие групп->types внизу отчёта
        try:
            mapping = lib.map_groups_to_types()
            lines = ["\nGroup -> types mapping:"]
            for g, tlist in mapping.items():
                lines.append(f"  {g}: {', '.join(tlist) if tlist else '-'}")
            self.text.append("\n".join(lines))
        except Exception:
            pass


def main():
    """Запуск GUI приложения."""
    app = QApplication(sys.argv)
    win = MainWindow()
    win.show()
    sys.exit(app.exec_())


if __name__ == '__main__':
    main()