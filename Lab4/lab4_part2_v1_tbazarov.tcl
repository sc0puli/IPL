# ==============================
# lab4_part2_v1_tbazarov.tcl
# Лабораторная работа №4, Часть 2
# Вариант 1
# ==============================

# Глобальные массивы (предопределённые данные)
array set pin_delays {
    CLK_in  "{input_pin} {1.5ns}"
    DATA_out "{output_pin} {3.2ns}"
    RST_n   "{input_pin} {0.8ns}"
    IO_pad  "{inout_pin} {2.5ns}"
    ADDR_out "{output_pin} {1.1ns}"
}

array set delay_type_priority {
    input_pin  1
    output_pin 2
    inout_pin  3
}

# Процедура сортировки пинов по типу и задержке
proc sort_by_delay {pin_list} {
    global pin_delays delay_type_priority

    # Формируем временный список {pin type value priority numeric_delay}
    set temp_list {}

    foreach pin $pin_list {
        if {![info exists pin_delays($pin)]} {
            puts "Предупреждение: данные для пина '$pin' отсутствуют"
            continue
        }

        # Извлекаем тип и значение задержки
        set data $pin_delays($pin)
        set type [lindex $data 0]
        set delay_str [lindex $data 1]

        # Удаляем "ns" и приводим к числу
        set delay_value [string map {"ns" ""} $delay_str]

        # Получаем приоритет типа
        if {![info exists delay_type_priority($type)]} {
            set priority 999
        } else {
            set priority $delay_type_priority($type)
        }

        # Добавляем в список
        lappend temp_list [list $pin $type $delay_value $priority]
    }

    # Сортировка по приоритету типа, затем по числовой задержке
    set sorted_list [lsort -increasing -command compare_pins $temp_list]

    # Вывод результата
    puts "=== Отсортированный список пинов ==="
    foreach entry $sorted_list {
        set pin [lindex $entry 0]
        set type [lindex $entry 1]
        set delay [lindex $entry 2]
        puts [format "%-10s | %-11s | %sns" $pin $type $delay]
    }
}

# Вспомогательная процедура сравнения для lsort
proc compare_pins {a b} {
    set pa [lindex $a 3]
    set pb [lindex $b 3]
    if {$pa < $pb} {return -1}
    if {$pa > $pb} {return 1}

    # Если типы равны — сравниваем задержки численно
    set da [expr {[lindex $a 2] + 0.0}]
    set db [expr {[lindex $b 2] + 0.0}]
    if {$da < $db} {return -1}
    if {$da > $db} {return 1}
    return 0
}

# Пример вызова после загрузки:
# set pins {CLK_in DATA_out RST_n IO_pad ADDR_out}
# sort_by_delay $pins
