#!/usr/bin/env python3
import argparse
import enum
import random
import subprocess

class Op(enum.IntEnum):
    LD = 0
    STR = 1
    ADD = 2
    AND = 3
    OR = 4
    NOT = 5
    NZ = 6
    UNDEF = 7

def disassemble(program, pc):
    opcode = Op(program[pc] & 7)
    operands = (program[pc] >> 3) & 7, (program[pc] >> 6) & 7
    pc = (pc + 1) & 511
    return opcode, operands, pc

def assemble(program):
    bits = subprocess.check_output(
        [ 'customasm', '-p', '-f', 'binstr', program]
    ).splitlines()[-1]

    return [int(bits[i:i+9], 2) for i in range(0, len(bits), 9)]

def run(program):
    mem = program + [0] * (2**9 - len(program))
    regs = [0] * 8
    mask = 2**9 - 1

    nums = random.sample(range(255), 30)
    mem[100:100 + len(nums)] = nums
    regs[0] = 100
    regs[1] = len(nums)

    for i in range(30000):
        old_pc = regs[7]
        op, ops, regs[7] = disassemble(mem, regs[7])
        pretty_regs = ' '.join(f'{reg:4}' for reg in regs)
        print(f'{old_pc:<3}: {op.name:5} r{ops[0]}, r{ops[1]} | {pretty_regs}')

        if op == Op.LD:
            regs[ops[0]] = mem[regs[ops[1]]]
        elif op == Op.STR:
            mem[regs[ops[0]]] = regs[ops[1]]
        elif op == Op.ADD:
            regs[ops[0]] += regs[ops[1]]
            regs[ops[0]] &= mask
        elif op == Op.AND:
            regs[ops[0]] &= regs[ops[1]]
        elif op == Op.OR:
            regs[ops[0]] |= regs[ops[1]]
        elif op == Op.NOT:
            regs[ops[0]] = (~regs[ops[1]]) & mask
        elif op == Op.NZ:
            regs[ops[0]] = int(regs[ops[1]] != 0)

        if regs[7] == old_pc:
            print('halting')
            break

    result = mem[100:100+len(nums)]
    print(result)
    print(sorted(nums))
    print(result == sorted(nums))

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('command', choices=['assemble', 'run'])
    parser.add_argument('program')
    args = parser.parse_args()

    if args.command == 'assemble':
        program = assemble(args.program)
        print(f'Assembled {len(program)} words')

        s = ''
        for word in program:
            s += '['
            for i in range(9):
                if word & (1 << i):
                    s += str(i + 1)
            s += ']'
        print(s)

    elif args.command == 'run':
        run(assemble(args.program))

if __name__ == '__main__':
    main()
