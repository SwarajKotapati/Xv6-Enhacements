#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"
#include "registers.h"

// Struct to keep VM registers 
struct vm_reg {
    int code;
    enum vm_current_mode {
        MACHINE_MODE,
        SUPERVISOR_MODE,
        USER_MODE
    } mode;
    uint64 val;
};

uint64 pmp_flag = 0;

// Keep the virtual state of the VM's privileged registers
struct vm_virtual_state {
    
    // User trap setup
    uint64 ustatus;
    uint64 uie;
    uint64 utvec;
    
    // User trap handling
    uint64 uscratch;
    uint64 uepc;
    uint64 ucause;
    uint64 utval;
    uint64 uip;
    
    // Supervisor trap setup
    uint64 sstatus;
    uint64 sedeleg;
    uint64 sideleg;
    uint64 sie;
    uint64 stvec;
    uint64 scounteren;
    uint64 sscratch;
    uint64 sepc;
    uint64 scause;
    uint64 stval;
    uint64 sip;
    
    // Supervisor page table register
    uint64 satp;
    
    // Machine information registers
    uint64 mvendorid;
    uint64 marchid;
    uint64 mimpid;
    uint64 mhartid;
    
    // Machine trap setup registers
    uint64 mstatus;
    uint64 misa;
    uint64 medeleg;
    uint64 mideleg;
    uint64 mie;
    uint64 mtvec;
    uint64 mcounteren;
    uint64 mstatush;
    
    // Machine trap handling registers
    uint64 mscratch;
    uint64 mepc;
    uint64 mcause;
    uint64 mtval;
    uint64 mip;
    uint64 mtinst;
    uint64 mtval2;

    // PMP Registers
    uint64 pmpcfg0;
    uint64 pmpaddr0;
    uint64 pmpaddr1;
    uint64 pmpaddr2;
    uint64 pmpaddr3;
    uint64 pmpaddr4;
    uint64 pmpaddr5;
    uint64 pmpaddr6;
    uint64 pmpaddr7;
    uint64 pmpaddr8;
    uint64 pmpaddr9;
    uint64 pmpaddr10;
    uint64 pmpaddr11;
    uint64 pmpaddr12;
    uint64 pmpaddr13;
    uint64 pmpaddr14;
    uint64 pmpaddr15;
    
    struct vm_reg regs;
};
static struct vm_virtual_state vm_state;
static pagetable_t tpagetable;  

void trap_and_emulate_init(void) {

    /* Create and initialize all state for the VM */
    
    // User trap setup
    vm_state.ustatus = 0;
    vm_state.uie = 0;
    vm_state.utvec = 0;

    // User trap handling
    vm_state.uscratch = 0;
    vm_state.uepc = 0;
    vm_state.ucause = 0;
    vm_state.utval = 0;
    vm_state.uip = 0;

    // Supervisor trap setup
    vm_state.sstatus = 0;
    vm_state.sedeleg = 0;
    vm_state.sideleg = 0;
    vm_state.sie = 0;
    vm_state.stvec = 0;
    vm_state.scounteren = 0;
    vm_state.sscratch = 0;
    vm_state.sepc = 0;
    vm_state.scause = 0;
    vm_state.stval = 0;
    vm_state.sip = 0;

    // Supervisor page table register
    vm_state.satp = 0;

    // Machine information registers
    vm_state.mvendorid = 0x637365353336; // cse536
    vm_state.marchid = 0;
    vm_state.mimpid = 0;
    vm_state.mhartid = 0;

    // Machine trap setup registers
    vm_state.mstatus = 0;
    vm_state.misa = 0;
    vm_state.medeleg = 0;
    vm_state.mideleg = 0;
    vm_state.mie = 0;
    vm_state.mtvec = 0;
    vm_state.mcounteren = 0;
    vm_state.mstatush = 0;

    // Machine trap handling registers
    vm_state.mscratch = 0;
    vm_state.mepc = 0;
    vm_state.mcause = 0;
    vm_state.mtval = 0;
    vm_state.mip = 0;
    vm_state.mtinst = 0;
    vm_state.mtval2 = 0;

    // PMP Registers
    vm_state.pmpcfg0 = 0x0;
    vm_state.pmpaddr0 = 0x80400000;
    vm_state.pmpaddr1 = 0;
    vm_state.pmpaddr2 = 0;
    vm_state.pmpaddr3 = 0;
    vm_state.pmpaddr4 = 0;
    vm_state.pmpaddr5 = 0;
    vm_state.pmpaddr6 = 0;
    vm_state.pmpaddr7 = 0;
    vm_state.pmpaddr8 = 0;
    vm_state.pmpaddr9 = 0;
    vm_state.pmpaddr10 = 0;
    vm_state.pmpaddr11 = 0;
    vm_state.pmpaddr12 = 0;
    vm_state.pmpaddr13 = 0;
    vm_state.pmpaddr14 = 0;
    vm_state.pmpaddr15 = 0;
    
    // Setting the execution mode to MACHINE_MODE
    vm_state.regs.mode = MACHINE_MODE;
}

