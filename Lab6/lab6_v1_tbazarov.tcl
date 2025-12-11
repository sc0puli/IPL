#!/usr/bin/env wish
package require Tk

# Глобальные переменные
array set congestion_map {}
set threshold 50
set total_cells 0
set avg_congestion 0.0
set grid_size 0

# Процедура для открытия и загрузки файла с данными
proc load_congestion_file {} {
    global congestion_map total_cells avg_congestion grid_size
    
    set filename [tk_getOpenFile -title "Open Congestion Map File" \
                                  -filetypes {{"Text files" {.txt}} {"All files" *}}]
    
    if {$filename eq ""} {
        return
    }
    
    # Очистка предыдущих данных
    array unset congestion_map
    array set congestion_map {}
    set total_cells 0
    set sum 0.0
    set max_x 0
    set max_y 0
    
    # Чтение файла с обработкой ошибок
    if {[catch {
        set fp [open $filename r]
        set content [read $fp]
        close $fp
        
        # Парсинг данных построчно
        foreach line [split $content "\n"] {
            set line [string trim $line]
            if {$line eq ""} continue
            
            # Разбор элементов в строке
            set elements [split $line]
            set i 0
            while {$i < [llength $elements]} {
                set item [lindex $elements $i]
                # Проверка на координату
                if {[regexp {^(\d+),(\d+)$} $item -> x y]} {
                    # Следующий элемент должен быть значением
                    incr i
                    if {$i < [llength $elements]} {
                        set value [lindex $elements $i]
                        if {[string is integer -strict $value]} {
                            set congestion_map($item) $value
                            incr total_cells
                            set sum [expr {$sum + $value}]
                            
                            # Определение размера сетки
                            if {$x > $max_x} {set max_x $x}
                            if {$y > $max_y} {set max_y $y}
                        }
                    }
                }
                incr i
            }
        }
        
        # Вычисление статистики
        if {$total_cells > 0} {
            set avg_congestion [format "%.2f" [expr {$sum / $total_cells}]]
            set grid_size [expr {max($max_x, $max_y)}]
        }
        
    } err]} {
        tk_messageBox -icon error -title "Error" \
                      -message "Failed to load file: $err"
        return
    }
    
    if {$total_cells == 0} {
        tk_messageBox -icon warning -title "Warning" \
                      -message "No valid data found in file"
        return
    }
    
    # Обновление интерфейса
    update_statistics
    draw_congestion_map
    
    tk_messageBox -icon info -title "Success" \
                  -message "Loaded $total_cells cells from file"
}

# Процедура обновления статистики
proc update_statistics {} {
    global total_cells avg_congestion
    
    .left.stats.cells configure -text "Total Cells: $total_cells"
    .left.stats.avg configure -text "Average Congestion: $avg_congestion%"
}

# Процедура отрисовки карты загруженности
proc draw_congestion_map {} {
    global congestion_map threshold grid_size
    
    # Очистка canvas
    .right.canvas delete all
    
    if {$grid_size == 0} {
        .right.canvas create text 250 250 -text "No data loaded\n\nUse File -> Open Map to load data" \
            -font {Arial 16} -fill gray -justify center
        return
    }
    
    # Размеры ячейки
    set canvas_width 500
    set canvas_height 500
    set cell_width [expr {double($canvas_width) / $grid_size}]
    set cell_height [expr {double($canvas_height) / $grid_size}]
    
    # Отрисовка ячеек
    for {set y 1} {$y <= $grid_size} {incr y} {
        for {set x 1} {$x <= $grid_size} {incr x} {
            set coord "$x,$y"
            
            if {[info exists congestion_map($coord)]} {
                set value $congestion_map($coord)
                
                # Определение цвета
                if {$value > $threshold} {
                    set color "#FF3333"
                    set textcolor "white"
                } elseif {$value > [expr {$threshold * 0.7}]} {
                    set color "#FFA500"
                    set textcolor "black"
                } else {
                    set color "#33FF33"
                    set textcolor "black"
                }
                
                # Координаты на canvas
                set x1 [expr {($x - 1) * $cell_width}]
                set y1 [expr {($y - 1) * $cell_height}]
                set x2 [expr {$x * $cell_width}]
                set y2 [expr {$y * $cell_height}]
                
                # Рисование ячейки
                .right.canvas create rectangle $x1 $y1 $x2 $y2 \
                    -fill $color -outline black -width 2
                
                # Добавление текста со значением
                set cx [expr {($x1 + $x2) / 2.0}]
                set cy [expr {($y1 + $y2) / 2.0}]
                
                # Размер шрифта зависит от размера ячейки
                set fontsize [expr {min(14, int($cell_width / 3))}]
                if {$fontsize < 8} {set fontsize 8}
                
                .right.canvas create text $cx $cy -text $value \
                    -fill $textcolor -font [list Arial $fontsize bold]
            }
        }
    }
}

