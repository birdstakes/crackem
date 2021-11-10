package provide app 1.0

package require Tk
package require Itcl
package require sudoku

namespace eval ::app {
    namespace export App
}

::itcl::class ::app::App {
    variable game
    variable window
    variable contentFrame
    variable cellCanvases
    variable selectedCell 00

    constructor {window_} {
        set window $window_
        set game [::sudoku::Sudoku #auto]

        initWindow
        createBoard
        redraw

        dict for {cell canvas} $cellCanvases {
            bind $canvas <1> [list $this selectCell $cell]
        }

        for {set n 0} {$n <= 9} {incr n} {
            bind $window <Key-$n> [list $this setCell $n]
            bind $window <Control-Key-$n> [list $this toggleCandidate $n]
        }

        bind $window <<New>> [list $this clearBoard]
        bind $window <<Quit>> {destroy .}
        bind $window <<Copy>> [list $this copy]
        bind $window <<Paste>> [list $this paste]
        bind $window <Left> [list $this moveSelection 0 -1]
        bind $window <Right> [list $this moveSelection 0 1]
        bind $window <Up> [list $this moveSelection -1 0]
        bind $window <Down> [list $this moveSelection 1 0]
    }

    private method initWindow {} {
        set w $window
        wm title $w "Sudoku"
        wm geometry $w 512x512
        wm resizable $w false false

        option add *tearOff 0
        menu $w.menu
        menu $w.menu.file
        menu $w.menu.edit
        menu $w.menu.help
        $w.menu add cascade -menu $w.menu.file -label "File" -underline 0
        $w.menu add cascade -menu $w.menu.edit -label "Edit" -underline 0
        $w.menu add cascade -menu $w.menu.help -label "Help" -underline 0
        $w.menu.file add command -label "New" -underline 0 -accelerator "Ctrl+N" -command [list event generate $w <<New>>]
        $w.menu.file add separator
        $w.menu.file add command -label "Exit" -underline 1 -accelerator "Ctrl+Q" -command [list event generate $w <<Quit>>]
        $w.menu.edit add command -label "Copy" -underline 0 -accelerator "Ctrl+C" -command [list event generate $w <<Copy>>]
        $w.menu.edit add command -label "Paste" -underline 0 -accelerator "Ctrl+V" -command [list event generate $w <<Paste>>]
        $w.menu.help add command -label "How to play" -underline 0 -command [list $this instructions]
        $w.menu.help add separator
        $w.menu.help add command -label "About" -underline 0 -command [list $this about]
        $w configure -menu $w.menu

        bind $w <Control-n> [list event generate $w <<New>>]
        bind $w <Control-q> [list event generate $w <<Quit>>]

        grid [ttk::frame $w.content] -row 0 -column 0 -sticky nsew
        grid rowconfigure $w 0 -weight 1
        grid columnconfigure $w 0 -weight 1
        set contentFrame $w.content
    }

    private method createBoard {} {
        set w $contentFrame
        font create CellFont -family Helvetica -size 20 -weight bold
        font create CandidateFont -family Helvetica -size 10
        ttk::style configure Border.TFrame -background black

        grid [ttk::frame $w.board -style Border.TFrame -padding 3] -sticky nsew
        grid rowconfigure $w 0 -weight 1
        grid columnconfigure $w 0 -weight 1

        # 3x3 blocks
        for {set i 0} {$i < 3} {incr i} {
            # equal spacing
            grid rowconfigure $w.board $i -weight 1
            grid columnconfigure $w.board $i -weight 1

            for {set j 0} {$j < 3} {incr j} {
                set path $w.board.block$i$j

                # border
                ttk::frame $path -style Border.TFrame -padding 1.5
                grid $path -row $i -column $j -sticky nsew
                grid rowconfigure $path 0 -weight 1
                grid columnconfigure $path 0 -weight 1

                # content
                ttk::frame $path.test
                grid $path.test -sticky nsew
            }
        }

        # cells
        for {set i 0} {$i < 9} {incr i} {
            for {set j 0} {$j < 9} {incr j} {
                # which block is this cell in?
                set blockRow [expr {$i / 3}]
                set blockColumn [expr {$j / 3}]

                # position of cell within block
                set rowInBlock [expr {$i % 3}]
                set columnInBlock [expr {$j % 3}]

                set parent $w.board.block${blockRow}${blockColumn}
                set path $parent.$i$j

                # space cells equally within block
                grid rowconfigure $parent $rowInBlock -weight 1
                grid columnconfigure $parent $columnInBlock -weight 1

                # border
                ttk::frame $path -style Border.TFrame -padding 1
                grid $path -row $rowInBlock -column $columnInBlock -sticky nsew
                grid rowconfigure $path 0 -weight 1
                grid columnconfigure $path 0 -weight 1

                # canvas
                grid [canvas $path.canvas -background white -borderwidth 0 -highlightthickness 0] -sticky nsew
                dict set cellCanvases $i$j $path.canvas
            }
        }
    }

    private method drawCell {cell} {
        set cellCanvas [dict get $cellCanvases $cell]
        set width [winfo width $cellCanvas]
        set height [winfo height $cellCanvas]
        set centerX [expr {$width / 2}]
        set centerY [expr {$height / 2}]

        $cellCanvas delete all

        set background [expr {$selectedCell == $cell ? {yellow} : {white}}]
        $cellCanvas configure -background $background

        if {![$game isEmpty $cell]} {
            set color [expr {[$game isGiven $cell] ? {blue} : {black}}]
            $cellCanvas create text $centerX $centerY -font CellFont -fill $color -text [$game getValue $cell]
        } else {
            for {set i 0} {$i < 3} {incr i} {
                for {set j 0} {$j < 3} {incr j} {
                    set x [expr {$centerX + ($j - 1) * $width / 3}]
                    set y [expr {$centerY + ($i - 1) * $height / 3}]
                    set candidate [expr {$i * 3 + $j + 1}]
                    if {[$game hasCandidate $cell $candidate]} {
                        $cellCanvas create text $x $y -font CandidateFont -text $candidate
                    }
                }
            }
        }
    }

    private method redraw {} {
        for {set i 0} {$i < 9} {incr i} {
            for {set j 0} {$j < 9} {incr j} {
                drawCell $i$j
            }
        }
    }

    method clearBoard {} {
        $game clear
        selectCell 00
        redraw
    }

    method selectCell {cell} {
        set oldSelection $selectedCell
        set selectedCell $cell
        drawCell $oldSelection
        drawCell $cell
    }

    method moveSelection {rows columns} {
        set currentRow [string index $selectedCell 0]
        set currentColumn  [string index $selectedCell 1]
        set newRow [expr {($currentRow + $rows) % 9}]
        set newColumn [expr {($currentColumn + $columns) % 9}]
        selectCell ${newRow}${newColumn}
    }

    method setCell {value} {
        $game setValue $selectedCell $value
        drawCell $selectedCell
        checkWin
    }

    method toggleCandidate {candidate} {
        $game toggleCandidate $selectedCell $candidate
        drawCell $selectedCell
    }

    method messageBox {args} {
        after 1 [list tk_messageBox -parent $window {*}$args]
    }

    method instructions {} {
        messageBox -title "How to play" -message "Put numbers in boxes until you win!"
    }
    method about {} {
        messageBox -title "About Sudoku" -message "The ancient number puzzle from Dell Magazines"
    }

    method checkWin {} {
        switch [$game state] {
            incorrect {
                messageBox -title "Not quite" -message "Keep trying..." -icon error
            }
            correct {
                messageBox -title "Well..." -message "You solved the puzzle but didn't beat the game..." -icon question
            }
            correcter {
                messageBox -title "You won!" -message "You are a true champion."
            }
        }
    }

    method copy {} {
        set string ""
        for {set i 0} {$i < 9} {incr i} {
            for {set j 0} {$j < 9} {incr j} {
                set value [$game getValue $i$j]
                set string ${string}${value}
            }
        }
        clipboard clear
        clipboard append $string
    }

    method paste {} {
        if {[catch {clipboard get} contents]} {
            return
        }
        set contents [string map {. 0} $contents]
        set cells [regexp -all -inline {\d|\[[\d ]*?\]} $contents]
        for {set i 0} {$i < 9} {incr i} {
            for {set j 0} {$j < 9} {incr j} {
                set value [lindex $cells [expr {$i * 9 + $j}]]
                if {[string length $value] == 1} {
                    $game setValue $i$j $value true
                } else {
                    foreach candidate [regexp -all -inline {\d} $value] {
                        $game addCandidate $i$j $candidate
                    }
                }
            }
        }
        redraw
    }
}
