#bits 9

#subruledef register
{
    r{n: u3} => n
    spinc    => 0b101
    sp       => 0b110
    pc       => 0b111
}

#subruledef opcode
{
    ld  => 0b000
    str => 0b001
    add => 0b010
    and => 0b011
    or  => 0b100
    not => 0b101
    nz  => 0b110
}

#ruledef instruction
{
    {op: opcode} {dst: register}, {src: register} => src @ dst @ op
}

#ruledef pseudoinstruction {
    jmp {target: u9} => asm {
        ld pc, pc
    } @ target

    mov {dst: register}, {src: register} => asm {
        and {dst}, {src}
        or {dst}, {src}
    }

    mov {dst: register}, 1 => asm {
        nz {dst}, pc
    }

    mov {dst: register}, -1 => asm {
        ld {dst}, pc
    } @ 0b111111111 ; -1 isn't a valid instruction and will be ignored

    if {cond: register} then {then: u9} else {else: u9}, clobber {scratch: register} => {
        assert(scratch != cond)
        asm {
            ; scratch = 3
            ; and r0, r0 is encoded as 3 and does nothing
            ld {scratch}, pc
            and r0, r0

            ; pc is always the next instruction, so now scratch points to else and then
            add {scratch}, pc

            ; pc = the array [else, then] indexed by (cond != 0)
            nz {cond}, {cond}
            add {scratch}, {cond}
            ld pc, {scratch}
        } @ else @ then
    }

    neg {dst: register}, {src: register}, clobber {scratch: register} => {
        assert(scratch != dst && scratch != src)
        asm {
            mov {scratch}, 1
            not {dst}, {src}
            add {dst}, {scratch}
        }
    }

    ; subtract and leave src negated
    sub nosave {dst: register}, {src: register}, clobber {scratch: register} => {
        assert(scratch != dst && scratch != src)
        asm {
            neg {src}, {src}, clobber {scratch}
            add {dst}, {src}
        }
    }

    sub {dst: register}, {a: register}, {b: register}, clobber {scratch: register} => {
        assert(dst != a && dst != b && dst != scratch)
        assert(a != b && a != scratch)
        assert(b != scratch)
        asm {
            neg {scratch}, {b}, clobber {dst}
            mov {dst}, {a}
            add {dst}, {scratch}
        }
    }

    inc {reg: register}, clobber {scratch: register} => {
        assert(scratch != reg)
        asm {
            mov {scratch}, 1
            add {reg}, {scratch}
        }
    }

    dec {reg: register}, clobber {scratch: register} => {
        assert(scratch != reg)
        asm {
            mov {scratch}, -1
            add {reg}, {scratch}
        }
    }

    ltz {reg: register}, clobber {scratch: register} => {
        assert(scratch != reg)
        ; check sign bit by ANDing reg with (1 << 9)
        ; 0b011111111 is not a valid instruction and will be ignored
        asm {
            ld {scratch}, pc
        } @ 0b011111111 @ asm {
            not {scratch}, {scratch}
            and {reg}, {scratch}
        }
    }
}