/*Csr Mappings*/
static uint64 *csr_vm_map[] = {

    // User trap setup
    [CSR_ustatus]       &vm_state.ustatus,
    [CSR_uie]           &vm_state.uie,
    [CSR_utvec]         &vm_state.utvec,

    // User trap handling
    [CSR_uscratch]      &vm_state.uscratch,
    [CSR_uepc]          &vm_state.uepc,
    [CSR_ucause]        &vm_state.ucause,
    [CSR_utval]         &vm_state.utval,
    [CSR_uip]           &vm_state.uip,

    // Supervisor trap setup
    [CSR_sstatus]       &vm_state.sstatus,
    [CSR_sedeleg]       &vm_state.sedeleg,
    [CSR_sideleg]       &vm_state.sideleg,
    [CSR_sie]           &vm_state.sie,
    [CSR_stvec]         &vm_state.stvec,
    [CSR_scounteren]    &vm_state.scounteren,
    [CSR_sscratch]      &vm_state.sscratch,
    [CSR_sepc]          &vm_state.sepc,
    [CSR_scause]        &vm_state.scause,
    [CSR_stval]         &vm_state.stval,
    [CSR_sip]           &vm_state.sip,
    
    // Supervisor page table register
    [CSR_satp]          &vm_state.satp,

    // Machine information registers
    [CSR_mvendorid]     &vm_state.mvendorid,
    [CSR_marchid]       &vm_state.marchid,
    [CSR_mimpid]        &vm_state.mimpid,
    [CSR_mhartid]       &vm_state.mhartid,

    // Machine trap setup registers
    [CSR_mstatus]       &vm_state.mstatus,
    [CSR_misa]          &vm_state.misa,
    [CSR_medeleg]       &vm_state.medeleg,
    [CSR_mideleg]       &vm_state.mideleg,
    [CSR_mie]           &vm_state.mie,
    [CSR_mtvec]         &vm_state.mtvec,
    [CSR_mcounteren]    &vm_state.mcounteren,
    [CSR_mstatush]      &vm_state.mstatush,
    
    // Machine trap handling registers
    [CSR_mscratch]      &vm_state.mscratch,
    [CSR_mepc]          &vm_state.mepc,
    [CSR_mcause]        &vm_state.mcause,
    [CSR_mtval]         &vm_state.mtval,
    [CSR_mip]           &vm_state.mip,
    [CSR_mtinst]        &vm_state.mtinst,
    [CSR_mtval2]        &vm_state.mtval2,
    
    // PMP Registers
    [CSR_pmpcfg0]       &vm_state.pmpcfg0,
    [CSR_pmpaddr0]      &vm_state.pmpaddr0,
    [CSR_pmpaddr1]      &vm_state.pmpaddr1,
    [CSR_pmpaddr2]      &vm_state.pmpaddr2,
    [CSR_pmpaddr3]      &vm_state.pmpaddr3,
    [CSR_pmpaddr4]      &vm_state.pmpaddr4,
    [CSR_pmpaddr5]      &vm_state.pmpaddr5,
    [CSR_pmpaddr6]      &vm_state.pmpaddr6,
    [CSR_pmpaddr7]      &vm_state.pmpaddr7,
    [CSR_pmpaddr8]      &vm_state.pmpaddr8,
    [CSR_pmpaddr9]      &vm_state.pmpaddr9,
    [CSR_pmpaddr10]     &vm_state.pmpaddr10,
    [CSR_pmpaddr11]     &vm_state.pmpaddr11,
    [CSR_pmpaddr12]     &vm_state.pmpaddr12,
    [CSR_pmpaddr13]     &vm_state.pmpaddr13,
    [CSR_pmpaddr14]     &vm_state.pmpaddr14,
    [CSR_pmpaddr15]     &vm_state.pmpaddr15,
};

