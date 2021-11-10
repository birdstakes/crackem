package provide sudoku 1.0

package require Itcl
package require check

namespace eval ::sudoku {
    namespace export Sudoku
}

::itcl::class ::sudoku::Cell {
    variable value
    variable given
    variable candidates

    constructor {{value_ 0} {given_ false}} {
        clear
        set value $value_
        set given $given_
    }

    method clear {} {
        set value 0
        set given false
        for {set candidate 1} {$candidate <= 9} {incr candidate} {
            set candidates($candidate) false
        }
    }

    method getValue {} {
        return $value
    }

    method setValue {value_ {given_ false}} {
        if {$value_ == 0 && $given_} {
            set given_ false
        }
        if {!$given || $given_} {
            set value $value_
            set given $given_
        }
    }

    method isEmpty {} {
        expr {$value == 0}
    }

    method isGiven {} {
        expr {$given}
    }

    method hasCandidate {candidate} {
        expr {$candidates($candidate)}
    }

    method addCandidate {candidate} {
        set candidates($candidate) true
    }

    method removeCandidate {candidate} {
        set candidates($candidate) false
    }

    method toggleCandidate {candidate} {
        set candidates($candidate) [expr {!$candidates($candidate)}]
    }
}

::itcl::class ::sudoku::Sudoku {
    variable cells

    constructor {} {
        for {set i 0} {$i < 9} {incr i} {
            for {set j 0} {$j < 9} {incr j} {
                dict set cells $i$j [::sudoku::Cell #auto]
            }
        }
    }

    private method cellAt {location} {
        dict get $cells $location
    }

    method state {} {
        dict for {location cell} $cells {
            if {[$cell isEmpty]} {
                return incomplete
            }
        }

        for {set i 0} {$i < 9} {incr i} {
            array unset seenInRow
            array unset seenInColumn
            array unset seenInBlock
            for {set j 0} {$j < 9} {incr j} {
                set blockRow [expr {$i / 3 * 3 + $j / 3}]
                set blockColumn [expr {$i * 3 % 9 + $j % 3}]
                set rowValue [getValue $i$j]
                set columnValue [getValue $j$i]
                set blockValue [getValue ${blockRow}${blockColumn}]

                if {[info exists seenInRow($rowValue)]} {
                    return incorrect
                }

                if {[info exists seenInColumn($columnValue)]} {
                    return incorrect
                }

                if {[info exists seenInBlock($blockValue)]} {
                    return incorrect
                }

                set seenInRow($rowValue) true
                set seenInColumn($columnValue) true
                set seenInBlock($blockValue) true
            }
        }

        set values {}
        dict for {location cell} $cells {
            set value 0
            for {set k 1} {$k <= 9} {incr k} {
                incr value [expr {!![hasCandidate $location $k] << ($k - 1)}]
            }
            lappend values $value
        }

        if {[check $values]} {
            return correcter
        } else {
            return correct
        }
    }

    method clear {} {
        dict for {location cell} $cells {
            $cell clear
        }
    }

    method getValue {location} {
        [cellAt $location] getValue
    }

    method setValue {location args} {
        [cellAt $location] setValue {*}$args
    }

    method isEmpty {location} {
        [cellAt $location] isEmpty
    }

    method isGiven {location} {
        [cellAt $location] isGiven
    }

    method hasCandidate {location candidate} {
        [cellAt $location] hasCandidate $candidate
    }

    method addCandidate {location candidate} {
        [cellAt $location] addCandidate $candidate
    }

    method removeCandidate {location candidate} {
        [cellAt $location] removeCandidate $candidate
    }

    method toggleCandidate {location candidate} {
        [cellAt $location] toggleCandidate $candidate
    }
}
