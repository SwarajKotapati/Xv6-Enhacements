#include "types.h"
#include "param.h"
#include "layout.h"
#include "riscv.h"
#include "defs.h"
#include "buf.h"
#include "elf.h"

#include <stdbool.h>

struct elfhdr* kernel_elfhdr;
struct proghdr* kernel_phdr;

uint64 find_kernel_load_addr(enum kernel ktype) {
    /* CSE 536: Get kernel load address from headers */
    
    uint64 addr = 0x84000000;
    if(ktype == RECOVERY){
    	addr = 0x84500000;
    }
    
    kernel_elfhdr = (struct elfhdr*)(addr);
    uint64 lphoff = kernel_elfhdr->phoff;
    ushort lphsize = kernel_elfhdr->phentsize;
    
    kernel_phdr = (struct proghdr*)(addr + lphoff + lphsize);
    uint64 lstart_address = kernel_phdr->vaddr;
    
    return lstart_address;
}

uint64 find_kernel_size(enum kernel ktype) {
    
    uint64 addr = 0x84000000;
    if(ktype == RECOVERY){
    	addr = 0x84500000;
    }
    
    kernel_elfhdr = (struct elfhdr*)(addr);
    return (kernel_elfhdr->shentsize * kernel_elfhdr->shnum) + kernel_elfhdr->shoff;
}

uint64 find_kernel_entry_addr(enum kernel ktype) {
    /* CSE 536: Get kernel entry point from headers */
    
    uint64 addr = 0x84000000;
    if(ktype == RECOVERY){
    	addr = 0x84500000;
    }
    
    kernel_elfhdr = (struct elfhdr*)(addr);
    return kernel_elfhdr->entry;
}
