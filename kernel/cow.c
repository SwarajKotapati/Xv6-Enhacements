#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"
#include "elf.h"
#include <stdbool.h>

struct spinlock cow_lock;

// Max number of pages a CoW group of processes can share
#define SHMEM_MAX 100

struct cow_group {
    int group; // group id
    uint64 shmem[SHMEM_MAX]; // list of pages a CoW group share
    int count; // Number of active processes
};

struct cow_group cow_group[NPROC];

struct cow_group* get_cow_group(int group) {
    if(group == -1)
        return 0;

    for(int i = 0; i < NPROC; i++) {
        if(cow_group[i].group == group)
            return &cow_group[i];
    }
    return 0;
}

void cow_group_init(int groupno) {
    for(int i = 0; i < NPROC; i++) {
        if(cow_group[i].group == -1) {
            cow_group[i].group = groupno;
            return;
        }
    }
} 

int get_cow_group_count(int group) {
    return get_cow_group(group)->count;
}
void incr_cow_group_count(int group) {
    get_cow_group(group)->count = get_cow_group_count(group)+1;
}
void decr_cow_group_count(int group) {
    get_cow_group(group)->count = get_cow_group_count(group)-1;
}

void add_shmem(int group, uint64 pa) {
    if(group == -1)
        return;

    uint64 *shmem = get_cow_group(group)->shmem;
    int index;
    for(index = 0; index < SHMEM_MAX; index++) {
        // duplicate address
        if(shmem[index] == pa)
            return;
        if(shmem[index] == 0)
            break;
    }
    shmem[index] = pa;
}

int is_shmem(int group, uint64 pa) {
    if(group == -1)
        return 0;

    uint64 *shmem = get_cow_group(group)->shmem;
    for(int i = 0; i < SHMEM_MAX; i++) {
        if(shmem[i] == 0)
            return 0;
        if(shmem[i] == pa)
            return 1;
    }
    return 0;
}

void cow_init() {
    for(int i = 0; i < NPROC; i++) {
        cow_group[i].count = 0;
        cow_group[i].group = -1;
        for(int j = 0; j < SHMEM_MAX; j++)
            cow_group[i].shmem[j] = 0;
    }
    initlock(&cow_lock, "cow_lock");
}

int uvmcopy_cow(pagetable_t old, pagetable_t new, uint64 sz) {
    
    /* CSE 536: (2.6.1) Handling Copy-on-write fork() */
    pte_t *pte;
    uint64 pa, i;
    uint flags;
    char *mem;
    struct proc *p = myproc();

    for(i = 0; i < sz; i += PGSIZE){
        if((pte = walk(old, i, 0)) == 0)
            panic("uvmcopy_cow: pte should exist");
        if((*pte & PTE_V) == 0)
            panic("uvmcopy_cow: page not present");
        pa = PTE2PA(*pte);
        *pte &= ~PTE_W; // Updating parent flag to be readonly
        flags = PTE_FLAGS(*pte);
        
        if(mappages(new, i, PGSIZE, pa, flags) != 0){ 
          goto err;
         }
         
        if(is_shmem(p->cow_group,pa) == 0){
            add_shmem(p->cow_group,pa);
        }
    }
    return 0;

    // Copy user vitual memory from old(parent) to new(child) process
    // Map pages as Read-Only in both the processes

    err:
        uvmunmap(new, 0, i / PGSIZE, 1);
        return -1;
}

void copy_on_write() {
    /* CSE 536: (2.6.2) Handling Copy-on-write */
    
    //printf("\ncopy_on_write : entry");
    struct proc *p = myproc();
    uint flags;
    
    // Allocate a new page 
    uchar *newpage;
    if((newpage = kalloc()) == 0)
      panic("copy_on_write kalloc operation");
    
    
    uint64 stval = r_stval();
    uint64 offset_mask = (1ULL << 12) - 1; 
    uint64 faulting_addr = stval & ~offset_mask;
    
    pte_t *pte;
    
    for(int i = 0;  i < 100000000; i++){}
    //printf("\nFaulting addr %x\n",faulting_addr);
    
    if((pte = walk(p->pagetable, faulting_addr, 0)) == 0)
        panic("copy_on_write: pte should exist");
    //printf("Walk done\n");
    
    if((*pte & PTE_V) == 0)
        panic("copy_on_write: page not present");
    //printf("Second if done\n");
    
    uchar* sharedpage = PTE2PA(*pte);
    //printf("3 done\n");
    flags = PTE_FLAGS(*pte);
    
    //printf("4 done\n");
     
    // Copy contents from the shared page to the new page
    if(memmove(newpage, (uchar*)sharedpage, PGSIZE) < 0){
      panic("copy_on_write memmove function");
    }
    //printf("\n pid %x,faddr %x,newpage %x,shared page %x,flag&PTW_w %x,proces cow group %x, get_cow_group_count %x\n",
          //p->pid,faulting_addr,newpage,sharedpage,flags&PTE_W,p->cow_group,get_cow_group_count(p->cow_group));
    
    *pte = PA2PTE(newpage) | flags | PTE_W;
    int newflag = PTE_FLAGS(*pte);
    
    
    //printf("\n pid %x,faddr %x,ptetopa %x,shared page %x,flag&PTW_w %x,proces cow group %x, get_cow_group_count %x\n",
          //p->pid,faulting_addr,PTE2PA(*pte),sharedpage,newflag&PTE_W,p->cow_group,get_cow_group_count(p->cow_group));
    
    print_copy_on_write(p,faulting_addr);
    //printf("7 done\n");
    
}
