# lab3_part3_v1_tbazarov.tcl
# Процедура: check_setup_time
# Описание: проверяет выполнение setup-условия для заданного пути.
# Входные аргументы (в порядке):
#   clock_period      - период тактового сигнала (ns)
#   data_path_delay   - фактическая задержка пути данных (ns)
#   setup_time        - время установки триггера (ns)
#   margin_factor     - коэффициент запаса (десятичная дробь, например 0.1 для 10%)
#
# Пример:
# % source lab3_part3_v1_<user>.tcl
# % check_setup_time 10.0 6.5 1.0 0.1

proc check_setup_time {clock_period data_path_delay setup_time margin_factor} {
    # Проверка количества аргументов (Tcl сам передаёт их по объявлению, но защитимся)
    set errMsg ""
    foreach {name val} {clock_period $clock_period data_path_delay $data_path_delay setup_time $setup_time margin_factor $margin_factor} {
        # проверим, что значение - число (попробуем привести к double)
        if {[catch {expr {double($val)}} _]} {
            append errMsg "Аргумент \"$name\" должен быть числом (получено: $val)\n"
        }
    }
    if {$errMsg ne ""} {
        puts "ERROR: Неверные аргументы:\n$errMsg"
        return -code error "Invalid arguments"
    }

    # Приведение к double
    set cp [expr {double($clock_period)}]
    set dp [expr {double($data_path_delay)}]
    set st [expr {double($setup_time)}]
    set mf [expr {double($margin_factor)}]

    # Вычисление T_max с учётом запаса
    set T_max [expr {$cp - $st - $cp * $mf}]

    # Slack = T_max - фактическая задержка (положительное - запас, отрицательное - дефицит)
    set slack [expr {$T_max - $dp}]

    # Вывод подробного отчёта
    puts "======================================="
    puts "SETUP TIME CHECK REPORT"
    puts "---------------------------------------"
    puts [format "Clock period         : %.6f ns" $cp]
    puts [format "Data path delay      : %.6f ns" $dp]
    puts [format "Setup time (flop)    : %.6f ns" $st]
    puts [format "Margin factor        : %.6f (fraction)" $mf]
    puts "---------------------------------------"
    puts [format "Max allowed data delay (T_max): %.6f ns" $T_max]
    puts [format "Slack (T_max - data_path_delay) : %.6f ns" $slack]
    puts "---------------------------------------"

    if {$slack >= 0.0} {
        puts "Result: Setup Check OK"
        puts [format "Timing status detail: Positive slack of %.6f ns (meets timing)." $slack]
    } else {
        puts "Result: Setup Violation Detected"
        puts [format "Timing status detail: Negative slack of %.6f ns (violation)." [expr {abs($slack)}]]
    }
    puts "======================================="
}1