# Процедура обновления порога
proc update_threshold {} {
    global threshold total_cells
    
    if {![string is integer -strict $threshold] || $threshold < 0 || $threshold > 100} {
        tk_messageBox -icon error -title "Error" \
                      -message "Threshold must be an integer between 0 and 100"
        set threshold 50
        return
    }
    
    if {$total_cells > 0} {
        draw_congestion_map
    }
}

# Процедура показа информации о приложении
proc show_about {} {
    set msg "Congestion Map Visualizer\n\n"
    append msg "Приложение для визуализации данных\n"
    append msg "о загруженности трассировки.\n\n"
    append msg "Функции:\n"
    append msg "- Загрузка карты из файла\n"
    append msg "- Визуализация с цветовой индикацией\n"
    append msg "- Настройка критического порога\n"
    append msg "- Статистика по загруженности\n\n"
    append msg "Вариант 1"
    
    tk_messageBox -icon info -title "About" -message $msg
}

# Процедура выхода из приложения
proc exit_app {} {
    exit
}

# Создание главного окна
wm title . "Congestion Map Visualizer"
wm geometry . 900x700

# Создание меню
menu .menubar
. configure -menu .menubar

# Меню File
menu .menubar.file -tearoff 0
.menubar.file add command -label "Open Map" -command load_congestion_file
.menubar.file add separator
.menubar.file add command -label "Exit" -command exit_app
.menubar add cascade -label "File" -menu .menubar.file

# Меню Help
menu .menubar.help -tearoff 0
.menubar.help add command -label "About" -command show_about
.menubar add cascade -label "Help" -menu .menubar.help

# Фрейм для порога (верхняя панель)
frame .top -relief raised -borderwidth 1
pack .top -side top -fill x -padx 5 -pady 5

label .top.label -text "Critical Threshold (%):" -font {Arial 12 bold}
grid .top.label -row 0 -column 0 -padx 10 -pady 10 -sticky w

entry .top.entry -textvariable threshold -width 15 -font {Arial 12} -relief sunken -borderwidth 2
grid .top.entry -row 0 -column 1 -padx 10 -pady 10

button .top.apply -text "Apply Threshold" -command update_threshold -font {Arial 12} -padx 10 -pady 5
grid .top.apply -row 0 -column 2 -padx 10 -pady 10

label .top.hint -text "(Enter value 0-100 and click Apply)" -font {Arial 10} -fg gray
grid .top.hint -row 0 -column 3 -padx 10 -pady 10 -sticky w

# Основной контейнер
frame .container
pack .container -side top -fill both -expand yes -padx 10 -pady 10

# Левая панель со статистикой
frame .left -relief ridge -borderwidth 2
pack .left -in .container -side left -fill y -padx 5 -pady 5

label .left.title -text "Statistics" -font {Arial 16 bold} -pady 10
pack .left.title -side top

frame .left.stats
pack .left.stats -side top -pady 10 -padx 20 -fill x

label .left.stats.cells -text "Total Cells: 0" -font {Arial 13} -anchor w
pack .left.stats.cells -side top -pady 5 -fill x

label .left.stats.avg -text "Average Congestion: 0.00%" -font {Arial 13} -anchor w
pack .left.stats.avg -side top -pady 5 -fill x

# Разделительная линия
frame .left.separator -height 2 -bg gray
pack .left.separator -side top -fill x -pady 20 -padx 10

# Легенда
label .left.legend_title -text "Legend" -font {Arial 14 bold}
pack .left.legend_title -side top -pady 10

frame .left.legend1
pack .left.legend1 -side top -pady 5 -padx 20 -anchor w

frame .left.legend1.color -width 40 -height 25 -bg "#33FF33" -relief raised -borderwidth 2
pack .left.legend1.color -side left -padx 5

label .left.legend1.text -text "Low congestion" -font {Arial 12}
pack .left.legend1.text -side left -padx 5

frame .left.legend2
pack .left.legend2 -side top -pady 5 -padx 20 -anchor w

frame .left.legend2.color -width 40 -height 25 -bg "#FFA500" -relief raised -borderwidth 2
pack .left.legend2.color -side left -padx 5

label .left.legend2.text -text "Medium congestion" -font {Arial 12}
pack .left.legend2.text -side left -padx 5

frame .left.legend3
pack .left.legend3 -side top -pady 5 -padx 20 -anchor w

frame .left.legend3.color -width 40 -height 25 -bg "#FF3333" -relief raised -borderwidth 2
pack .left.legend3.color -side left -padx 5

label .left.legend3.text -text "Critical (> threshold)" -font {Arial 12}
pack .left.legend3.text -side left -padx 5

# Правая панель с картой
frame .right -relief ridge -borderwidth 2
pack .right -in .container -side right -fill both -expand yes -padx 5 -pady 5

label .right.title -text "Congestion Map" -font {Arial 16 bold} -pady 10
pack .right.title -side top

canvas .right.canvas -width 500 -height 500 -bg white -relief sunken -borderwidth 2
pack .right.canvas -side top -padx 20 -pady 10

# Начальное сообщение на canvas
.right.canvas create text 250 250 -text "No data loaded\n\nUse File -> Open Map to load data" \
    -font {Arial 16} -fill gray -justify center