# ==============================
# lab4_part1_v1_tbazarov.tcl
# Лабораторная работа №4, Часть 1
# Вариант 1
# ==============================

# Процедура проверки иерархических путей проекта
proc validate_path {design_paths max_name_length} {
    set invalid_paths {}
    set valid_paths {}

    # Для каждого пути в списке
    foreach path $design_paths {
        set has_error 0

        # Разбиваем путь по "/"
        set modules [split $path "/"]

        # Проверяем каждый модуль
        foreach module $modules {
            if {$module eq ""} {
                continue
            }

            # Проверка длины имени
            if {[string length $module] > $max_name_length} {
                set has_error 1
            }

            # Проверка наличия временного имени
            if {[string match "_temp_*" $module]} {
                set has_error 1
            }
        }

        # Формируем списки
        if {$has_error} {
            lappend invalid_paths $path
        } else {
            lappend valid_paths $path
        }
    }

    # Вывод результатов
    puts "=== Проверка путей ==="
    puts "Ошибочные пути:"
    if {[llength $invalid_paths] == 0} {
        puts "  (нет ошибок)"
    } else {
        foreach p $invalid_paths {
            puts "  $p"
        }
    }

    puts "\nВалидные пути:"
    if {[llength $valid_paths] == 0} {
        puts "  (нет валидных путей)"
    } else {
        foreach p $valid_paths {
            puts "  $p"
        }
    }
}

# Пример использования (после source в интерпретаторе):
# set design_paths {/top/inst_a/module_b /top/inst_long_name/sub_c /top/inst_d/_temp_ff /top/valid_inst}
# validate_path $design_paths 10
