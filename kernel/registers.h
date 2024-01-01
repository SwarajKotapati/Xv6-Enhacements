#define REG_ra          0x1
#define REG_sp          0x2
#define REG_gp          0x3
#define REG_tp          0x4
#define REG_t0          0x5
#define REG_t1          0x6
#define REG_t2          0x7
#define REG_s0          0x8
#define REG_s1          0x9
#define REG_a0          0xa
#define REG_a1          0xb
#define REG_a2          0xc
#define REG_a3          0xd
#define REG_a4          0xe
#define REG_a5          0xf
#define REG_a6          0x10
#define REG_a7          0x11
#define REG_s2          0x12
#define REG_s3          0x13
#define REG_s4          0x14
#define REG_s5          0x15
#define REG_s6          0x16
#define REG_s7          0x17
#define REG_s8          0x18
#define REG_s9          0x19
#define REG_s10         0x1a
#define REG_s11         0x1b
#define REG_t3          0x1c
#define REG_t4          0x1d
#define REG_t5          0x1e
#define REG_t6          0x1f

#define CSR_ustatus     0x0
#define CSR_uie         0x4
#define CSR_utvec       0x5
#define CSR_uscratch    0x40
#define CSR_uepc        0x41
#define CSR_ucause      0x42
#define CSR_utval       0x43
#define CSR_uip         0x44

#define CSR_sstatus     0x100
#define CSR_sedeleg     0x102
#define CSR_sideleg     0x103
#define CSR_sie         0x104
#define CSR_stvec       0x105
#define CSR_scounteren  0x106
#define CSR_sscratch    0x140
#define CSR_sepc        0x141
#define CSR_scause      0x142
#define CSR_stval       0x143
#define CSR_sip         0x144
#define CSR_satp        0x180

#define CSR_mvendorid   0xf11
#define CSR_marchid     0xf12
#define CSR_mimpid      0xf13
#define CSR_mhartid     0xf14
#define CSR_mstatus     0x300
#define CSR_misa        0x301
#define CSR_medeleg     0x302
#define CSR_mideleg     0x303
#define CSR_mie         0x304
#define CSR_mtvec       0x305
#define CSR_mcounteren  0x306
#define CSR_mstatush    0x310
#define CSR_mscratch    0x340
#define CSR_mepc        0x341
#define CSR_mcause      0x342
#define CSR_mtval       0x343
#define CSR_mip         0x344
#define CSR_mtinst      0x34a
#define CSR_mtval2      0x34b

#define CSR_pmpcfg0     0x3a0
#define CSR_pmpaddr0    0x3b0
#define CSR_pmpaddr1    0x3b1
#define CSR_pmpaddr2    0x3b2
#define CSR_pmpaddr3    0x3b3
#define CSR_pmpaddr4    0x3b4
#define CSR_pmpaddr5    0x3b5
#define CSR_pmpaddr6    0x3b6
#define CSR_pmpaddr7    0x3b7
#define CSR_pmpaddr8    0x3b8
#define CSR_pmpaddr9    0x3b9
#define CSR_pmpaddr10   0x3ba
#define CSR_pmpaddr11   0x3bb
#define CSR_pmpaddr12   0x3bc
#define CSR_pmpaddr13   0x3bd
#define CSR_pmpaddr14   0x3be
#define CSR_pmpaddr15   0x3bf