/* Trap Frame Mappings*/
static uint64* reg_tf_map(struct trapframe *tf, uint32 register_val) {
    
    switch(register_val) {

        case REG_ra: return &tf->ra;
        case REG_sp: return &tf->sp;
        case REG_gp: return &tf->gp;
        case REG_tp: return &tf->tp;
        case REG_t0: return &tf->t0;
        case REG_t1: return &tf->t1;
        case REG_t2: return &tf->t2;
        case REG_s0: return &tf->s0;
        case REG_s1: return &tf->s1;

        case REG_a0: return &tf->a0;
        case REG_a1: return &tf->a1;
        case REG_a2: return &tf->a2;
        case REG_a3: return &tf->a3;
        case REG_a4: return &tf->a4;
        case REG_a5: return &tf->a5;
        
        default: return &tf->a5;

    }
}

// Allowing read operations on mvendroid
int mvendroid_check(uint32 uimm, uint32 funct3) {
    
    if (uimm == 0xf11 && funct3 == 2) {
        printf("Mvendroid is readable in all Modes\n");
        return 1;
    }

    if ((vm_state.regs.mode == USER_MODE && uimm > 0x45) || (vm_state.regs.mode == SUPERVISOR_MODE && uimm > 0x181))
        return 0;
    // if (vm_state.regs.mode == SUPERVISOR_MODE && uimm > 0x182) 
    //     return 0;
    return 1;
}

/* Redirecting to Guest */
void trap_and_emulate_ecall() {
    
    printf("(EC at %p)\n", myproc()->trapframe->epc);
    
    struct proc *proc = myproc();
    vm_state.sepc = proc->trapframe->epc;
    proc->trapframe->epc = vm_state.stvec;

    vm_state.regs.mode = SUPERVISOR_MODE;
    vm_state.sstatus |= SSTATUS_SPP;
    // printf("Successfylly redirecting to the guest");
}

/* Using existing uvmcopy function to copy the page tables*/
int my_uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
  pte_t *pte;
  uint64 pa, i;
  uint flags;

  for(i = 0; i < sz; i += PGSIZE){
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    flags = PTE_FLAGS(*pte);
    if(mappages(new, i, PGSIZE, pa, flags) != 0){
      goto err;
    }
  }
  // printf("Uvmcopy success\n");
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
  // printf("Uvmcopy fail\n");
  return -1;
}

