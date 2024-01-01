/* This file contains code for a generic page fault handler for processes. */
#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"
#include "elf.h"

#include "sleeplock.h"
#include "fs.h"
#include "buf.h"

int loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz);
int flags2perm(int flags);

/* CSE 536: (2.4) read current time. */
uint64 read_current_timestamp() {
  uint64 curticks = 0;
  acquire(&tickslock);
  curticks = ticks;
  wakeup(&ticks);
  release(&tickslock);
  return curticks;
}

bool psa_tracker[PSASIZE];
uint64 tempPFaddr;
int count = 1;

/* All blocks are free during initialization. */
void init_psa_regions(void)
{
    for (int i = 0; i < PSASIZE; i++) 
        psa_tracker[i] = false;
}

/* Evict heap page to disk when resident pages exceed limit */
void evict_page_to_disk(struct proc* p) {
    /* Find free block */
    int blockno = 0;
    
    // Finding the free PSA block
    for(int i = 0 ; i < PSASIZE; i++){
    	
    	if(psa_tracker[i] == false){
    	   
    	   uint64 flag = 0;
    	   
    	   for(int j = 0; j < 4 ; j++){
    	       if(psa_tracker[i+j] == true){
    	           flag = 1;
    	           break;
    	       }    
    	   }
    	   
    	   if(flag == 0){
    	       blockno = i;
    	       break;
    	   }
    	}
    }
    
    // Assigning the blockno to startblock variable
    
    /* Find victim page using FIFO. */
    
    uint64 least_time = 0xFFFFFFFFFFFFFFFF; // MAX value
    uint64 victim_addr;
    
    for (int i = 0; i < MAXHEAP; i++) {
    	if (p->heap_tracker[i].last_load_time < least_time && p->heap_tracker[i].loaded == 1) {
            least_time = p->heap_tracker[i].last_load_time;
            victim_addr = p->heap_tracker[i].addr;
       } 
    }
    
    int working_set_algo = 0; // Set the value from 0 to 1 to implement working set algorithm.
    if(working_set_algo){
    
      //printf("Working set func entry\n");
        
    	for(int i = 0 ; i < MAXHEAP; i++){
           if(p->heap_tracker[i].loaded){
              
	         //printf("Difference is %d\n",read_current_timestamp()-p->heap_tracker[i].last_load_time);
                 
                 if(read_current_timestamp()-p->heap_tracker[i].last_load_time >= 1 && p->heap_tracker[i].addr){
                   //printf("\nWorking set 123\n");
                   //printf("heap tracker addr %x \n", p->heap_tracker[i].addr); 
		   victim_addr = p->heap_tracker[i].addr;
		   //printf("victim addr working set %x \n", victim_addr); 
		   break;
              }

      }
      
      
    }
    }

    
    
    //printf("\nVictim Page Address %x \n",victim_addr);
    
    for (int i = 0; i < MAXHEAP; i++) {
    	if (p->heap_tracker[i].addr == victim_addr) {
            p->heap_tracker[i].startblock = blockno;
       } 
    }
    
    // Updating the blocks to true as they are now currently being used
    
    
    
    uchar *kernel_page = kalloc();
    
    // Copying from process's address space to kernel space
    if(copyin(p->pagetable, (uchar *)kernel_page, victim_addr, 4096) != -1)
        //printf("Copy from address space to kernel");
    
    /* Print statement. */
    print_evict_page(victim_addr, blockno);
    
    
    /* Write to the disk blocks. Below is a template as to how this works. There is
     * definitely a better way but this works for now. :p */
    struct buf* b;
    b = bread(1, PSASTART+(blockno));
    // Copy page contents to b.data using memmove.
    memmove(b->data,(uchar *)kernel_page, BSIZE);
    bwrite(b);
    brelse(b);
    
    b = bread(1, PSASTART+(blockno + 1));
    memmove(b->data,(uchar *)kernel_page + 1024, BSIZE);
    bwrite(b);
    brelse(b);
    
    b = bread(1, PSASTART+(blockno + 2));
    memmove(b->data,(uchar *)kernel_page + 2048, BSIZE);
    bwrite(b);
    brelse(b);
    
    b = bread(1, PSASTART+(blockno + 3));
    memmove(b->data,(uchar *)kernel_page + 3072, BSIZE);
    bwrite(b);
    brelse(b);


    /* Unmap swapped out page */
    uvmunmap(p->pagetable,victim_addr,1,0);
    
    /* Update the resident heap tracker. */
    p->resident_heap_pages--;
    for (int i = 0; i < MAXHEAP; i++) {
    	if (p->heap_tracker[i].addr == victim_addr) {
            p->heap_tracker[i].loaded = false;
       } 
    }
    
    for(int i = 0 ; i < 4; i++){
    	psa_tracker[blockno+i] = true;
    }
    
    //printf("\n After Evict resident_pages %d \n",p->resident_heap_pages);
    
}

