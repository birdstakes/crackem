#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <tcl.h>

enum {
    OP_LD,
    OP_STR,
    OP_ADD,
    OP_AND,
    OP_OR,
    OP_NOT,
    OP_NZ,
};

#define NUM_REGS 8
#define PC 7
#define MEM_SIZE (1 << 9)
#define MEM_MASK (MEM_SIZE - 1)

static void interpret(uint16_t *mem, uint16_t *regs) {
    for(int i = 0; i < 30000; i++) {
        uint16_t instruction = mem[regs[PC]++];
        uint16_t opcode = instruction & 7;
        uint16_t a = (instruction >> 3) & 7;
        uint16_t b = (instruction >> 6) & 7;
        regs[PC] &= MEM_MASK;

        switch(opcode) {
            case OP_LD:
                regs[a] = mem[regs[b]];
                break;

            case OP_STR:
                mem[regs[a]] = regs[b];
                break;

            case OP_ADD:
                regs[a] = (regs[a] + regs[b]) & MEM_MASK;
                break;

            case OP_AND:
                regs[a] &= regs[b];
                break;

            case OP_OR:
                regs[a] |= regs[b];
                break;

            case OP_NOT:
                regs[a] = ~regs[b] & MEM_MASK;
                break;

            case OP_NZ:
                regs[a] = !!regs[b];
                break;

            default:
                break;
        }
    }
}

static int compare(const void *a, const void *b) {
    uint16_t x = *(uint16_t *)a;
    uint16_t y = *(uint16_t *)b;
    return (x > y) - (x < y);
}

static int check_proc(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]) {
    uint16_t program[MEM_SIZE] = {0};
    uint16_t mem[MEM_SIZE] = {0}, regs[NUM_REGS] = {0};

    if(objc != 2) {
        return TCL_ERROR;
    }

    int length;
    if(Tcl_ListObjLength(interp, objv[1], &length) != TCL_OK) {
        return TCL_ERROR;
    }

    for(int i = 0; i < length && i < MEM_SIZE; i++) {
        Tcl_Obj *obj;
        int value;

        Tcl_ListObjIndex(interp, objv[1], i, &obj);
        if(Tcl_GetIntFromObj(interp, obj, &value) != TCL_OK) {
            return TCL_ERROR;
        }
        program[i] = value & MEM_MASK;
    }

    for(int i = 0; i < 100; i++) {
        memcpy(mem, program, sizeof(mem));
        memset(regs, 0, sizeof(regs));

        const size_t address = 100;
        const size_t length = 30;
        uint16_t nums[length];

        for(size_t j = 0; j < length; j++) {
            nums[j] = rand() & 255;
        }
        memcpy(&mem[address], nums, sizeof(nums));

        regs[0] = address;
        regs[1] = length;
        interpret(mem, regs);

        qsort(nums, length, sizeof(nums[0]), compare);
        if(memcmp(&mem[address], nums, sizeof(nums)) != 0) {
            Tcl_SetResult(interp, "0", TCL_STATIC);
            return TCL_OK;
        }
    }

    Tcl_SetResult(interp, "1", TCL_STATIC);
    return TCL_OK;
}

int Check_Init(Tcl_Interp *interp) {
    if(Tcl_InitStubs(interp, "8.6", 0) == NULL) {
        return TCL_ERROR;
    }

    if(Tcl_PkgProvide(interp, "check", "1.0") != TCL_OK) {
        return TCL_ERROR;
    }

    Tcl_CreateObjCommand(interp, "check", check_proc, NULL, NULL);
    return TCL_OK;
}
