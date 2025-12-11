# ==============================
# lab5_part1_v1_tbazarov.tcl
# Лабораторная работа №5, Часть 1
# Вариант 1
# ==============================
proc cell_count {args} {
    return [llength $args]
}

set cells [list and2 or2 xor2 inv]
puts "Number of cells: [cell_count $cells]"