/* Retrieve faulted page from disk. */
void retrieve_page_from_disk(struct proc* p, uint64 uvaddr) {
    /* Find where the page is located in disk */
    
    //printf("\nRetrieve_from_disk_func\n");
    uint64 blockno = 0;
    
    for (int i = 0; i < MAXHEAP; i++) {
    	if (p->heap_tracker[i].startblock != -1 && p->heap_tracker[i].addr == uvaddr) {
            blockno = p->heap_tracker[i].startblock;
            break;
       } 
    }
    
    //printf("blockno %d\n",blockno);
    
    
    /* Print statement. */
    print_retrieve_page(uvaddr, blockno);

    /* Create a kernel page to read memory temporarily into first. */
    uchar *kernel_page = kalloc();
    
    /* Read the disk block into temp kernel page. */
    struct buf* b;
    b = bread(1, PSASTART+(blockno));
    memmove((uchar *)kernel_page, b->data ,1024);
    brelse(b);
    
    b = bread(1, PSASTART+(blockno + 1));
    memmove((uchar *)kernel_page + 1024, b->data ,1024);
    brelse(b);
    
    b = bread(1, PSASTART+(blockno + 2));
    memmove((uchar *)kernel_page + 2048, b->data ,1024);
    brelse(b);
    
    b = bread(1, PSASTART+(blockno + 3));
    memmove((uchar *)kernel_page + 3072, b->data ,1024);
    brelse(b);
    

    /* Copy from temp kernel page to uvaddr (use copyout) */
    //copyout(p->pagetable, dst, src, len);
    copyout(p->pagetable, uvaddr, kernel_page,4096);
    
    // Updating the blocks to true as they are now currently being used
    for(int i = 0 ; i < 4; i++){
    	psa_tracker[blockno+i] = false;
    }
    
    for (int i = 0; i < MAXHEAP; i++) {
    	if (p->heap_tracker[i].addr == uvaddr) {
            p->heap_tracker[i].access = 1;
            break;
       } 
    }
}


