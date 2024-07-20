#include <cstdint>
#include <cstdio>
#include <verilated.h>
#include "Vtop_exp_ahb.h"
#include "Vtop_exp_ahb___024root.h"

Vtop_exp_ahb *top;

unsigned char memory[1024*1024];

enum HTRANS {
  IDLE = 0b00,
  BUSY = 0b01,
  NONSEQ = 0b10,
  SEQ = 0b11
};

enum HSIZE {
  BYTE = 0b00,
  HALFWORD = 0b01,
  WORD = 0b10
};

const uint32_t SCR1_SIM_PRINT_ADDR = 0xF0000000;
const uint32_t SCR1_SIM_EXIT_ADDR = 0x000000F8;

uint32_t memread(uint32_t address, uint8_t size) {
  uint32_t ret = 0;
  switch (size) {
  case BYTE: {
    /* printf("requested 1 byte at 0x%010X. Memory is 0x%02X\n", address, memory[address]); */
    ret = memory[address];
    break;
  }
  case HALFWORD: {
    /* printf("requested 2 bytes at 0x%010X. Memory is 0x%02X 0x%02X\n", address, memory[address], memory[address + 1]); */
    ret = (memory[address + 1] << 8) + memory[address];
    break;
  }
  case WORD: {
    /* printf("requested 4 bytes at 0x%010X. Memory is 0x%02X 0x%02X 0x%02X 0x%02X\n", address, memory[address], memory[address + 1], */
    /*        memory[address + 2], memory[address + 3]); */
    ret = (((((memory[address + 3] << 8) + memory[address + 2]) << 8) + memory[address + 1]) << 8) + memory[address];
    break;
  }
  }
  /* printf("reading %hi (0x%08X)\n", ret, ret); */
  return ret;
}

void memwrite(uint32_t address, uint32_t value, uint8_t size) {
  switch (size) {
  case BYTE: {
    memory[address] = value;
    break;
  }
  case HALFWORD: {
    memory[address] = value;
    memory[address + 1] = value >> 8;
    break;
  }
  case WORD: {
    memory[address] = value;
    memory[address + 1] = value >> 8;
    memory[address + 2] = value >> 16;
    memory[address + 3] = value >> 24;
    break;
  }
  }
}

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);

  top = new Vtop_exp_ahb;

  FILE *fp = fopen("../hello.bin", "rb");
  fseek(fp , 0L , SEEK_END);
  long lSize = ftell(fp);
  rewind(fp);

  printf("file size is %li\n", lSize);

  fread(memory, lSize, 1, fp);

  bool do_write = false;
  uint32_t haddr;
  uint32_t hwdata;
  uint8_t hsize;

  int count = 0;
  while (top->rootp->top_exp_ahb__DOT__i_top__DOT__i_core_top__DOT__i_pipe_top__DOT__curr_pc != SCR1_SIM_EXIT_ADDR) {
    count++;
    auto clk_posedge = top->clk;

    if (clk_posedge) {
      top->imem_hrdata = 0;
      /* printf("i_addr: %i (0x%04X), imem_htrans: %i, imem_hsize: %i\n", top->imem_haddr, top->imem_haddr, top->imem_htrans, top->imem_hsize); */

      /* if (do_read) { */
      /*   top->imem_hrdata = memread(haddr, hsize); */
      /*   top->imem_hresp = 0; */
      /*   top->imem_hready = 1; */
      /*   do_read = false; */
      /* } */

      switch (top->imem_htrans) {
      case IDLE: {
        top->imem_hresp = 0;
        top->imem_hready = 1;
        break;
      }
      case NONSEQ: {
        top->imem_hrdata = memread(top->imem_haddr, top->imem_hsize);
        haddr = top->imem_haddr;
        hsize = top->imem_hsize;
        top->imem_hready = 1;
        top->imem_hresp = 0;
        break;
      }
      default: {
        exit(1);
      }
      }
    }

    if (clk_posedge) {
      /* printf("d_addr: %i (0x%04X), dmem_htrans: %i, dmem_hsize: %i, dmem_hwrite: %i\n", top->dmem_haddr, top->dmem_haddr, top->dmem_htrans, top->dmem_hsize, top->dmem_hwrite); */

      if (do_write) {
        do_write = false;
        if (haddr == SCR1_SIM_PRINT_ADDR) {
          printf("%c", top->dmem_hwdata);
        } else {
          memwrite(haddr, top->dmem_hwdata, hsize);
        }
      }

      switch (top->dmem_htrans) {
      case IDLE: {
        top->dmem_hresp = 0;
        top->dmem_hready = 1;
        break;
      }
      case NONSEQ: {
        if (!top->dmem_hwrite) {
          top->dmem_hrdata = memread(top->dmem_haddr, top->dmem_hsize);
          top->dmem_hresp = 0;
          top->dmem_hready = 1;
        } else {
          do_write = true;
          haddr = top->dmem_haddr;
          hsize = top->dmem_hsize;
          top->dmem_hresp = 0;
          top->dmem_hready = 1;
        }
        break;
      }
      default: {
        exit(1);
      }
      }
    }

    top->clk = !top->clk;
    top->eval();
  }
}
