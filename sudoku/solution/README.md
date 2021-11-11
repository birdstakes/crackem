# Sudoku solution

Examining the binary reveals that it is a Tcl
[starpack](https://wiki.tcl-lang.org/page/Starpack) built with a
[tclkit](https://wiki.tcl-lang.org/page/Tclkit). It contains a virtual
filesystem that can be extracted with [sdx](https://wiki.tcl-lang.org/page/sdx):

```
>tclkitsh.exe sdx.kit unwrap sudoku.exe
1020 updates applied
```

After unpacking the virtual filesystem, a method called `checkWin` can be found
in `lib/app/app.tcl`:

```tcl
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
```


To beat the game, `::sudoku::Sudoku::state` in `lib/sudoku/sudoku.tcl` needs to
return `correcter`.

```tcl
    method state {} {

        # ...

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
```

The end of this method interprets the candidates in each cell as a 9-bit
integer, where the presence of a candidate corresponds to a bit being set. These
integers are then passed to a function called `check`, whose implementation can
be found in `lib/check/check.dll`. After some reversing it can be seen that it
implements a simple virtual machine. Every instruction is a 9-bit word
consisting of a 3-bit opcode in the lowest bits followed by two operands, each
of which is a 3-bit number representing a register from `r0` to `r7`. The
address space consists of 512 9-bit words, the first 81 of which come from the
numbers passed to `check` and make up the program to be executed.

The following opcodes are recognized by the virtual machine:

| Opcode | Instruction  | Operation                                              |
| ------ | ------------ | ------------------------------------------------------ |
| 0      | LD  dst, src | Load the value at the address in src into dst          |
| 1      | STR dst, src | Store the value in src at the address in dst           |
| 2      | ADD dst, src | Add src to dst                                         |
| 3      | AND dst, src | Bitwise AND dst with src                               |
| 4      | OR  dst, src | Bitwise OR dst with src                                |
| 5      | NOT dst, src | Bitwise NOT src, storing the result in dst             |
| 6      | NZ  dst, src | Set dst to 1 if src is nonzero, otherwise set dst to 0 |
| 7      | NOP dst, src | Do nothing                                             |

Note that there are no instructions taking immediate values as operands, no
branching instructions, and no comparison instructions other than NZ.

With no immediate operands, register values will have to be computed or loaded
from memory.

The lack of branching instructions can be overcome by storing values directing
into the program counter, `r7` (henceforth referred to as `pc`). A convenient
way to branch to a constant address is with the instruction `LD pc, pc` followed
directly by the address. This works because the program counter always points to
the word after the current instruction.

Comparison can be done by subtracting and checking the sign of the result. There
is no subtraction instruction, but `a - b` can still easily be computed by
adding the two's complement of `b` to `a`. The two's complement of a number is
found by inverting each bit of the number and adding 1. Checking the sign of the
result is then a matter of examining the most significant bit.

As the program counter points to the word after the current instruction, `pc`
will practically always be nonzero. The only time this is not the case is when
the address of the current instruction is 511. This means that `NZ dst, pc` can
be used to set `dst` to 1.

```
AND dst, src
OR dst, src
```

copies `src` into `dst`.

```
NZ tmp, pc
NOT dst, src
ADD dst, tmp
```

stores the negated value of `src` in `dst` (clobbering some other register `tmp`
in the process), and so

```
NZ tmp, pc
NOT src, src
ADD src, tmp
ADD dst, src
```

subtracts `src` from `dst`, though it will overwrite `src` in the process.

```
LD tmp, pc
<0b011111111>
NOT tmp, tmp
AND dst, tmp
NZ dst, dst
```

replaces `dst` with 1 if it is negative and 0 otherwise. The constant
0b011111111 will be interpreted as a `NOP`.

An implementation of conditional branching sets `pc` depending whether some
register `cond` is zero or nonzero.

```
LD tmp, pc
<3>
ADD tmp, pc
NZ cond, cond
ADD tmp, cond
LD pc, tmp
<else>
<then>
```

The value 3 is interpreted as `AND r0, r0`, effectively a `NOP`. After adding
`pc`, `tmp` points to `else` and `then`, which are pointers to the code to
branch to.

Returning to `check.dll`, before the program is run a list of numbers is
randomly generated and stored in the virtual machine's memory at address 100.
`r0` is set to the address of the list, `r1` is set to its length, and the
program is run. When it is done the list in memory is compared with a sorted
version of the original list. If the lists do not match then `check` fails.

[sort.asm](sort.asm) is an implementation of insertion sort that has been
slightly modified to be easier to write with the primitives developed above.

[vm.asm](vm.asm) is included by `sort.asm` and contains rules for the
[customasm](https://github.com/hlorenzi/customasm) assembler.

[vm.py](vm.py) assembles a program with customasm and runs it or dumps it in
a format that can be pasted into `sudoku.exe`.
