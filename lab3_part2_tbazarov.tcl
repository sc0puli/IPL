# ================================================================
# lab3_part2_v1_<user>.tcl
# Лабораторная работа №3 — Часть 2
# Вариант 1
# Тема: различие в кавычках и фигурных скобках при определении процедур Tcl
# ================================================================

# Инициализация переменной
set a 2
puts "Initial global variable: a = $a"
puts "-------------------------------------------------------------"

# Определение процедур
proc print_q {a} "puts {Value = $a}"
proc print_b {a} {puts "Value = $a"}
proc print_bb {a} {puts {Value = $a}}

# Выводим тела процедур для анализа
puts "\n--- Procedure Bodies ---"
puts "print_q body: [info body print_q]"
puts "print_b body: [info body print_b]"
puts "print_bb body: [info body print_bb]"
puts "-------------------------------------------------------------"

# Демонстрация вызовов
puts "\n--- Calling print_q 99 ---"
print_q 99
puts "Explanation: \$a подставился при определении, поэтому всегда Value = 2"

puts "\n--- Calling print_b 99 ---"
print_b 99
puts "Explanation: \$a подставляется при вызове, поэтому Value = 99"

puts "\n--- Calling print_bb 99 ---"
print_bb 99
puts "Explanation: \$a внутри фигурных скобок — текст, без подстановки => Value = \$a"

puts "-------------------------------------------------------------"
puts "Summary:"
puts "print_q  -> значение a зашито при определении (Value = 2)"
puts "print_b  -> значение подставляется при вызове (Value = аргумент)"
puts "print_bb -> \$a выводится буквально (Value = \$a)"