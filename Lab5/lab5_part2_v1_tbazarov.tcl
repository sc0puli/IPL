# ==============================
# lab5_part2_v1_tbazarov.tcl
# Лабораторная работа №5, Часть 2
# Вариант 1
# ==============================
proc analyze_timing_report {report_path} {

    # Проверка существования файла
    if {![file exists $report_path]} {
        error "Файл отчёта не найден: $report_path"
    }

    set fh [open $report_path r]

    # Инициализация статистики
    set setupCount 0
    set holdCount 0
    set worstSetup +Inf
    set worstHold  +Inf

    # Регулярное выражение ПОЛНОСТЬЮ соответствующее формату отчёта:
    # Path N Slack: -0.23 ns (VIOLATED Setup) Endpoint: U_CORE/REG_A/Q
    set re {Slack:\s*([-+]?\d+\.?\d*)\s*ns\s*\(VIOLATED\s+(Setup|Hold)\)\s*Endpoint:\s+(\S+)}

    # Чтение файла
    while {[gets $fh line] >= 0} {

        # Парсим только строки "VIOLATED"
        if {[regexp $re $line -> slack type endpoint]} {

            # Приведение slack к числу
            set slack [expr {$slack + 0.0}]

            if {$type eq "Setup"} {
                incr setupCount
                if {$slack < $worstSetup} { set worstSetup $slack }
            } else {
                incr holdCount
                if {$slack < $worstHold} { set worstHold $slack }
            }
        }
    }

    close $fh

    # ---------------------------------------------------------------
    # Вывод статистики
    # ---------------------------------------------------------------
    puts "Нарушения Setup: $setupCount"
    puts "Нарушения Hold:  $holdCount"
    puts "Худший Setup Slack: $worstSetup"
    puts "Худший Hold  Slack: $worstHold"

    # ---------------------------------------------------------------
    # Правила обработки нарушений
    # ---------------------------------------------------------------

    # 1) Если Setup нарушений > 5 → ошибка
    if {$setupCount > 5} {
        error "Слишком много Setup нарушений! Худший Slack: $worstSetup"
    }

    # 2) Если есть Hold нарушения и худший Slack < –0.1 ns → предупреждение
    if {$holdCount > 0 && $worstHold < -0.1} {
        puts "CRITICAL WARNING: Hold Slack глубже -0.1 ns — возможны серьёзные проблемы синхронизации!"
    }
}

# ===============================================================
# ВЕРХНИЙ УРОВЕНЬ: вызов процедуры через catch
# ===============================================================

set rpt "full_timing.rpt"

if {[catch {analyze_timing_report $rpt} msg]} {
    puts "КРИТИЧЕСКИЙ СБОЙ СИНХРОНИЗАЦИИ:"
    puts $msg
} else {
    puts "Анализ успешно завершён."
}