void page_fault_handler(void) 
{

    //printf("\nPage fault handler function entry");
    struct elfhdr elf;
    struct inode *ip;
    struct proghdr ph;
    pagetable_t pagetable = 0;// oldpagetable;
    struct proc *p = myproc();
    // uint64 sz = 0;
    /* Current process struct */
    
    /* Track whether the heap page should be brought back from disk or not. */
    bool load_from_disk = false;
    
    

    /* Find faulting address. */
    
    //printf("PageFaultHandler");
    //printf("\n");
    
    uint64 stval = r_stval();
    uint64 offset_mask = (1ULL << 12) - 1; 
    uint64 faulting_addr = stval & ~offset_mask;
    uint64 PFaddr = faulting_addr;
    tempPFaddr = faulting_addr;
    
    
    //printf("Stval %x \n", stval);
    print_page_fault(p->name, faulting_addr);
    ////printf("Hey Bottom \n");
    
    if(p->cow_enabled == 1){
    	//printf("\n Cow enabled pfault entry.c\n");
        copy_on_write();
        //printf("\n Cow enabled pfault exit.c\n");
        goto out;
    }

    /* Check if the fault address is a heap page. Use p->heap_tracker */
    
    uint64 flag = 0;
    for (int i = 0; i < MAXHEAP; i++) {
    if (p->heap_tracker[i].addr == PFaddr) {
            flag = 1;
       } 
    }
    
    if (flag == 1) {
	    for (int i = 0; i < MAXHEAP; i++) {
	    	if (p->heap_tracker[i].startblock != -1 && psa_tracker[p->heap_tracker[i].startblock] == true && p->heap_tracker[i].addr == PFaddr) {
	    	    //printf("\n Load from disk index : %d startblock : %d address %x",i,p->heap_tracker[i].startblock, p->heap_tracker[i].addr); 
		    load_from_disk = true;
		    break;
	       } 
	    }
      goto heap_handle;
    }
    
    if((ip = namei(p->name)) == 0){
       end_op();
       goto bad;
    }
    ilock(ip);
  
    if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
       goto bad;

    //if(elf.magic != ELF_MAGIC)
      // goto bad;

    

    /* If it came here, it is a page from the program binary that we must load. */
     for (int i = 0, off = elf.phoff; i < elf.phnum; i++, off += sizeof(ph)) {
        if (readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
            goto bad;
        
        // Check if this is a program segment we are interested in (e.g., based on PFaddr)
        if (ph.type != ELF_PROG_LOAD)
            continue;
            
        //printf("For Loop \n");
        //printf("ph.vaddr %x",ph.vaddr);
        //printf("ph.memsz %x",ph.memsz);
        //printf("PFaddr %x",PFaddr);
        
        uint64 sz1;
        
        // Check if PFaddr is within this segment
        if (PFaddr >= ph.vaddr && PFaddr < (ph.vaddr + ph.memsz)) {
        	
            //printf("If Condition \n");
            
            if((sz1 = uvmalloc(p->pagetable, PFaddr, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    	       goto bad;
    	    // sz = sz1;
    	    
    	    if(loadseg(p->pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    	      goto bad;
    	      
    	      print_load_seg(PFaddr,ph.off,ph.filesz);
    	      break;
    	      

        }
    }
    
    iunlockput(ip);
    //end_op();
    //ip = 0;

    //p = myproc();

    /* Go to out, since the remainder of this code is for the heap. */
    goto out;

heap_handle:
    /* 2.4: Check if resident pages are more than heap pages. If yes, evict. */
    
    
    
    //printf("\nResident_heap_pages %d\n", p->resident_heap_pages);
    if (p->resident_heap_pages == MAXRESHEAP) {
        //printf("\nHeap_handle if condition\n");
        evict_page_to_disk(p);
        
    }

    /* 2.3: Map a heap page into the process' address space. (Hint: check growproc) */
    uint64 newsize = uvmalloc(p->pagetable, PFaddr, PFaddr + 4096, PTE_W);
    //printf("Without update size %x & With update %x ",p->sz,newsize);
    
    if(!load_from_disk){
    	p->sz = newsize;
    }

    /* 2.4: Update the last load time for the loaded heap page in p->heap_tracker. */
    uint64 current_time = read_current_timestamp();
      	for (int i = 0; i < MAXHEAP; i++) {
    	    if (p->heap_tracker[i].addr == PFaddr) {
                p->heap_tracker[i].last_load_time = current_time;
           } 
    }

    /* 2.4: Heap page was swapped to disk previously. We must load it from disk. */
    if (load_from_disk) {
        retrieve_page_from_disk(p, faulting_addr);
        //load_from_disk_flag = 0;
    }

    /* Track that another heap page has been brought into memory. */
    p->resident_heap_pages++;
    for (int i = 0; i < MAXHEAP; i++) {
    	    if (p->heap_tracker[i].addr == PFaddr) {
                p->heap_tracker[i].loaded = 1;
           } 
    }
    
    goto out;

out:
    /* Flush stale page table entries. This is important to always do. */
    sfence_vma();
    return;
    
  bad:
  //printf("Bad");
  if(pagetable)
    proc_freepagetable(pagetable, PFaddr);
  if(ip){
    iunlockput(ip);
    end_op();
  }
  return;
}
