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

    plus {dst: register} => asm {
        nz {dst}, pc
    }

    minus {dst: register} => asm {
        ld {dst}, pc
    } @ 0b111111111

    push {src: register} => asm {
        str sp, {src}
        add sp, spinc
    }

    pop {dst: register} => asm {
        add sp, spinc
        ld {dst}, sp
    }
}