void trap_and_emulate(void) {

    /* Comes here when a VM tries to execute a supervisor instruction. */
    struct proc *proc = myproc();
    struct trapframe *tf = proc->trapframe;
    uint32 ins;

    if (copyin(proc->pagetable, (char *)&ins, tf->epc, sizeof(ins))) {
        // printf("Error copying instruction into pagetable\n");
        goto killvm;
    }

    // printf("Current instruction : %proc, scause value %d\n", ins, r_scause());
    if (r_scause() == 12 || r_scause() == 13) {
        goto killvm;
    }
    if(r_scause() == 15){
    	printf("PMP Region scause Fault \n");
    	goto killvm;
    }

    /* Retrieve all required values from the instruction */
    uint64 addr     = tf->epc;
    uint32 op       = ins & 0x7F;
    uint32 rd       = (ins >> 7) & 0x1F;
    uint32 funct3   = (ins >> 12) & 0x7;
    uint32 rs1      = (ins >> 15) & 0x1F;
    uint32 uimm     = (ins >> 20);
    
    printf("(PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", addr, op, rd, funct3, rs1, uimm);

    if (!mvendroid_check(uimm, funct3)) {
        // printf("Kill because write on mvendroid \n"); 
        goto killvm;
    }
    
    // Handling csrr, csrw, mret & sret
    if (op == 0x73) {
        
        // csrw call
        if (funct3 == 1) {

            *csr_vm_map[uimm] = *reg_tf_map(tf, rs1);
            proc->trapframe->epc += 4;
            
            // printf("uimm %d CSR_mvendorid %x *csr_vm_map[uimm] %x \n",uimm,CSR_mvendorid, *csr_vm_map[uimm]);
            if(uimm == CSR_mvendorid && *reg_tf_map(tf, rs1) == 0x0){
            	// printf("Error Mvendroid write 0\n");
                goto killvm;
            }
        }

        // csrr call
        else if (funct3 == 2) { 
            *reg_tf_map(tf, rd) = *csr_vm_map[uimm];
            proc->trapframe->epc += 4;
        }
         
        else {

            // sret call
            if (uimm == 0x102) {
                if ((vm_state.sstatus & SSTATUS_SPP) != 0) {
                    // printf("Error SSTATUS_SPP\n");
                    goto killvm;
                }

                // Return to user
                vm_state.regs.mode = USER_MODE;
                proc->trapframe->epc = vm_state.sepc;
            }

            // mret call
            else if (uimm == 0x302) {
                if ((vm_state.mstatus & MSTATUS_MPP_MASK) == MSTATUS_MPP_M) {
                    // printf("Error MSTATUS_MPP_M\n");
                    goto killvm;
                }
                
                // Changing vm state based on previous modes
                if(vm_state.mstatus == MSTATUS_MPP_S){
                    vm_state.regs.mode = SUPERVISOR_MODE;
                }
                else if(vm_state.mstatus == MSTATUS_MPP_U){
                    vm_state.regs.mode = USER_MODE;
                }
                
                // Setting the epc of the trapframe
                proc->trapframe->epc = vm_state.mepc;
                
                /*PMP Handling*/
                static pagetable_t pagetable_pmp;

                int pmp_region = (0x80400000 - (vm_state.pmpaddr0<<2));
                pmp_region = pmp_region / PGSIZE;

                if (vm_state.pmpcfg0 != 0 && pmp_region > 0) { 

                    pagetable_pmp = proc_pagetable(proc);
                    uint64 addr = 0x80000000;
                    int sz1 = 0;
                    pmp_flag = 1; // Flag to know it PMP is ever executed

                    if((sz1 = uvmalloc(pagetable_pmp, addr, addr + 1024*PGSIZE, PTE_W)) == 0) {
                        printf("Failed to allocate memory for PMP\n");
                    }
                    if(my_uvmcopy(proc->pagetable, pagetable_pmp, proc->sz) < 0) {
                        printf("Error in copying the page tables\n");
                    }
                    else{
                        // Unmapping and updating the page tables
                        uvmunmap(pagetable_pmp, vm_state.pmpaddr0<<2, pmp_region, 0);
                        tpagetable = proc->pagetable;
                        proc->pagetable = pagetable_pmp;  
                        printf("Pages unmapped are %d\n", pmp_region);
                    }
                }
            }
        }
    }

    // printf("End\n");
    return;
    
killvm:
   // printf("Killing the VM\n");
   if(pmp_flag){
      proc->pagetable = tpagetable;
   }
   setkilled(proc); // Killing the VM ie process
}
    
