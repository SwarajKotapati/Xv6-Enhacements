
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00010117          	auipc	sp,0x10
    80000004:	4d010113          	addi	sp,sp,1232 # 800104d0 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	07a000ef          	jal	ra,80000090 <start>

000000008000001a <_entry_kernel>:
    8000001a:	6cf000ef          	jal	ra,80000ee8 <main>

000000008000001e <_entry_test>:
    8000001e:	a001                	j	8000001e <_entry_test>

0000000080000020 <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    80000020:	1141                	addi	sp,sp,-16
    80000022:	e422                	sd	s0,8(sp)
    80000024:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000026:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    8000002a:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002e:	0037979b          	slliw	a5,a5,0x3
    80000032:	02004737          	lui	a4,0x2004
    80000036:	97ba                	add	a5,a5,a4
    80000038:	0200c737          	lui	a4,0x200c
    8000003c:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000040:	000f4637          	lui	a2,0xf4
    80000044:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000048:	9732                	add	a4,a4,a2
    8000004a:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    8000004c:	00259693          	slli	a3,a1,0x2
    80000050:	96ae                	add	a3,a3,a1
    80000052:	068e                	slli	a3,a3,0x3
    80000054:	00010717          	auipc	a4,0x10
    80000058:	33c70713          	addi	a4,a4,828 # 80010390 <timer_scratch>
    8000005c:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005e:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    80000060:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000062:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000066:	00006797          	auipc	a5,0x6
    8000006a:	c3a78793          	addi	a5,a5,-966 # 80005ca0 <timervec>
    8000006e:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000072:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000076:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000007a:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007e:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000082:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000086:	30479073          	csrw	mie,a5
}
    8000008a:	6422                	ld	s0,8(sp)
    8000008c:	0141                	addi	sp,sp,16
    8000008e:	8082                	ret

0000000080000090 <start>:
{
    80000090:	1141                	addi	sp,sp,-16
    80000092:	e406                	sd	ra,8(sp)
    80000094:	e022                	sd	s0,0(sp)
    80000096:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000098:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    8000009c:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    8000009e:	823e                	mv	tp,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    800000a0:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    800000a4:	7779                	lui	a4,0xffffe
    800000a6:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd4c2f>
    800000aa:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000ac:	6705                	lui	a4,0x1
    800000ae:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000b2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000b4:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000b8:	00001797          	auipc	a5,0x1
    800000bc:	e3078793          	addi	a5,a5,-464 # 80000ee8 <main>
    800000c0:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000c4:	4781                	li	a5,0
    800000c6:	18079073          	csrw	satp,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000ca:	57fd                	li	a5,-1
    800000cc:	83a9                	srli	a5,a5,0xa
    800000ce:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000d2:	47bd                	li	a5,15
    800000d4:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f48080e7          	jalr	-184(ra) # 80000020 <timerinit>
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000e0:	67c1                	lui	a5,0x10
    800000e2:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000e4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000e8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ec:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000f0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000f4:	10479073          	csrw	sie,a5
  asm volatile("mret");
    800000f8:	30200073          	mret
}
    800000fc:	60a2                	ld	ra,8(sp)
    800000fe:	6402                	ld	s0,0(sp)
    80000100:	0141                	addi	sp,sp,16
    80000102:	8082                	ret

0000000080000104 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000104:	715d                	addi	sp,sp,-80
    80000106:	e486                	sd	ra,72(sp)
    80000108:	e0a2                	sd	s0,64(sp)
    8000010a:	fc26                	sd	s1,56(sp)
    8000010c:	f84a                	sd	s2,48(sp)
    8000010e:	f44e                	sd	s3,40(sp)
    80000110:	f052                	sd	s4,32(sp)
    80000112:	ec56                	sd	s5,24(sp)
    80000114:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000116:	04c05763          	blez	a2,80000164 <consolewrite+0x60>
    8000011a:	8a2a                	mv	s4,a0
    8000011c:	84ae                	mv	s1,a1
    8000011e:	89b2                	mv	s3,a2
    80000120:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000122:	5afd                	li	s5,-1
    80000124:	4685                	li	a3,1
    80000126:	8626                	mv	a2,s1
    80000128:	85d2                	mv	a1,s4
    8000012a:	fbf40513          	addi	a0,s0,-65
    8000012e:	00002097          	auipc	ra,0x2
    80000132:	436080e7          	jalr	1078(ra) # 80002564 <either_copyin>
    80000136:	01550d63          	beq	a0,s5,80000150 <consolewrite+0x4c>
      break;
    uartputc(c);
    8000013a:	fbf44503          	lbu	a0,-65(s0)
    8000013e:	00000097          	auipc	ra,0x0
    80000142:	7f2080e7          	jalr	2034(ra) # 80000930 <uartputc>
  for(i = 0; i < n; i++){
    80000146:	2905                	addiw	s2,s2,1
    80000148:	0485                	addi	s1,s1,1
    8000014a:	fd299de3          	bne	s3,s2,80000124 <consolewrite+0x20>
    8000014e:	894e                	mv	s2,s3
  }

  return i;
}
    80000150:	854a                	mv	a0,s2
    80000152:	60a6                	ld	ra,72(sp)
    80000154:	6406                	ld	s0,64(sp)
    80000156:	74e2                	ld	s1,56(sp)
    80000158:	7942                	ld	s2,48(sp)
    8000015a:	79a2                	ld	s3,40(sp)
    8000015c:	7a02                	ld	s4,32(sp)
    8000015e:	6ae2                	ld	s5,24(sp)
    80000160:	6161                	addi	sp,sp,80
    80000162:	8082                	ret
  for(i = 0; i < n; i++){
    80000164:	4901                	li	s2,0
    80000166:	b7ed                	j	80000150 <consolewrite+0x4c>

0000000080000168 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000168:	711d                	addi	sp,sp,-96
    8000016a:	ec86                	sd	ra,88(sp)
    8000016c:	e8a2                	sd	s0,80(sp)
    8000016e:	e4a6                	sd	s1,72(sp)
    80000170:	e0ca                	sd	s2,64(sp)
    80000172:	fc4e                	sd	s3,56(sp)
    80000174:	f852                	sd	s4,48(sp)
    80000176:	f456                	sd	s5,40(sp)
    80000178:	f05a                	sd	s6,32(sp)
    8000017a:	ec5e                	sd	s7,24(sp)
    8000017c:	1080                	addi	s0,sp,96
    8000017e:	8aaa                	mv	s5,a0
    80000180:	8a2e                	mv	s4,a1
    80000182:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000184:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000188:	00018517          	auipc	a0,0x18
    8000018c:	34850513          	addi	a0,a0,840 # 800184d0 <cons>
    80000190:	00001097          	auipc	ra,0x1
    80000194:	ab8080e7          	jalr	-1352(ra) # 80000c48 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000198:	00018497          	auipc	s1,0x18
    8000019c:	33848493          	addi	s1,s1,824 # 800184d0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a0:	00018917          	auipc	s2,0x18
    800001a4:	3c890913          	addi	s2,s2,968 # 80018568 <cons+0x98>
  while(n > 0){
    800001a8:	09305263          	blez	s3,8000022c <consoleread+0xc4>
    while(cons.r == cons.w){
    800001ac:	0984a783          	lw	a5,152(s1)
    800001b0:	09c4a703          	lw	a4,156(s1)
    800001b4:	02f71763          	bne	a4,a5,800001e2 <consoleread+0x7a>
      if(killed(myproc())){
    800001b8:	00002097          	auipc	ra,0x2
    800001bc:	86c080e7          	jalr	-1940(ra) # 80001a24 <myproc>
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	1ee080e7          	jalr	494(ra) # 800023ae <killed>
    800001c8:	ed2d                	bnez	a0,80000242 <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001ca:	85a6                	mv	a1,s1
    800001cc:	854a                	mv	a0,s2
    800001ce:	00002097          	auipc	ra,0x2
    800001d2:	f38080e7          	jalr	-200(ra) # 80002106 <sleep>
    while(cons.r == cons.w){
    800001d6:	0984a783          	lw	a5,152(s1)
    800001da:	09c4a703          	lw	a4,156(s1)
    800001de:	fcf70de3          	beq	a4,a5,800001b8 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001e2:	00018717          	auipc	a4,0x18
    800001e6:	2ee70713          	addi	a4,a4,750 # 800184d0 <cons>
    800001ea:	0017869b          	addiw	a3,a5,1
    800001ee:	08d72c23          	sw	a3,152(a4)
    800001f2:	07f7f693          	andi	a3,a5,127
    800001f6:	9736                	add	a4,a4,a3
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    80000200:	4691                	li	a3,4
    80000202:	06db8463          	beq	s7,a3,8000026a <consoleread+0x102>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    80000206:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020a:	4685                	li	a3,1
    8000020c:	faf40613          	addi	a2,s0,-81
    80000210:	85d2                	mv	a1,s4
    80000212:	8556                	mv	a0,s5
    80000214:	00002097          	auipc	ra,0x2
    80000218:	2fa080e7          	jalr	762(ra) # 8000250e <either_copyout>
    8000021c:	57fd                	li	a5,-1
    8000021e:	00f50763          	beq	a0,a5,8000022c <consoleread+0xc4>
      break;

    dst++;
    80000222:	0a05                	addi	s4,s4,1
    --n;
    80000224:	39fd                	addiw	s3,s3,-1

    if(c == '\n'){
    80000226:	47a9                	li	a5,10
    80000228:	f8fb90e3          	bne	s7,a5,800001a8 <consoleread+0x40>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022c:	00018517          	auipc	a0,0x18
    80000230:	2a450513          	addi	a0,a0,676 # 800184d0 <cons>
    80000234:	00001097          	auipc	ra,0x1
    80000238:	ac8080e7          	jalr	-1336(ra) # 80000cfc <release>

  return target - n;
    8000023c:	413b053b          	subw	a0,s6,s3
    80000240:	a811                	j	80000254 <consoleread+0xec>
        release(&cons.lock);
    80000242:	00018517          	auipc	a0,0x18
    80000246:	28e50513          	addi	a0,a0,654 # 800184d0 <cons>
    8000024a:	00001097          	auipc	ra,0x1
    8000024e:	ab2080e7          	jalr	-1358(ra) # 80000cfc <release>
        return -1;
    80000252:	557d                	li	a0,-1
}
    80000254:	60e6                	ld	ra,88(sp)
    80000256:	6446                	ld	s0,80(sp)
    80000258:	64a6                	ld	s1,72(sp)
    8000025a:	6906                	ld	s2,64(sp)
    8000025c:	79e2                	ld	s3,56(sp)
    8000025e:	7a42                	ld	s4,48(sp)
    80000260:	7aa2                	ld	s5,40(sp)
    80000262:	7b02                	ld	s6,32(sp)
    80000264:	6be2                	ld	s7,24(sp)
    80000266:	6125                	addi	sp,sp,96
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677fe3          	bgeu	a4,s6,8000022c <consoleread+0xc4>
        cons.r--;
    80000272:	00018717          	auipc	a4,0x18
    80000276:	2ef72b23          	sw	a5,758(a4) # 80018568 <cons+0x98>
    8000027a:	bf4d                	j	8000022c <consoleread+0xc4>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	5de080e7          	jalr	1502(ra) # 8000086a <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	5cc080e7          	jalr	1484(ra) # 8000086a <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	5c0080e7          	jalr	1472(ra) # 8000086a <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	5b6080e7          	jalr	1462(ra) # 8000086a <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00018517          	auipc	a0,0x18
    800002d0:	20450513          	addi	a0,a0,516 # 800184d0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	974080e7          	jalr	-1676(ra) # 80000c48 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	2c8080e7          	jalr	712(ra) # 800025ba <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00018517          	auipc	a0,0x18
    800002fe:	1d650513          	addi	a0,a0,470 # 800184d0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	9fa080e7          	jalr	-1542(ra) # 80000cfc <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00018717          	auipc	a4,0x18
    80000322:	1b270713          	addi	a4,a4,434 # 800184d0 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00018797          	auipc	a5,0x18
    8000034c:	18878793          	addi	a5,a5,392 # 800184d0 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00018797          	auipc	a5,0x18
    8000037a:	1f27a783          	lw	a5,498(a5) # 80018568 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00018717          	auipc	a4,0x18
    8000038e:	14670713          	addi	a4,a4,326 # 800184d0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00018497          	auipc	s1,0x18
    8000039e:	13648493          	addi	s1,s1,310 # 800184d0 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00018717          	auipc	a4,0x18
    800003da:	0fa70713          	addi	a4,a4,250 # 800184d0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00018717          	auipc	a4,0x18
    800003f0:	18f72223          	sw	a5,388(a4) # 80018570 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00018797          	auipc	a5,0x18
    80000416:	0be78793          	addi	a5,a5,190 # 800184d0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00018797          	auipc	a5,0x18
    8000043a:	12c7ab23          	sw	a2,310(a5) # 8001856c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00018517          	auipc	a0,0x18
    80000442:	12a50513          	addi	a0,a0,298 # 80018568 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	d24080e7          	jalr	-732(ra) # 8000216a <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00018517          	auipc	a0,0x18
    80000464:	07050513          	addi	a0,a0,112 # 800184d0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	750080e7          	jalr	1872(ra) # 80000bb8 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	3aa080e7          	jalr	938(ra) # 8000081a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00028797          	auipc	a5,0x28
    8000047c:	3f078793          	addi	a5,a5,1008 # 80028868 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce870713          	addi	a4,a4,-792 # 80000168 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7a70713          	addi	a4,a4,-902 # 80000104 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
  //   release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00018797          	auipc	a5,0x18
    80000550:	0407a223          	sw	zero,68(a5) # 80018590 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00010517          	auipc	a0,0x10
    80000572:	cca50513          	addi	a0,a0,-822 # 80010238 <csr_vm_map+0x78f8>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00010717          	auipc	a4,0x10
    80000584:	dcf72023          	sw	a5,-576(a4) # 80010340 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  if (fmt == 0)
    800005ba:	c90d                	beqz	a0,800005ec <printf+0x62>
    800005bc:	8a2a                	mv	s4,a0
  va_start(ap, fmt);
    800005be:	00840793          	addi	a5,s0,8
    800005c2:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005c6:	00054503          	lbu	a0,0(a0)
    800005ca:	20050063          	beqz	a0,800007ca <printf+0x240>
    800005ce:	4481                	li	s1,0
    if(c != '%'){
    800005d0:	02500b13          	li	s6,37
    switch(c){
    800005d4:	07000b93          	li	s7,112
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d8:	00008a97          	auipc	s5,0x8
    800005dc:	a68a8a93          	addi	s5,s5,-1432 # 80008040 <digits>
    switch(c){
    800005e0:	07300c93          	li	s9,115
    800005e4:	03400c13          	li	s8,52
  } while((x /= base) != 0);
    800005e8:	4d3d                	li	s10,15
    800005ea:	a025                	j	80000612 <printf+0x88>
    panic("null fmt");
    800005ec:	00008517          	auipc	a0,0x8
    800005f0:	a3c50513          	addi	a0,a0,-1476 # 80008028 <etext+0x28>
    800005f4:	00000097          	auipc	ra,0x0
    800005f8:	f4c080e7          	jalr	-180(ra) # 80000540 <panic>
      consputc(c);
    800005fc:	00000097          	auipc	ra,0x0
    80000600:	c80080e7          	jalr	-896(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000604:	2485                	addiw	s1,s1,1
    80000606:	009a07b3          	add	a5,s4,s1
    8000060a:	0007c503          	lbu	a0,0(a5)
    8000060e:	1a050e63          	beqz	a0,800007ca <printf+0x240>
    if(c != '%'){
    80000612:	ff6515e3          	bne	a0,s6,800005fc <printf+0x72>
    c = fmt[++i] & 0xff;
    80000616:	2485                	addiw	s1,s1,1
    80000618:	009a07b3          	add	a5,s4,s1
    8000061c:	0007c783          	lbu	a5,0(a5)
    80000620:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000624:	1a078363          	beqz	a5,800007ca <printf+0x240>
    switch(c){
    80000628:	11778563          	beq	a5,s7,80000732 <printf+0x1a8>
    8000062c:	02fbee63          	bltu	s7,a5,80000668 <printf+0xde>
    80000630:	07878063          	beq	a5,s8,80000690 <printf+0x106>
    80000634:	06400713          	li	a4,100
    80000638:	02e79063          	bne	a5,a4,80000658 <printf+0xce>
      printint(va_arg(ap, int), 10, 1);
    8000063c:	f8843783          	ld	a5,-120(s0)
    80000640:	00878713          	addi	a4,a5,8
    80000644:	f8e43423          	sd	a4,-120(s0)
    80000648:	4605                	li	a2,1
    8000064a:	45a9                	li	a1,10
    8000064c:	4388                	lw	a0,0(a5)
    8000064e:	00000097          	auipc	ra,0x0
    80000652:	e4e080e7          	jalr	-434(ra) # 8000049c <printint>
      break;
    80000656:	b77d                	j	80000604 <printf+0x7a>
    switch(c){
    80000658:	15679e63          	bne	a5,s6,800007b4 <printf+0x22a>
      consputc('%');
    8000065c:	855a                	mv	a0,s6
    8000065e:	00000097          	auipc	ra,0x0
    80000662:	c1e080e7          	jalr	-994(ra) # 8000027c <consputc>
      break;
    80000666:	bf79                	j	80000604 <printf+0x7a>
    switch(c){
    80000668:	11978863          	beq	a5,s9,80000778 <printf+0x1ee>
    8000066c:	07800713          	li	a4,120
    80000670:	14e79263          	bne	a5,a4,800007b4 <printf+0x22a>
      printint(va_arg(ap, int), 16, 1);
    80000674:	f8843783          	ld	a5,-120(s0)
    80000678:	00878713          	addi	a4,a5,8
    8000067c:	f8e43423          	sd	a4,-120(s0)
    80000680:	4605                	li	a2,1
    80000682:	45c1                	li	a1,16
    80000684:	4388                	lw	a0,0(a5)
    80000686:	00000097          	auipc	ra,0x0
    8000068a:	e16080e7          	jalr	-490(ra) # 8000049c <printint>
      break;
    8000068e:	bf9d                	j	80000604 <printf+0x7a>
      print4hex(va_arg(ap, int), 16, 1);
    80000690:	f8843783          	ld	a5,-120(s0)
    80000694:	00878713          	addi	a4,a5,8
    80000698:	f8e43423          	sd	a4,-120(s0)
    8000069c:	438c                	lw	a1,0(a5)
    x = xx;
    8000069e:	0005879b          	sext.w	a5,a1
  if(sign && (sign = xx < 0))
    800006a2:	0805c563          	bltz	a1,8000072c <printf+0x1a2>
    800006a6:	f8040693          	addi	a3,s0,-128
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800006aa:	4901                	li	s2,0
    buf[i++] = digits[x % base];
    800006ac:	864a                	mv	a2,s2
    800006ae:	2905                	addiw	s2,s2,1
    800006b0:	00f7f713          	andi	a4,a5,15
    800006b4:	9756                	add	a4,a4,s5
    800006b6:	00074703          	lbu	a4,0(a4)
    800006ba:	00e68023          	sb	a4,0(a3)
  } while((x /= base) != 0);
    800006be:	0007871b          	sext.w	a4,a5
    800006c2:	0047d79b          	srliw	a5,a5,0x4
    800006c6:	0685                	addi	a3,a3,1
    800006c8:	feed62e3          	bltu	s10,a4,800006ac <printf+0x122>
  if(sign)
    800006cc:	0005dc63          	bgez	a1,800006e4 <printf+0x15a>
    buf[i++] = '-';
    800006d0:	f9090793          	addi	a5,s2,-112
    800006d4:	00878933          	add	s2,a5,s0
    800006d8:	02d00793          	li	a5,45
    800006dc:	fef90823          	sb	a5,-16(s2)
    800006e0:	0026091b          	addiw	s2,a2,2
  for (int p=4-i; p>=0; p--)
    800006e4:	4991                	li	s3,4
    800006e6:	412989bb          	subw	s3,s3,s2
    800006ea:	0009cc63          	bltz	s3,80000702 <printf+0x178>
    800006ee:	5dfd                	li	s11,-1
    consputc('0');
    800006f0:	03000513          	li	a0,48
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
  for (int p=4-i; p>=0; p--)
    800006fc:	39fd                	addiw	s3,s3,-1
    800006fe:	ffb999e3          	bne	s3,s11,800006f0 <printf+0x166>
  while(--i >= 0)
    80000702:	fff9099b          	addiw	s3,s2,-1
    80000706:	f609c7e3          	bltz	s3,80000674 <printf+0xea>
    8000070a:	f9090793          	addi	a5,s2,-112
    8000070e:	00878933          	add	s2,a5,s0
    80000712:	193d                	addi	s2,s2,-17
    80000714:	5dfd                	li	s11,-1
    consputc(buf[i]);
    80000716:	00094503          	lbu	a0,0(s2)
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000722:	39fd                	addiw	s3,s3,-1
    80000724:	197d                	addi	s2,s2,-1
    80000726:	ffb998e3          	bne	s3,s11,80000716 <printf+0x18c>
    8000072a:	b7a9                	j	80000674 <printf+0xea>
    x = -xx;
    8000072c:	40b007bb          	negw	a5,a1
    80000730:	bf9d                	j	800006a6 <printf+0x11c>
      printptr(va_arg(ap, uint64));
    80000732:	f8843783          	ld	a5,-120(s0)
    80000736:	00878713          	addi	a4,a5,8
    8000073a:	f8e43423          	sd	a4,-120(s0)
    8000073e:	0007b983          	ld	s3,0(a5)
  consputc('0');
    80000742:	03000513          	li	a0,48
    80000746:	00000097          	auipc	ra,0x0
    8000074a:	b36080e7          	jalr	-1226(ra) # 8000027c <consputc>
  consputc('x');
    8000074e:	07800513          	li	a0,120
    80000752:	00000097          	auipc	ra,0x0
    80000756:	b2a080e7          	jalr	-1238(ra) # 8000027c <consputc>
    8000075a:	4941                	li	s2,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    8000075c:	03c9d793          	srli	a5,s3,0x3c
    80000760:	97d6                	add	a5,a5,s5
    80000762:	0007c503          	lbu	a0,0(a5)
    80000766:	00000097          	auipc	ra,0x0
    8000076a:	b16080e7          	jalr	-1258(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000076e:	0992                	slli	s3,s3,0x4
    80000770:	397d                	addiw	s2,s2,-1
    80000772:	fe0915e3          	bnez	s2,8000075c <printf+0x1d2>
    80000776:	b579                	j	80000604 <printf+0x7a>
      if((s = va_arg(ap, char*)) == 0)
    80000778:	f8843783          	ld	a5,-120(s0)
    8000077c:	00878713          	addi	a4,a5,8
    80000780:	f8e43423          	sd	a4,-120(s0)
    80000784:	0007b903          	ld	s2,0(a5)
    80000788:	00090f63          	beqz	s2,800007a6 <printf+0x21c>
      for(; *s; s++)
    8000078c:	00094503          	lbu	a0,0(s2)
    80000790:	e6050ae3          	beqz	a0,80000604 <printf+0x7a>
        consputc(*s);
    80000794:	00000097          	auipc	ra,0x0
    80000798:	ae8080e7          	jalr	-1304(ra) # 8000027c <consputc>
      for(; *s; s++)
    8000079c:	0905                	addi	s2,s2,1
    8000079e:	00094503          	lbu	a0,0(s2)
    800007a2:	f96d                	bnez	a0,80000794 <printf+0x20a>
    800007a4:	b585                	j	80000604 <printf+0x7a>
        s = "(null)";
    800007a6:	00008917          	auipc	s2,0x8
    800007aa:	87a90913          	addi	s2,s2,-1926 # 80008020 <etext+0x20>
      for(; *s; s++)
    800007ae:	02800513          	li	a0,40
    800007b2:	b7cd                	j	80000794 <printf+0x20a>
      consputc('%');
    800007b4:	855a                	mv	a0,s6
    800007b6:	00000097          	auipc	ra,0x0
    800007ba:	ac6080e7          	jalr	-1338(ra) # 8000027c <consputc>
      consputc(c);
    800007be:	854a                	mv	a0,s2
    800007c0:	00000097          	auipc	ra,0x0
    800007c4:	abc080e7          	jalr	-1348(ra) # 8000027c <consputc>
      break;
    800007c8:	bd35                	j	80000604 <printf+0x7a>
}
    800007ca:	70e6                	ld	ra,120(sp)
    800007cc:	7446                	ld	s0,112(sp)
    800007ce:	74a6                	ld	s1,104(sp)
    800007d0:	7906                	ld	s2,96(sp)
    800007d2:	69e6                	ld	s3,88(sp)
    800007d4:	6a46                	ld	s4,80(sp)
    800007d6:	6aa6                	ld	s5,72(sp)
    800007d8:	6b06                	ld	s6,64(sp)
    800007da:	7be2                	ld	s7,56(sp)
    800007dc:	7c42                	ld	s8,48(sp)
    800007de:	7ca2                	ld	s9,40(sp)
    800007e0:	7d02                	ld	s10,32(sp)
    800007e2:	6de2                	ld	s11,24(sp)
    800007e4:	6129                	addi	sp,sp,192
    800007e6:	8082                	ret

00000000800007e8 <printfinit>:
    ;
}

void
printfinit(void)
{
    800007e8:	1101                	addi	sp,sp,-32
    800007ea:	ec06                	sd	ra,24(sp)
    800007ec:	e822                	sd	s0,16(sp)
    800007ee:	e426                	sd	s1,8(sp)
    800007f0:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    800007f2:	00018497          	auipc	s1,0x18
    800007f6:	d8648493          	addi	s1,s1,-634 # 80018578 <pr>
    800007fa:	00008597          	auipc	a1,0x8
    800007fe:	83e58593          	addi	a1,a1,-1986 # 80008038 <etext+0x38>
    80000802:	8526                	mv	a0,s1
    80000804:	00000097          	auipc	ra,0x0
    80000808:	3b4080e7          	jalr	948(ra) # 80000bb8 <initlock>
  pr.locking = 1;
    8000080c:	4785                	li	a5,1
    8000080e:	cc9c                	sw	a5,24(s1)
}
    80000810:	60e2                	ld	ra,24(sp)
    80000812:	6442                	ld	s0,16(sp)
    80000814:	64a2                	ld	s1,8(sp)
    80000816:	6105                	addi	sp,sp,32
    80000818:	8082                	ret

000000008000081a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000081a:	1141                	addi	sp,sp,-16
    8000081c:	e406                	sd	ra,8(sp)
    8000081e:	e022                	sd	s0,0(sp)
    80000820:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000822:	100007b7          	lui	a5,0x10000
    80000826:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    8000082a:	f8000713          	li	a4,-128
    8000082e:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000832:	470d                	li	a4,3
    80000834:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000838:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000083c:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000840:	469d                	li	a3,7
    80000842:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000846:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    8000084a:	00008597          	auipc	a1,0x8
    8000084e:	80e58593          	addi	a1,a1,-2034 # 80008058 <digits+0x18>
    80000852:	00018517          	auipc	a0,0x18
    80000856:	d4650513          	addi	a0,a0,-698 # 80018598 <uart_tx_lock>
    8000085a:	00000097          	auipc	ra,0x0
    8000085e:	35e080e7          	jalr	862(ra) # 80000bb8 <initlock>
}
    80000862:	60a2                	ld	ra,8(sp)
    80000864:	6402                	ld	s0,0(sp)
    80000866:	0141                	addi	sp,sp,16
    80000868:	8082                	ret

000000008000086a <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    8000086a:	1101                	addi	sp,sp,-32
    8000086c:	ec06                	sd	ra,24(sp)
    8000086e:	e822                	sd	s0,16(sp)
    80000870:	e426                	sd	s1,8(sp)
    80000872:	1000                	addi	s0,sp,32
    80000874:	84aa                	mv	s1,a0
  push_off();
    80000876:	00000097          	auipc	ra,0x0
    8000087a:	386080e7          	jalr	902(ra) # 80000bfc <push_off>
  //   for(;;)
  //     ;
  // }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000087e:	10000737          	lui	a4,0x10000
    80000882:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000886:	0207f793          	andi	a5,a5,32
    8000088a:	dfe5                	beqz	a5,80000882 <uartputc_sync+0x18>
    ;
  WriteReg(THR, c);
    8000088c:	0ff4f493          	zext.b	s1,s1
    80000890:	100007b7          	lui	a5,0x10000
    80000894:	00978023          	sb	s1,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000898:	00000097          	auipc	ra,0x0
    8000089c:	404080e7          	jalr	1028(ra) # 80000c9c <pop_off>
}
    800008a0:	60e2                	ld	ra,24(sp)
    800008a2:	6442                	ld	s0,16(sp)
    800008a4:	64a2                	ld	s1,8(sp)
    800008a6:	6105                	addi	sp,sp,32
    800008a8:	8082                	ret

00000000800008aa <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    800008aa:	00010797          	auipc	a5,0x10
    800008ae:	a9e7b783          	ld	a5,-1378(a5) # 80010348 <uart_tx_r>
    800008b2:	00010717          	auipc	a4,0x10
    800008b6:	a9e73703          	ld	a4,-1378(a4) # 80010350 <uart_tx_w>
    800008ba:	06f70a63          	beq	a4,a5,8000092e <uartstart+0x84>
{
    800008be:	7139                	addi	sp,sp,-64
    800008c0:	fc06                	sd	ra,56(sp)
    800008c2:	f822                	sd	s0,48(sp)
    800008c4:	f426                	sd	s1,40(sp)
    800008c6:	f04a                	sd	s2,32(sp)
    800008c8:	ec4e                	sd	s3,24(sp)
    800008ca:	e852                	sd	s4,16(sp)
    800008cc:	e456                	sd	s5,8(sp)
    800008ce:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008d0:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008d4:	00018a17          	auipc	s4,0x18
    800008d8:	cc4a0a13          	addi	s4,s4,-828 # 80018598 <uart_tx_lock>
    uart_tx_r += 1;
    800008dc:	00010497          	auipc	s1,0x10
    800008e0:	a6c48493          	addi	s1,s1,-1428 # 80010348 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    800008e4:	00010997          	auipc	s3,0x10
    800008e8:	a6c98993          	addi	s3,s3,-1428 # 80010350 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008ec:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    800008f0:	02077713          	andi	a4,a4,32
    800008f4:	c705                	beqz	a4,8000091c <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008f6:	01f7f713          	andi	a4,a5,31
    800008fa:	9752                	add	a4,a4,s4
    800008fc:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000900:	0785                	addi	a5,a5,1
    80000902:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000904:	8526                	mv	a0,s1
    80000906:	00002097          	auipc	ra,0x2
    8000090a:	864080e7          	jalr	-1948(ra) # 8000216a <wakeup>
    
    WriteReg(THR, c);
    8000090e:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    80000912:	609c                	ld	a5,0(s1)
    80000914:	0009b703          	ld	a4,0(s3)
    80000918:	fcf71ae3          	bne	a4,a5,800008ec <uartstart+0x42>
  }
}
    8000091c:	70e2                	ld	ra,56(sp)
    8000091e:	7442                	ld	s0,48(sp)
    80000920:	74a2                	ld	s1,40(sp)
    80000922:	7902                	ld	s2,32(sp)
    80000924:	69e2                	ld	s3,24(sp)
    80000926:	6a42                	ld	s4,16(sp)
    80000928:	6aa2                	ld	s5,8(sp)
    8000092a:	6121                	addi	sp,sp,64
    8000092c:	8082                	ret
    8000092e:	8082                	ret

0000000080000930 <uartputc>:
{
    80000930:	7179                	addi	sp,sp,-48
    80000932:	f406                	sd	ra,40(sp)
    80000934:	f022                	sd	s0,32(sp)
    80000936:	ec26                	sd	s1,24(sp)
    80000938:	e84a                	sd	s2,16(sp)
    8000093a:	e44e                	sd	s3,8(sp)
    8000093c:	e052                	sd	s4,0(sp)
    8000093e:	1800                	addi	s0,sp,48
    80000940:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    80000942:	00018517          	auipc	a0,0x18
    80000946:	c5650513          	addi	a0,a0,-938 # 80018598 <uart_tx_lock>
    8000094a:	00000097          	auipc	ra,0x0
    8000094e:	2fe080e7          	jalr	766(ra) # 80000c48 <acquire>
  if(panicked){
    80000952:	00010797          	auipc	a5,0x10
    80000956:	9ee7a783          	lw	a5,-1554(a5) # 80010340 <panicked>
    8000095a:	e7c9                	bnez	a5,800009e4 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000095c:	00010717          	auipc	a4,0x10
    80000960:	9f473703          	ld	a4,-1548(a4) # 80010350 <uart_tx_w>
    80000964:	00010797          	auipc	a5,0x10
    80000968:	9e47b783          	ld	a5,-1564(a5) # 80010348 <uart_tx_r>
    8000096c:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000970:	00018997          	auipc	s3,0x18
    80000974:	c2898993          	addi	s3,s3,-984 # 80018598 <uart_tx_lock>
    80000978:	00010497          	auipc	s1,0x10
    8000097c:	9d048493          	addi	s1,s1,-1584 # 80010348 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000980:	00010917          	auipc	s2,0x10
    80000984:	9d090913          	addi	s2,s2,-1584 # 80010350 <uart_tx_w>
    80000988:	00e79f63          	bne	a5,a4,800009a6 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000098c:	85ce                	mv	a1,s3
    8000098e:	8526                	mv	a0,s1
    80000990:	00001097          	auipc	ra,0x1
    80000994:	776080e7          	jalr	1910(ra) # 80002106 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000998:	00093703          	ld	a4,0(s2)
    8000099c:	609c                	ld	a5,0(s1)
    8000099e:	02078793          	addi	a5,a5,32
    800009a2:	fee785e3          	beq	a5,a4,8000098c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    800009a6:	00018497          	auipc	s1,0x18
    800009aa:	bf248493          	addi	s1,s1,-1038 # 80018598 <uart_tx_lock>
    800009ae:	01f77793          	andi	a5,a4,31
    800009b2:	97a6                	add	a5,a5,s1
    800009b4:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    800009b8:	0705                	addi	a4,a4,1
    800009ba:	00010797          	auipc	a5,0x10
    800009be:	98e7bb23          	sd	a4,-1642(a5) # 80010350 <uart_tx_w>
  uartstart();
    800009c2:	00000097          	auipc	ra,0x0
    800009c6:	ee8080e7          	jalr	-280(ra) # 800008aa <uartstart>
  release(&uart_tx_lock);
    800009ca:	8526                	mv	a0,s1
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	330080e7          	jalr	816(ra) # 80000cfc <release>
}
    800009d4:	70a2                	ld	ra,40(sp)
    800009d6:	7402                	ld	s0,32(sp)
    800009d8:	64e2                	ld	s1,24(sp)
    800009da:	6942                	ld	s2,16(sp)
    800009dc:	69a2                	ld	s3,8(sp)
    800009de:	6a02                	ld	s4,0(sp)
    800009e0:	6145                	addi	sp,sp,48
    800009e2:	8082                	ret
    for(;;)
    800009e4:	a001                	j	800009e4 <uartputc+0xb4>

00000000800009e6 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009e6:	1141                	addi	sp,sp,-16
    800009e8:	e422                	sd	s0,8(sp)
    800009ea:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009ec:	100007b7          	lui	a5,0x10000
    800009f0:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009f4:	8b85                	andi	a5,a5,1
    800009f6:	cb81                	beqz	a5,80000a06 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    800009f8:	100007b7          	lui	a5,0x10000
    800009fc:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    80000a00:	6422                	ld	s0,8(sp)
    80000a02:	0141                	addi	sp,sp,16
    80000a04:	8082                	ret
    return -1;
    80000a06:	557d                	li	a0,-1
    80000a08:	bfe5                	j	80000a00 <uartgetc+0x1a>

0000000080000a0a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000a0a:	1101                	addi	sp,sp,-32
    80000a0c:	ec06                	sd	ra,24(sp)
    80000a0e:	e822                	sd	s0,16(sp)
    80000a10:	e426                	sd	s1,8(sp)
    80000a12:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a14:	54fd                	li	s1,-1
    80000a16:	a029                	j	80000a20 <uartintr+0x16>
      break;
    consoleintr(c);
    80000a18:	00000097          	auipc	ra,0x0
    80000a1c:	8a6080e7          	jalr	-1882(ra) # 800002be <consoleintr>
    int c = uartgetc();
    80000a20:	00000097          	auipc	ra,0x0
    80000a24:	fc6080e7          	jalr	-58(ra) # 800009e6 <uartgetc>
    if(c == -1)
    80000a28:	fe9518e3          	bne	a0,s1,80000a18 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a2c:	00018497          	auipc	s1,0x18
    80000a30:	b6c48493          	addi	s1,s1,-1172 # 80018598 <uart_tx_lock>
    80000a34:	8526                	mv	a0,s1
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	212080e7          	jalr	530(ra) # 80000c48 <acquire>
  uartstart();
    80000a3e:	00000097          	auipc	ra,0x0
    80000a42:	e6c080e7          	jalr	-404(ra) # 800008aa <uartstart>
  release(&uart_tx_lock);
    80000a46:	8526                	mv	a0,s1
    80000a48:	00000097          	auipc	ra,0x0
    80000a4c:	2b4080e7          	jalr	692(ra) # 80000cfc <release>
}
    80000a50:	60e2                	ld	ra,24(sp)
    80000a52:	6442                	ld	s0,16(sp)
    80000a54:	64a2                	ld	s1,8(sp)
    80000a56:	6105                	addi	sp,sp,32
    80000a58:	8082                	ret

0000000080000a5a <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a5a:	1101                	addi	sp,sp,-32
    80000a5c:	ec06                	sd	ra,24(sp)
    80000a5e:	e822                	sd	s0,16(sp)
    80000a60:	e426                	sd	s1,8(sp)
    80000a62:	e04a                	sd	s2,0(sp)
    80000a64:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a66:	03451793          	slli	a5,a0,0x34
    80000a6a:	ebb9                	bnez	a5,80000ac0 <kfree+0x66>
    80000a6c:	84aa                	mv	s1,a0
    80000a6e:	00029797          	auipc	a5,0x29
    80000a72:	16278793          	addi	a5,a5,354 # 80029bd0 <end>
    80000a76:	04f56563          	bltu	a0,a5,80000ac0 <kfree+0x66>
    80000a7a:	47c5                	li	a5,17
    80000a7c:	07ee                	slli	a5,a5,0x1b
    80000a7e:	04f57163          	bgeu	a0,a5,80000ac0 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a82:	6605                	lui	a2,0x1
    80000a84:	4585                	li	a1,1
    80000a86:	00000097          	auipc	ra,0x0
    80000a8a:	2be080e7          	jalr	702(ra) # 80000d44 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a8e:	00018917          	auipc	s2,0x18
    80000a92:	b4290913          	addi	s2,s2,-1214 # 800185d0 <kmem>
    80000a96:	854a                	mv	a0,s2
    80000a98:	00000097          	auipc	ra,0x0
    80000a9c:	1b0080e7          	jalr	432(ra) # 80000c48 <acquire>
  r->next = kmem.freelist;
    80000aa0:	01893783          	ld	a5,24(s2)
    80000aa4:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000aa6:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000aaa:	854a                	mv	a0,s2
    80000aac:	00000097          	auipc	ra,0x0
    80000ab0:	250080e7          	jalr	592(ra) # 80000cfc <release>
}
    80000ab4:	60e2                	ld	ra,24(sp)
    80000ab6:	6442                	ld	s0,16(sp)
    80000ab8:	64a2                	ld	s1,8(sp)
    80000aba:	6902                	ld	s2,0(sp)
    80000abc:	6105                	addi	sp,sp,32
    80000abe:	8082                	ret
    panic("kfree");
    80000ac0:	00007517          	auipc	a0,0x7
    80000ac4:	5a050513          	addi	a0,a0,1440 # 80008060 <digits+0x20>
    80000ac8:	00000097          	auipc	ra,0x0
    80000acc:	a78080e7          	jalr	-1416(ra) # 80000540 <panic>

0000000080000ad0 <freerange>:
{
    80000ad0:	7179                	addi	sp,sp,-48
    80000ad2:	f406                	sd	ra,40(sp)
    80000ad4:	f022                	sd	s0,32(sp)
    80000ad6:	ec26                	sd	s1,24(sp)
    80000ad8:	e84a                	sd	s2,16(sp)
    80000ada:	e44e                	sd	s3,8(sp)
    80000adc:	e052                	sd	s4,0(sp)
    80000ade:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000ae0:	6785                	lui	a5,0x1
    80000ae2:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000ae6:	00e504b3          	add	s1,a0,a4
    80000aea:	777d                	lui	a4,0xfffff
    80000aec:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aee:	94be                	add	s1,s1,a5
    80000af0:	0095ee63          	bltu	a1,s1,80000b0c <freerange+0x3c>
    80000af4:	892e                	mv	s2,a1
    kfree(p);
    80000af6:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000af8:	6985                	lui	s3,0x1
    kfree(p);
    80000afa:	01448533          	add	a0,s1,s4
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	f5c080e7          	jalr	-164(ra) # 80000a5a <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b06:	94ce                	add	s1,s1,s3
    80000b08:	fe9979e3          	bgeu	s2,s1,80000afa <freerange+0x2a>
}
    80000b0c:	70a2                	ld	ra,40(sp)
    80000b0e:	7402                	ld	s0,32(sp)
    80000b10:	64e2                	ld	s1,24(sp)
    80000b12:	6942                	ld	s2,16(sp)
    80000b14:	69a2                	ld	s3,8(sp)
    80000b16:	6a02                	ld	s4,0(sp)
    80000b18:	6145                	addi	sp,sp,48
    80000b1a:	8082                	ret

0000000080000b1c <kinit>:
{
    80000b1c:	1141                	addi	sp,sp,-16
    80000b1e:	e406                	sd	ra,8(sp)
    80000b20:	e022                	sd	s0,0(sp)
    80000b22:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b24:	00007597          	auipc	a1,0x7
    80000b28:	54458593          	addi	a1,a1,1348 # 80008068 <digits+0x28>
    80000b2c:	00018517          	auipc	a0,0x18
    80000b30:	aa450513          	addi	a0,a0,-1372 # 800185d0 <kmem>
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	084080e7          	jalr	132(ra) # 80000bb8 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b3c:	45c5                	li	a1,17
    80000b3e:	05ee                	slli	a1,a1,0x1b
    80000b40:	00029517          	auipc	a0,0x29
    80000b44:	09050513          	addi	a0,a0,144 # 80029bd0 <end>
    80000b48:	00000097          	auipc	ra,0x0
    80000b4c:	f88080e7          	jalr	-120(ra) # 80000ad0 <freerange>
}
    80000b50:	60a2                	ld	ra,8(sp)
    80000b52:	6402                	ld	s0,0(sp)
    80000b54:	0141                	addi	sp,sp,16
    80000b56:	8082                	ret

0000000080000b58 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b58:	1101                	addi	sp,sp,-32
    80000b5a:	ec06                	sd	ra,24(sp)
    80000b5c:	e822                	sd	s0,16(sp)
    80000b5e:	e426                	sd	s1,8(sp)
    80000b60:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b62:	00018497          	auipc	s1,0x18
    80000b66:	a6e48493          	addi	s1,s1,-1426 # 800185d0 <kmem>
    80000b6a:	8526                	mv	a0,s1
    80000b6c:	00000097          	auipc	ra,0x0
    80000b70:	0dc080e7          	jalr	220(ra) # 80000c48 <acquire>
  r = kmem.freelist;
    80000b74:	6c84                	ld	s1,24(s1)
  if(r)
    80000b76:	c885                	beqz	s1,80000ba6 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b78:	609c                	ld	a5,0(s1)
    80000b7a:	00018517          	auipc	a0,0x18
    80000b7e:	a5650513          	addi	a0,a0,-1450 # 800185d0 <kmem>
    80000b82:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b84:	00000097          	auipc	ra,0x0
    80000b88:	178080e7          	jalr	376(ra) # 80000cfc <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b8c:	6605                	lui	a2,0x1
    80000b8e:	4595                	li	a1,5
    80000b90:	8526                	mv	a0,s1
    80000b92:	00000097          	auipc	ra,0x0
    80000b96:	1b2080e7          	jalr	434(ra) # 80000d44 <memset>
  return (void*)r;
}
    80000b9a:	8526                	mv	a0,s1
    80000b9c:	60e2                	ld	ra,24(sp)
    80000b9e:	6442                	ld	s0,16(sp)
    80000ba0:	64a2                	ld	s1,8(sp)
    80000ba2:	6105                	addi	sp,sp,32
    80000ba4:	8082                	ret
  release(&kmem.lock);
    80000ba6:	00018517          	auipc	a0,0x18
    80000baa:	a2a50513          	addi	a0,a0,-1494 # 800185d0 <kmem>
    80000bae:	00000097          	auipc	ra,0x0
    80000bb2:	14e080e7          	jalr	334(ra) # 80000cfc <release>
  if(r)
    80000bb6:	b7d5                	j	80000b9a <kalloc+0x42>

0000000080000bb8 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bb8:	1141                	addi	sp,sp,-16
    80000bba:	e422                	sd	s0,8(sp)
    80000bbc:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bbe:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bc0:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bc4:	00053823          	sd	zero,16(a0)
}
    80000bc8:	6422                	ld	s0,8(sp)
    80000bca:	0141                	addi	sp,sp,16
    80000bcc:	8082                	ret

0000000080000bce <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bce:	411c                	lw	a5,0(a0)
    80000bd0:	e399                	bnez	a5,80000bd6 <holding+0x8>
    80000bd2:	4501                	li	a0,0
  return r;
}
    80000bd4:	8082                	ret
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000be0:	6904                	ld	s1,16(a0)
    80000be2:	00001097          	auipc	ra,0x1
    80000be6:	e26080e7          	jalr	-474(ra) # 80001a08 <mycpu>
    80000bea:	40a48533          	sub	a0,s1,a0
    80000bee:	00153513          	seqz	a0,a0
}
    80000bf2:	60e2                	ld	ra,24(sp)
    80000bf4:	6442                	ld	s0,16(sp)
    80000bf6:	64a2                	ld	s1,8(sp)
    80000bf8:	6105                	addi	sp,sp,32
    80000bfa:	8082                	ret

0000000080000bfc <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bfc:	1101                	addi	sp,sp,-32
    80000bfe:	ec06                	sd	ra,24(sp)
    80000c00:	e822                	sd	s0,16(sp)
    80000c02:	e426                	sd	s1,8(sp)
    80000c04:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c06:	100024f3          	csrr	s1,sstatus
    80000c0a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c0e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c10:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	df4080e7          	jalr	-524(ra) # 80001a08 <mycpu>
    80000c1c:	5d3c                	lw	a5,120(a0)
    80000c1e:	cf89                	beqz	a5,80000c38 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c20:	00001097          	auipc	ra,0x1
    80000c24:	de8080e7          	jalr	-536(ra) # 80001a08 <mycpu>
    80000c28:	5d3c                	lw	a5,120(a0)
    80000c2a:	2785                	addiw	a5,a5,1
    80000c2c:	dd3c                	sw	a5,120(a0)
}
    80000c2e:	60e2                	ld	ra,24(sp)
    80000c30:	6442                	ld	s0,16(sp)
    80000c32:	64a2                	ld	s1,8(sp)
    80000c34:	6105                	addi	sp,sp,32
    80000c36:	8082                	ret
    mycpu()->intena = old;
    80000c38:	00001097          	auipc	ra,0x1
    80000c3c:	dd0080e7          	jalr	-560(ra) # 80001a08 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c40:	8085                	srli	s1,s1,0x1
    80000c42:	8885                	andi	s1,s1,1
    80000c44:	dd64                	sw	s1,124(a0)
    80000c46:	bfe9                	j	80000c20 <push_off+0x24>

0000000080000c48 <acquire>:
{
    80000c48:	1101                	addi	sp,sp,-32
    80000c4a:	ec06                	sd	ra,24(sp)
    80000c4c:	e822                	sd	s0,16(sp)
    80000c4e:	e426                	sd	s1,8(sp)
    80000c50:	1000                	addi	s0,sp,32
    80000c52:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c54:	00000097          	auipc	ra,0x0
    80000c58:	fa8080e7          	jalr	-88(ra) # 80000bfc <push_off>
  if(holding(lk))
    80000c5c:	8526                	mv	a0,s1
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	f70080e7          	jalr	-144(ra) # 80000bce <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c66:	4705                	li	a4,1
  if(holding(lk))
    80000c68:	e115                	bnez	a0,80000c8c <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c6a:	87ba                	mv	a5,a4
    80000c6c:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c70:	2781                	sext.w	a5,a5
    80000c72:	ffe5                	bnez	a5,80000c6a <acquire+0x22>
  __sync_synchronize();
    80000c74:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c78:	00001097          	auipc	ra,0x1
    80000c7c:	d90080e7          	jalr	-624(ra) # 80001a08 <mycpu>
    80000c80:	e888                	sd	a0,16(s1)
}
    80000c82:	60e2                	ld	ra,24(sp)
    80000c84:	6442                	ld	s0,16(sp)
    80000c86:	64a2                	ld	s1,8(sp)
    80000c88:	6105                	addi	sp,sp,32
    80000c8a:	8082                	ret
    panic("acquire");
    80000c8c:	00007517          	auipc	a0,0x7
    80000c90:	3e450513          	addi	a0,a0,996 # 80008070 <digits+0x30>
    80000c94:	00000097          	auipc	ra,0x0
    80000c98:	8ac080e7          	jalr	-1876(ra) # 80000540 <panic>

0000000080000c9c <pop_off>:

void
pop_off(void)
{
    80000c9c:	1141                	addi	sp,sp,-16
    80000c9e:	e406                	sd	ra,8(sp)
    80000ca0:	e022                	sd	s0,0(sp)
    80000ca2:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000ca4:	00001097          	auipc	ra,0x1
    80000ca8:	d64080e7          	jalr	-668(ra) # 80001a08 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cac:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cb0:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000cb2:	e78d                	bnez	a5,80000cdc <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000cb4:	5d3c                	lw	a5,120(a0)
    80000cb6:	02f05b63          	blez	a5,80000cec <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000cba:	37fd                	addiw	a5,a5,-1
    80000cbc:	0007871b          	sext.w	a4,a5
    80000cc0:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cc2:	eb09                	bnez	a4,80000cd4 <pop_off+0x38>
    80000cc4:	5d7c                	lw	a5,124(a0)
    80000cc6:	c799                	beqz	a5,80000cd4 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cc8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000ccc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cd0:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cd4:	60a2                	ld	ra,8(sp)
    80000cd6:	6402                	ld	s0,0(sp)
    80000cd8:	0141                	addi	sp,sp,16
    80000cda:	8082                	ret
    panic("pop_off - interruptible");
    80000cdc:	00007517          	auipc	a0,0x7
    80000ce0:	39c50513          	addi	a0,a0,924 # 80008078 <digits+0x38>
    80000ce4:	00000097          	auipc	ra,0x0
    80000ce8:	85c080e7          	jalr	-1956(ra) # 80000540 <panic>
    panic("pop_off");
    80000cec:	00007517          	auipc	a0,0x7
    80000cf0:	3a450513          	addi	a0,a0,932 # 80008090 <digits+0x50>
    80000cf4:	00000097          	auipc	ra,0x0
    80000cf8:	84c080e7          	jalr	-1972(ra) # 80000540 <panic>

0000000080000cfc <release>:
{
    80000cfc:	1101                	addi	sp,sp,-32
    80000cfe:	ec06                	sd	ra,24(sp)
    80000d00:	e822                	sd	s0,16(sp)
    80000d02:	e426                	sd	s1,8(sp)
    80000d04:	1000                	addi	s0,sp,32
    80000d06:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d08:	00000097          	auipc	ra,0x0
    80000d0c:	ec6080e7          	jalr	-314(ra) # 80000bce <holding>
    80000d10:	c115                	beqz	a0,80000d34 <release+0x38>
  lk->cpu = 0;
    80000d12:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d16:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d1a:	0f50000f          	fence	iorw,ow
    80000d1e:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d22:	00000097          	auipc	ra,0x0
    80000d26:	f7a080e7          	jalr	-134(ra) # 80000c9c <pop_off>
}
    80000d2a:	60e2                	ld	ra,24(sp)
    80000d2c:	6442                	ld	s0,16(sp)
    80000d2e:	64a2                	ld	s1,8(sp)
    80000d30:	6105                	addi	sp,sp,32
    80000d32:	8082                	ret
    panic("release");
    80000d34:	00007517          	auipc	a0,0x7
    80000d38:	36450513          	addi	a0,a0,868 # 80008098 <digits+0x58>
    80000d3c:	00000097          	auipc	ra,0x0
    80000d40:	804080e7          	jalr	-2044(ra) # 80000540 <panic>

0000000080000d44 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d44:	1141                	addi	sp,sp,-16
    80000d46:	e422                	sd	s0,8(sp)
    80000d48:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d4a:	ca19                	beqz	a2,80000d60 <memset+0x1c>
    80000d4c:	87aa                	mv	a5,a0
    80000d4e:	1602                	slli	a2,a2,0x20
    80000d50:	9201                	srli	a2,a2,0x20
    80000d52:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d56:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d5a:	0785                	addi	a5,a5,1
    80000d5c:	fee79de3          	bne	a5,a4,80000d56 <memset+0x12>
  }
  return dst;
}
    80000d60:	6422                	ld	s0,8(sp)
    80000d62:	0141                	addi	sp,sp,16
    80000d64:	8082                	ret

0000000080000d66 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d66:	1141                	addi	sp,sp,-16
    80000d68:	e422                	sd	s0,8(sp)
    80000d6a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d6c:	ca05                	beqz	a2,80000d9c <memcmp+0x36>
    80000d6e:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d72:	1682                	slli	a3,a3,0x20
    80000d74:	9281                	srli	a3,a3,0x20
    80000d76:	0685                	addi	a3,a3,1
    80000d78:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d7a:	00054783          	lbu	a5,0(a0)
    80000d7e:	0005c703          	lbu	a4,0(a1)
    80000d82:	00e79863          	bne	a5,a4,80000d92 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d86:	0505                	addi	a0,a0,1
    80000d88:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d8a:	fed518e3          	bne	a0,a3,80000d7a <memcmp+0x14>
  }

  return 0;
    80000d8e:	4501                	li	a0,0
    80000d90:	a019                	j	80000d96 <memcmp+0x30>
      return *s1 - *s2;
    80000d92:	40e7853b          	subw	a0,a5,a4
}
    80000d96:	6422                	ld	s0,8(sp)
    80000d98:	0141                	addi	sp,sp,16
    80000d9a:	8082                	ret
  return 0;
    80000d9c:	4501                	li	a0,0
    80000d9e:	bfe5                	j	80000d96 <memcmp+0x30>

0000000080000da0 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e422                	sd	s0,8(sp)
    80000da4:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000da6:	c205                	beqz	a2,80000dc6 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000da8:	02a5e263          	bltu	a1,a0,80000dcc <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000dac:	1602                	slli	a2,a2,0x20
    80000dae:	9201                	srli	a2,a2,0x20
    80000db0:	00c587b3          	add	a5,a1,a2
{
    80000db4:	872a                	mv	a4,a0
      *d++ = *s++;
    80000db6:	0585                	addi	a1,a1,1
    80000db8:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffd5431>
    80000dba:	fff5c683          	lbu	a3,-1(a1)
    80000dbe:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000dc2:	fef59ae3          	bne	a1,a5,80000db6 <memmove+0x16>

  return dst;
}
    80000dc6:	6422                	ld	s0,8(sp)
    80000dc8:	0141                	addi	sp,sp,16
    80000dca:	8082                	ret
  if(s < d && s + n > d){
    80000dcc:	02061693          	slli	a3,a2,0x20
    80000dd0:	9281                	srli	a3,a3,0x20
    80000dd2:	00d58733          	add	a4,a1,a3
    80000dd6:	fce57be3          	bgeu	a0,a4,80000dac <memmove+0xc>
    d += n;
    80000dda:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000ddc:	fff6079b          	addiw	a5,a2,-1
    80000de0:	1782                	slli	a5,a5,0x20
    80000de2:	9381                	srli	a5,a5,0x20
    80000de4:	fff7c793          	not	a5,a5
    80000de8:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000dea:	177d                	addi	a4,a4,-1
    80000dec:	16fd                	addi	a3,a3,-1
    80000dee:	00074603          	lbu	a2,0(a4)
    80000df2:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000df6:	fee79ae3          	bne	a5,a4,80000dea <memmove+0x4a>
    80000dfa:	b7f1                	j	80000dc6 <memmove+0x26>

0000000080000dfc <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dfc:	1141                	addi	sp,sp,-16
    80000dfe:	e406                	sd	ra,8(sp)
    80000e00:	e022                	sd	s0,0(sp)
    80000e02:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e04:	00000097          	auipc	ra,0x0
    80000e08:	f9c080e7          	jalr	-100(ra) # 80000da0 <memmove>
}
    80000e0c:	60a2                	ld	ra,8(sp)
    80000e0e:	6402                	ld	s0,0(sp)
    80000e10:	0141                	addi	sp,sp,16
    80000e12:	8082                	ret

0000000080000e14 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e14:	1141                	addi	sp,sp,-16
    80000e16:	e422                	sd	s0,8(sp)
    80000e18:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e1a:	ce11                	beqz	a2,80000e36 <strncmp+0x22>
    80000e1c:	00054783          	lbu	a5,0(a0)
    80000e20:	cf89                	beqz	a5,80000e3a <strncmp+0x26>
    80000e22:	0005c703          	lbu	a4,0(a1)
    80000e26:	00f71a63          	bne	a4,a5,80000e3a <strncmp+0x26>
    n--, p++, q++;
    80000e2a:	367d                	addiw	a2,a2,-1
    80000e2c:	0505                	addi	a0,a0,1
    80000e2e:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e30:	f675                	bnez	a2,80000e1c <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e32:	4501                	li	a0,0
    80000e34:	a809                	j	80000e46 <strncmp+0x32>
    80000e36:	4501                	li	a0,0
    80000e38:	a039                	j	80000e46 <strncmp+0x32>
  if(n == 0)
    80000e3a:	ca09                	beqz	a2,80000e4c <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e3c:	00054503          	lbu	a0,0(a0)
    80000e40:	0005c783          	lbu	a5,0(a1)
    80000e44:	9d1d                	subw	a0,a0,a5
}
    80000e46:	6422                	ld	s0,8(sp)
    80000e48:	0141                	addi	sp,sp,16
    80000e4a:	8082                	ret
    return 0;
    80000e4c:	4501                	li	a0,0
    80000e4e:	bfe5                	j	80000e46 <strncmp+0x32>

0000000080000e50 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e50:	1141                	addi	sp,sp,-16
    80000e52:	e422                	sd	s0,8(sp)
    80000e54:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e56:	87aa                	mv	a5,a0
    80000e58:	86b2                	mv	a3,a2
    80000e5a:	367d                	addiw	a2,a2,-1
    80000e5c:	00d05963          	blez	a3,80000e6e <strncpy+0x1e>
    80000e60:	0785                	addi	a5,a5,1
    80000e62:	0005c703          	lbu	a4,0(a1)
    80000e66:	fee78fa3          	sb	a4,-1(a5)
    80000e6a:	0585                	addi	a1,a1,1
    80000e6c:	f775                	bnez	a4,80000e58 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e6e:	873e                	mv	a4,a5
    80000e70:	9fb5                	addw	a5,a5,a3
    80000e72:	37fd                	addiw	a5,a5,-1
    80000e74:	00c05963          	blez	a2,80000e86 <strncpy+0x36>
    *s++ = 0;
    80000e78:	0705                	addi	a4,a4,1
    80000e7a:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000e7e:	40e786bb          	subw	a3,a5,a4
    80000e82:	fed04be3          	bgtz	a3,80000e78 <strncpy+0x28>
  return os;
}
    80000e86:	6422                	ld	s0,8(sp)
    80000e88:	0141                	addi	sp,sp,16
    80000e8a:	8082                	ret

0000000080000e8c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e8c:	1141                	addi	sp,sp,-16
    80000e8e:	e422                	sd	s0,8(sp)
    80000e90:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e92:	02c05363          	blez	a2,80000eb8 <safestrcpy+0x2c>
    80000e96:	fff6069b          	addiw	a3,a2,-1
    80000e9a:	1682                	slli	a3,a3,0x20
    80000e9c:	9281                	srli	a3,a3,0x20
    80000e9e:	96ae                	add	a3,a3,a1
    80000ea0:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ea2:	00d58963          	beq	a1,a3,80000eb4 <safestrcpy+0x28>
    80000ea6:	0585                	addi	a1,a1,1
    80000ea8:	0785                	addi	a5,a5,1
    80000eaa:	fff5c703          	lbu	a4,-1(a1)
    80000eae:	fee78fa3          	sb	a4,-1(a5)
    80000eb2:	fb65                	bnez	a4,80000ea2 <safestrcpy+0x16>
    ;
  *s = 0;
    80000eb4:	00078023          	sb	zero,0(a5)
  return os;
}
    80000eb8:	6422                	ld	s0,8(sp)
    80000eba:	0141                	addi	sp,sp,16
    80000ebc:	8082                	ret

0000000080000ebe <strlen>:

int
strlen(const char *s)
{
    80000ebe:	1141                	addi	sp,sp,-16
    80000ec0:	e422                	sd	s0,8(sp)
    80000ec2:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ec4:	00054783          	lbu	a5,0(a0)
    80000ec8:	cf91                	beqz	a5,80000ee4 <strlen+0x26>
    80000eca:	0505                	addi	a0,a0,1
    80000ecc:	87aa                	mv	a5,a0
    80000ece:	86be                	mv	a3,a5
    80000ed0:	0785                	addi	a5,a5,1
    80000ed2:	fff7c703          	lbu	a4,-1(a5)
    80000ed6:	ff65                	bnez	a4,80000ece <strlen+0x10>
    80000ed8:	40a6853b          	subw	a0,a3,a0
    80000edc:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000ede:	6422                	ld	s0,8(sp)
    80000ee0:	0141                	addi	sp,sp,16
    80000ee2:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ee4:	4501                	li	a0,0
    80000ee6:	bfe5                	j	80000ede <strlen+0x20>

0000000080000ee8 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ee8:	1141                	addi	sp,sp,-16
    80000eea:	e406                	sd	ra,8(sp)
    80000eec:	e022                	sd	s0,0(sp)
    80000eee:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ef0:	00001097          	auipc	ra,0x1
    80000ef4:	b08080e7          	jalr	-1272(ra) # 800019f8 <cpuid>
    trap_and_emulate_init();

    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ef8:	0000f717          	auipc	a4,0xf
    80000efc:	46070713          	addi	a4,a4,1120 # 80010358 <started>
  if(cpuid() == 0){
    80000f00:	c139                	beqz	a0,80000f46 <main+0x5e>
    while(started == 0)
    80000f02:	431c                	lw	a5,0(a4)
    80000f04:	2781                	sext.w	a5,a5
    80000f06:	dff5                	beqz	a5,80000f02 <main+0x1a>
      ;
    __sync_synchronize();
    80000f08:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f0c:	00001097          	auipc	ra,0x1
    80000f10:	aec080e7          	jalr	-1300(ra) # 800019f8 <cpuid>
    80000f14:	85aa                	mv	a1,a0
    80000f16:	00007517          	auipc	a0,0x7
    80000f1a:	1a250513          	addi	a0,a0,418 # 800080b8 <digits+0x78>
    80000f1e:	fffff097          	auipc	ra,0xfffff
    80000f22:	66c080e7          	jalr	1644(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	0e0080e7          	jalr	224(ra) # 80001006 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	7ce080e7          	jalr	1998(ra) # 800026fc <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f36:	00005097          	auipc	ra,0x5
    80000f3a:	daa080e7          	jalr	-598(ra) # 80005ce0 <plicinithart>
  }

  scheduler();        
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	016080e7          	jalr	22(ra) # 80001f54 <scheduler>
    consoleinit();
    80000f46:	fffff097          	auipc	ra,0xfffff
    80000f4a:	50a080e7          	jalr	1290(ra) # 80000450 <consoleinit>
    printfinit();
    80000f4e:	00000097          	auipc	ra,0x0
    80000f52:	89a080e7          	jalr	-1894(ra) # 800007e8 <printfinit>
    printf("\n");
    80000f56:	0000f517          	auipc	a0,0xf
    80000f5a:	2e250513          	addi	a0,a0,738 # 80010238 <csr_vm_map+0x78f8>
    80000f5e:	fffff097          	auipc	ra,0xfffff
    80000f62:	62c080e7          	jalr	1580(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000f66:	00007517          	auipc	a0,0x7
    80000f6a:	13a50513          	addi	a0,a0,314 # 800080a0 <digits+0x60>
    80000f6e:	fffff097          	auipc	ra,0xfffff
    80000f72:	61c080e7          	jalr	1564(ra) # 8000058a <printf>
    printf("\n");
    80000f76:	0000f517          	auipc	a0,0xf
    80000f7a:	2c250513          	addi	a0,a0,706 # 80010238 <csr_vm_map+0x78f8>
    80000f7e:	fffff097          	auipc	ra,0xfffff
    80000f82:	60c080e7          	jalr	1548(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f86:	00000097          	auipc	ra,0x0
    80000f8a:	b96080e7          	jalr	-1130(ra) # 80000b1c <kinit>
    kvminit();       // create kernel page table
    80000f8e:	00000097          	auipc	ra,0x0
    80000f92:	32e080e7          	jalr	814(ra) # 800012bc <kvminit>
    kvminithart();   // turn on paging
    80000f96:	00000097          	auipc	ra,0x0
    80000f9a:	070080e7          	jalr	112(ra) # 80001006 <kvminithart>
    procinit();      // process table
    80000f9e:	00001097          	auipc	ra,0x1
    80000fa2:	9a6080e7          	jalr	-1626(ra) # 80001944 <procinit>
    trapinit();      // trap vectors
    80000fa6:	00001097          	auipc	ra,0x1
    80000faa:	72e080e7          	jalr	1838(ra) # 800026d4 <trapinit>
    trapinithart();  // install kernel trap vector
    80000fae:	00001097          	auipc	ra,0x1
    80000fb2:	74e080e7          	jalr	1870(ra) # 800026fc <trapinithart>
    plicinit();      // set up interrupt controller
    80000fb6:	00005097          	auipc	ra,0x5
    80000fba:	d14080e7          	jalr	-748(ra) # 80005cca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fbe:	00005097          	auipc	ra,0x5
    80000fc2:	d22080e7          	jalr	-734(ra) # 80005ce0 <plicinithart>
    binit();         // buffer cache
    80000fc6:	00002097          	auipc	ra,0x2
    80000fca:	eae080e7          	jalr	-338(ra) # 80002e74 <binit>
    iinit();         // inode table
    80000fce:	00002097          	auipc	ra,0x2
    80000fd2:	54c080e7          	jalr	1356(ra) # 8000351a <iinit>
    fileinit();      // file table
    80000fd6:	00003097          	auipc	ra,0x3
    80000fda:	4c2080e7          	jalr	1218(ra) # 80004498 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fde:	00005097          	auipc	ra,0x5
    80000fe2:	e0a080e7          	jalr	-502(ra) # 80005de8 <virtio_disk_init>
    userinit();      // first user process
    80000fe6:	00001097          	auipc	ra,0x1
    80000fea:	d50080e7          	jalr	-688(ra) # 80001d36 <userinit>
    trap_and_emulate_init();
    80000fee:	00005097          	auipc	ra,0x5
    80000ff2:	696080e7          	jalr	1686(ra) # 80006684 <trap_and_emulate_init>
    __sync_synchronize();
    80000ff6:	0ff0000f          	fence
    started = 1;
    80000ffa:	4785                	li	a5,1
    80000ffc:	0000f717          	auipc	a4,0xf
    80001000:	34f72e23          	sw	a5,860(a4) # 80010358 <started>
    80001004:	bf2d                	j	80000f3e <main+0x56>

0000000080001006 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001006:	1141                	addi	sp,sp,-16
    80001008:	e422                	sd	s0,8(sp)
    8000100a:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000100c:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80001010:	0000f797          	auipc	a5,0xf
    80001014:	3507b783          	ld	a5,848(a5) # 80010360 <kernel_pagetable>
    80001018:	83b1                	srli	a5,a5,0xc
    8000101a:	577d                	li	a4,-1
    8000101c:	177e                	slli	a4,a4,0x3f
    8000101e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001020:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001024:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001028:	6422                	ld	s0,8(sp)
    8000102a:	0141                	addi	sp,sp,16
    8000102c:	8082                	ret

000000008000102e <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000102e:	7139                	addi	sp,sp,-64
    80001030:	fc06                	sd	ra,56(sp)
    80001032:	f822                	sd	s0,48(sp)
    80001034:	f426                	sd	s1,40(sp)
    80001036:	f04a                	sd	s2,32(sp)
    80001038:	ec4e                	sd	s3,24(sp)
    8000103a:	e852                	sd	s4,16(sp)
    8000103c:	e456                	sd	s5,8(sp)
    8000103e:	e05a                	sd	s6,0(sp)
    80001040:	0080                	addi	s0,sp,64
    80001042:	84aa                	mv	s1,a0
    80001044:	89ae                	mv	s3,a1
    80001046:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001048:	57fd                	li	a5,-1
    8000104a:	83e9                	srli	a5,a5,0x1a
    8000104c:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000104e:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001050:	04b7f263          	bgeu	a5,a1,80001094 <walk+0x66>
    panic("walk");
    80001054:	00007517          	auipc	a0,0x7
    80001058:	07c50513          	addi	a0,a0,124 # 800080d0 <digits+0x90>
    8000105c:	fffff097          	auipc	ra,0xfffff
    80001060:	4e4080e7          	jalr	1252(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001064:	060a8663          	beqz	s5,800010d0 <walk+0xa2>
    80001068:	00000097          	auipc	ra,0x0
    8000106c:	af0080e7          	jalr	-1296(ra) # 80000b58 <kalloc>
    80001070:	84aa                	mv	s1,a0
    80001072:	c529                	beqz	a0,800010bc <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001074:	6605                	lui	a2,0x1
    80001076:	4581                	li	a1,0
    80001078:	00000097          	auipc	ra,0x0
    8000107c:	ccc080e7          	jalr	-820(ra) # 80000d44 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001080:	00c4d793          	srli	a5,s1,0xc
    80001084:	07aa                	slli	a5,a5,0xa
    80001086:	0017e793          	ori	a5,a5,1
    8000108a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000108e:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd5427>
    80001090:	036a0063          	beq	s4,s6,800010b0 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001094:	0149d933          	srl	s2,s3,s4
    80001098:	1ff97913          	andi	s2,s2,511
    8000109c:	090e                	slli	s2,s2,0x3
    8000109e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010a0:	00093483          	ld	s1,0(s2)
    800010a4:	0014f793          	andi	a5,s1,1
    800010a8:	dfd5                	beqz	a5,80001064 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010aa:	80a9                	srli	s1,s1,0xa
    800010ac:	04b2                	slli	s1,s1,0xc
    800010ae:	b7c5                	j	8000108e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010b0:	00c9d513          	srli	a0,s3,0xc
    800010b4:	1ff57513          	andi	a0,a0,511
    800010b8:	050e                	slli	a0,a0,0x3
    800010ba:	9526                	add	a0,a0,s1
}
    800010bc:	70e2                	ld	ra,56(sp)
    800010be:	7442                	ld	s0,48(sp)
    800010c0:	74a2                	ld	s1,40(sp)
    800010c2:	7902                	ld	s2,32(sp)
    800010c4:	69e2                	ld	s3,24(sp)
    800010c6:	6a42                	ld	s4,16(sp)
    800010c8:	6aa2                	ld	s5,8(sp)
    800010ca:	6b02                	ld	s6,0(sp)
    800010cc:	6121                	addi	sp,sp,64
    800010ce:	8082                	ret
        return 0;
    800010d0:	4501                	li	a0,0
    800010d2:	b7ed                	j	800010bc <walk+0x8e>

00000000800010d4 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010d4:	57fd                	li	a5,-1
    800010d6:	83e9                	srli	a5,a5,0x1a
    800010d8:	00b7f463          	bgeu	a5,a1,800010e0 <walkaddr+0xc>
    return 0;
    800010dc:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010de:	8082                	ret
{
    800010e0:	1141                	addi	sp,sp,-16
    800010e2:	e406                	sd	ra,8(sp)
    800010e4:	e022                	sd	s0,0(sp)
    800010e6:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010e8:	4601                	li	a2,0
    800010ea:	00000097          	auipc	ra,0x0
    800010ee:	f44080e7          	jalr	-188(ra) # 8000102e <walk>
  if(pte == 0)
    800010f2:	c105                	beqz	a0,80001112 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010f4:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010f6:	0117f693          	andi	a3,a5,17
    800010fa:	4745                	li	a4,17
    return 0;
    800010fc:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010fe:	00e68663          	beq	a3,a4,8000110a <walkaddr+0x36>
}
    80001102:	60a2                	ld	ra,8(sp)
    80001104:	6402                	ld	s0,0(sp)
    80001106:	0141                	addi	sp,sp,16
    80001108:	8082                	ret
  pa = PTE2PA(*pte);
    8000110a:	83a9                	srli	a5,a5,0xa
    8000110c:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001110:	bfcd                	j	80001102 <walkaddr+0x2e>
    return 0;
    80001112:	4501                	li	a0,0
    80001114:	b7fd                	j	80001102 <walkaddr+0x2e>

0000000080001116 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001116:	715d                	addi	sp,sp,-80
    80001118:	e486                	sd	ra,72(sp)
    8000111a:	e0a2                	sd	s0,64(sp)
    8000111c:	fc26                	sd	s1,56(sp)
    8000111e:	f84a                	sd	s2,48(sp)
    80001120:	f44e                	sd	s3,40(sp)
    80001122:	f052                	sd	s4,32(sp)
    80001124:	ec56                	sd	s5,24(sp)
    80001126:	e85a                	sd	s6,16(sp)
    80001128:	e45e                	sd	s7,8(sp)
    8000112a:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    8000112c:	c639                	beqz	a2,8000117a <mappages+0x64>
    8000112e:	8aaa                	mv	s5,a0
    80001130:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001132:	777d                	lui	a4,0xfffff
    80001134:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001138:	fff58993          	addi	s3,a1,-1
    8000113c:	99b2                	add	s3,s3,a2
    8000113e:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001142:	893e                	mv	s2,a5
    80001144:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001148:	6b85                	lui	s7,0x1
    8000114a:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000114e:	4605                	li	a2,1
    80001150:	85ca                	mv	a1,s2
    80001152:	8556                	mv	a0,s5
    80001154:	00000097          	auipc	ra,0x0
    80001158:	eda080e7          	jalr	-294(ra) # 8000102e <walk>
    8000115c:	cd1d                	beqz	a0,8000119a <mappages+0x84>
    if(*pte & PTE_V)
    8000115e:	611c                	ld	a5,0(a0)
    80001160:	8b85                	andi	a5,a5,1
    80001162:	e785                	bnez	a5,8000118a <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001164:	80b1                	srli	s1,s1,0xc
    80001166:	04aa                	slli	s1,s1,0xa
    80001168:	0164e4b3          	or	s1,s1,s6
    8000116c:	0014e493          	ori	s1,s1,1
    80001170:	e104                	sd	s1,0(a0)
    if(a == last)
    80001172:	05390063          	beq	s2,s3,800011b2 <mappages+0x9c>
    a += PGSIZE;
    80001176:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001178:	bfc9                	j	8000114a <mappages+0x34>
    panic("mappages: size");
    8000117a:	00007517          	auipc	a0,0x7
    8000117e:	f5e50513          	addi	a0,a0,-162 # 800080d8 <digits+0x98>
    80001182:	fffff097          	auipc	ra,0xfffff
    80001186:	3be080e7          	jalr	958(ra) # 80000540 <panic>
      panic("mappages: remap");
    8000118a:	00007517          	auipc	a0,0x7
    8000118e:	f5e50513          	addi	a0,a0,-162 # 800080e8 <digits+0xa8>
    80001192:	fffff097          	auipc	ra,0xfffff
    80001196:	3ae080e7          	jalr	942(ra) # 80000540 <panic>
      return -1;
    8000119a:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000119c:	60a6                	ld	ra,72(sp)
    8000119e:	6406                	ld	s0,64(sp)
    800011a0:	74e2                	ld	s1,56(sp)
    800011a2:	7942                	ld	s2,48(sp)
    800011a4:	79a2                	ld	s3,40(sp)
    800011a6:	7a02                	ld	s4,32(sp)
    800011a8:	6ae2                	ld	s5,24(sp)
    800011aa:	6b42                	ld	s6,16(sp)
    800011ac:	6ba2                	ld	s7,8(sp)
    800011ae:	6161                	addi	sp,sp,80
    800011b0:	8082                	ret
  return 0;
    800011b2:	4501                	li	a0,0
    800011b4:	b7e5                	j	8000119c <mappages+0x86>

00000000800011b6 <kvmmap>:
{
    800011b6:	1141                	addi	sp,sp,-16
    800011b8:	e406                	sd	ra,8(sp)
    800011ba:	e022                	sd	s0,0(sp)
    800011bc:	0800                	addi	s0,sp,16
    800011be:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800011c0:	86b2                	mv	a3,a2
    800011c2:	863e                	mv	a2,a5
    800011c4:	00000097          	auipc	ra,0x0
    800011c8:	f52080e7          	jalr	-174(ra) # 80001116 <mappages>
    800011cc:	e509                	bnez	a0,800011d6 <kvmmap+0x20>
}
    800011ce:	60a2                	ld	ra,8(sp)
    800011d0:	6402                	ld	s0,0(sp)
    800011d2:	0141                	addi	sp,sp,16
    800011d4:	8082                	ret
    panic("kvmmap");
    800011d6:	00007517          	auipc	a0,0x7
    800011da:	f2250513          	addi	a0,a0,-222 # 800080f8 <digits+0xb8>
    800011de:	fffff097          	auipc	ra,0xfffff
    800011e2:	362080e7          	jalr	866(ra) # 80000540 <panic>

00000000800011e6 <kvmmake>:
{
    800011e6:	1101                	addi	sp,sp,-32
    800011e8:	ec06                	sd	ra,24(sp)
    800011ea:	e822                	sd	s0,16(sp)
    800011ec:	e426                	sd	s1,8(sp)
    800011ee:	e04a                	sd	s2,0(sp)
    800011f0:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011f2:	00000097          	auipc	ra,0x0
    800011f6:	966080e7          	jalr	-1690(ra) # 80000b58 <kalloc>
    800011fa:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011fc:	6605                	lui	a2,0x1
    800011fe:	4581                	li	a1,0
    80001200:	00000097          	auipc	ra,0x0
    80001204:	b44080e7          	jalr	-1212(ra) # 80000d44 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	6685                	lui	a3,0x1
    8000120c:	10000637          	lui	a2,0x10000
    80001210:	100005b7          	lui	a1,0x10000
    80001214:	8526                	mv	a0,s1
    80001216:	00000097          	auipc	ra,0x0
    8000121a:	fa0080e7          	jalr	-96(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000121e:	4719                	li	a4,6
    80001220:	6685                	lui	a3,0x1
    80001222:	10001637          	lui	a2,0x10001
    80001226:	100015b7          	lui	a1,0x10001
    8000122a:	8526                	mv	a0,s1
    8000122c:	00000097          	auipc	ra,0x0
    80001230:	f8a080e7          	jalr	-118(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001234:	4719                	li	a4,6
    80001236:	004006b7          	lui	a3,0x400
    8000123a:	0c000637          	lui	a2,0xc000
    8000123e:	0c0005b7          	lui	a1,0xc000
    80001242:	8526                	mv	a0,s1
    80001244:	00000097          	auipc	ra,0x0
    80001248:	f72080e7          	jalr	-142(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000124c:	00007917          	auipc	s2,0x7
    80001250:	db490913          	addi	s2,s2,-588 # 80008000 <etext>
    80001254:	4729                	li	a4,10
    80001256:	80007697          	auipc	a3,0x80007
    8000125a:	daa68693          	addi	a3,a3,-598 # 8000 <_entry-0x7fff8000>
    8000125e:	4605                	li	a2,1
    80001260:	067e                	slli	a2,a2,0x1f
    80001262:	85b2                	mv	a1,a2
    80001264:	8526                	mv	a0,s1
    80001266:	00000097          	auipc	ra,0x0
    8000126a:	f50080e7          	jalr	-176(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000126e:	4719                	li	a4,6
    80001270:	46c5                	li	a3,17
    80001272:	06ee                	slli	a3,a3,0x1b
    80001274:	412686b3          	sub	a3,a3,s2
    80001278:	864a                	mv	a2,s2
    8000127a:	85ca                	mv	a1,s2
    8000127c:	8526                	mv	a0,s1
    8000127e:	00000097          	auipc	ra,0x0
    80001282:	f38080e7          	jalr	-200(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001286:	4729                	li	a4,10
    80001288:	6685                	lui	a3,0x1
    8000128a:	00006617          	auipc	a2,0x6
    8000128e:	d7660613          	addi	a2,a2,-650 # 80007000 <_trampoline>
    80001292:	040005b7          	lui	a1,0x4000
    80001296:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001298:	05b2                	slli	a1,a1,0xc
    8000129a:	8526                	mv	a0,s1
    8000129c:	00000097          	auipc	ra,0x0
    800012a0:	f1a080e7          	jalr	-230(ra) # 800011b6 <kvmmap>
  proc_mapstacks(kpgtbl);
    800012a4:	8526                	mv	a0,s1
    800012a6:	00000097          	auipc	ra,0x0
    800012aa:	608080e7          	jalr	1544(ra) # 800018ae <proc_mapstacks>
}
    800012ae:	8526                	mv	a0,s1
    800012b0:	60e2                	ld	ra,24(sp)
    800012b2:	6442                	ld	s0,16(sp)
    800012b4:	64a2                	ld	s1,8(sp)
    800012b6:	6902                	ld	s2,0(sp)
    800012b8:	6105                	addi	sp,sp,32
    800012ba:	8082                	ret

00000000800012bc <kvminit>:
{
    800012bc:	1141                	addi	sp,sp,-16
    800012be:	e406                	sd	ra,8(sp)
    800012c0:	e022                	sd	s0,0(sp)
    800012c2:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800012c4:	00000097          	auipc	ra,0x0
    800012c8:	f22080e7          	jalr	-222(ra) # 800011e6 <kvmmake>
    800012cc:	0000f797          	auipc	a5,0xf
    800012d0:	08a7ba23          	sd	a0,148(a5) # 80010360 <kernel_pagetable>
}
    800012d4:	60a2                	ld	ra,8(sp)
    800012d6:	6402                	ld	s0,0(sp)
    800012d8:	0141                	addi	sp,sp,16
    800012da:	8082                	ret

00000000800012dc <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012dc:	715d                	addi	sp,sp,-80
    800012de:	e486                	sd	ra,72(sp)
    800012e0:	e0a2                	sd	s0,64(sp)
    800012e2:	fc26                	sd	s1,56(sp)
    800012e4:	f84a                	sd	s2,48(sp)
    800012e6:	f44e                	sd	s3,40(sp)
    800012e8:	f052                	sd	s4,32(sp)
    800012ea:	ec56                	sd	s5,24(sp)
    800012ec:	e85a                	sd	s6,16(sp)
    800012ee:	e45e                	sd	s7,8(sp)
    800012f0:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012f2:	03459793          	slli	a5,a1,0x34
    800012f6:	e795                	bnez	a5,80001322 <uvmunmap+0x46>
    800012f8:	8a2a                	mv	s4,a0
    800012fa:	892e                	mv	s2,a1
    800012fc:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012fe:	0632                	slli	a2,a2,0xc
    80001300:	00b609b3          	add	s3,a2,a1
  // printf("va %p\n",va);
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001304:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001306:	6b05                	lui	s6,0x1
    80001308:	0735e263          	bltu	a1,s3,8000136c <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000130c:	60a6                	ld	ra,72(sp)
    8000130e:	6406                	ld	s0,64(sp)
    80001310:	74e2                	ld	s1,56(sp)
    80001312:	7942                	ld	s2,48(sp)
    80001314:	79a2                	ld	s3,40(sp)
    80001316:	7a02                	ld	s4,32(sp)
    80001318:	6ae2                	ld	s5,24(sp)
    8000131a:	6b42                	ld	s6,16(sp)
    8000131c:	6ba2                	ld	s7,8(sp)
    8000131e:	6161                	addi	sp,sp,80
    80001320:	8082                	ret
    panic("uvmunmap: not aligned");
    80001322:	00007517          	auipc	a0,0x7
    80001326:	dde50513          	addi	a0,a0,-546 # 80008100 <digits+0xc0>
    8000132a:	fffff097          	auipc	ra,0xfffff
    8000132e:	216080e7          	jalr	534(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    80001332:	00007517          	auipc	a0,0x7
    80001336:	de650513          	addi	a0,a0,-538 # 80008118 <digits+0xd8>
    8000133a:	fffff097          	auipc	ra,0xfffff
    8000133e:	206080e7          	jalr	518(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    80001342:	00007517          	auipc	a0,0x7
    80001346:	de650513          	addi	a0,a0,-538 # 80008128 <digits+0xe8>
    8000134a:	fffff097          	auipc	ra,0xfffff
    8000134e:	1f6080e7          	jalr	502(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    80001352:	00007517          	auipc	a0,0x7
    80001356:	dee50513          	addi	a0,a0,-530 # 80008140 <digits+0x100>
    8000135a:	fffff097          	auipc	ra,0xfffff
    8000135e:	1e6080e7          	jalr	486(ra) # 80000540 <panic>
    *pte = 0;
    80001362:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001366:	995a                	add	s2,s2,s6
    80001368:	fb3972e3          	bgeu	s2,s3,8000130c <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000136c:	4601                	li	a2,0
    8000136e:	85ca                	mv	a1,s2
    80001370:	8552                	mv	a0,s4
    80001372:	00000097          	auipc	ra,0x0
    80001376:	cbc080e7          	jalr	-836(ra) # 8000102e <walk>
    8000137a:	84aa                	mv	s1,a0
    8000137c:	d95d                	beqz	a0,80001332 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000137e:	6108                	ld	a0,0(a0)
    80001380:	00157793          	andi	a5,a0,1
    80001384:	dfdd                	beqz	a5,80001342 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001386:	3ff57793          	andi	a5,a0,1023
    8000138a:	fd7784e3          	beq	a5,s7,80001352 <uvmunmap+0x76>
    if(do_free){
    8000138e:	fc0a8ae3          	beqz	s5,80001362 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001392:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001394:	0532                	slli	a0,a0,0xc
    80001396:	fffff097          	auipc	ra,0xfffff
    8000139a:	6c4080e7          	jalr	1732(ra) # 80000a5a <kfree>
    8000139e:	b7d1                	j	80001362 <uvmunmap+0x86>

00000000800013a0 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013a0:	1101                	addi	sp,sp,-32
    800013a2:	ec06                	sd	ra,24(sp)
    800013a4:	e822                	sd	s0,16(sp)
    800013a6:	e426                	sd	s1,8(sp)
    800013a8:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013aa:	fffff097          	auipc	ra,0xfffff
    800013ae:	7ae080e7          	jalr	1966(ra) # 80000b58 <kalloc>
    800013b2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013b4:	c519                	beqz	a0,800013c2 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013b6:	6605                	lui	a2,0x1
    800013b8:	4581                	li	a1,0
    800013ba:	00000097          	auipc	ra,0x0
    800013be:	98a080e7          	jalr	-1654(ra) # 80000d44 <memset>
  return pagetable;
}
    800013c2:	8526                	mv	a0,s1
    800013c4:	60e2                	ld	ra,24(sp)
    800013c6:	6442                	ld	s0,16(sp)
    800013c8:	64a2                	ld	s1,8(sp)
    800013ca:	6105                	addi	sp,sp,32
    800013cc:	8082                	ret

00000000800013ce <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800013ce:	7179                	addi	sp,sp,-48
    800013d0:	f406                	sd	ra,40(sp)
    800013d2:	f022                	sd	s0,32(sp)
    800013d4:	ec26                	sd	s1,24(sp)
    800013d6:	e84a                	sd	s2,16(sp)
    800013d8:	e44e                	sd	s3,8(sp)
    800013da:	e052                	sd	s4,0(sp)
    800013dc:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013de:	6785                	lui	a5,0x1
    800013e0:	04f67863          	bgeu	a2,a5,80001430 <uvmfirst+0x62>
    800013e4:	8a2a                	mv	s4,a0
    800013e6:	89ae                	mv	s3,a1
    800013e8:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800013ea:	fffff097          	auipc	ra,0xfffff
    800013ee:	76e080e7          	jalr	1902(ra) # 80000b58 <kalloc>
    800013f2:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013f4:	6605                	lui	a2,0x1
    800013f6:	4581                	li	a1,0
    800013f8:	00000097          	auipc	ra,0x0
    800013fc:	94c080e7          	jalr	-1716(ra) # 80000d44 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001400:	4779                	li	a4,30
    80001402:	86ca                	mv	a3,s2
    80001404:	6605                	lui	a2,0x1
    80001406:	4581                	li	a1,0
    80001408:	8552                	mv	a0,s4
    8000140a:	00000097          	auipc	ra,0x0
    8000140e:	d0c080e7          	jalr	-756(ra) # 80001116 <mappages>
  memmove(mem, src, sz);
    80001412:	8626                	mv	a2,s1
    80001414:	85ce                	mv	a1,s3
    80001416:	854a                	mv	a0,s2
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	988080e7          	jalr	-1656(ra) # 80000da0 <memmove>
}
    80001420:	70a2                	ld	ra,40(sp)
    80001422:	7402                	ld	s0,32(sp)
    80001424:	64e2                	ld	s1,24(sp)
    80001426:	6942                	ld	s2,16(sp)
    80001428:	69a2                	ld	s3,8(sp)
    8000142a:	6a02                	ld	s4,0(sp)
    8000142c:	6145                	addi	sp,sp,48
    8000142e:	8082                	ret
    panic("uvmfirst: more than a page");
    80001430:	00007517          	auipc	a0,0x7
    80001434:	d2850513          	addi	a0,a0,-728 # 80008158 <digits+0x118>
    80001438:	fffff097          	auipc	ra,0xfffff
    8000143c:	108080e7          	jalr	264(ra) # 80000540 <panic>

0000000080001440 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001440:	1101                	addi	sp,sp,-32
    80001442:	ec06                	sd	ra,24(sp)
    80001444:	e822                	sd	s0,16(sp)
    80001446:	e426                	sd	s1,8(sp)
    80001448:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000144a:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000144c:	00b67d63          	bgeu	a2,a1,80001466 <uvmdealloc+0x26>
    80001450:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001452:	6785                	lui	a5,0x1
    80001454:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001456:	00f60733          	add	a4,a2,a5
    8000145a:	76fd                	lui	a3,0xfffff
    8000145c:	8f75                	and	a4,a4,a3
    8000145e:	97ae                	add	a5,a5,a1
    80001460:	8ff5                	and	a5,a5,a3
    80001462:	00f76863          	bltu	a4,a5,80001472 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001466:	8526                	mv	a0,s1
    80001468:	60e2                	ld	ra,24(sp)
    8000146a:	6442                	ld	s0,16(sp)
    8000146c:	64a2                	ld	s1,8(sp)
    8000146e:	6105                	addi	sp,sp,32
    80001470:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001472:	8f99                	sub	a5,a5,a4
    80001474:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001476:	4685                	li	a3,1
    80001478:	0007861b          	sext.w	a2,a5
    8000147c:	85ba                	mv	a1,a4
    8000147e:	00000097          	auipc	ra,0x0
    80001482:	e5e080e7          	jalr	-418(ra) # 800012dc <uvmunmap>
    80001486:	b7c5                	j	80001466 <uvmdealloc+0x26>

0000000080001488 <uvmalloc>:
  if(newsz < oldsz)
    80001488:	0ab66563          	bltu	a2,a1,80001532 <uvmalloc+0xaa>
{
    8000148c:	7139                	addi	sp,sp,-64
    8000148e:	fc06                	sd	ra,56(sp)
    80001490:	f822                	sd	s0,48(sp)
    80001492:	f426                	sd	s1,40(sp)
    80001494:	f04a                	sd	s2,32(sp)
    80001496:	ec4e                	sd	s3,24(sp)
    80001498:	e852                	sd	s4,16(sp)
    8000149a:	e456                	sd	s5,8(sp)
    8000149c:	e05a                	sd	s6,0(sp)
    8000149e:	0080                	addi	s0,sp,64
    800014a0:	8aaa                	mv	s5,a0
    800014a2:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014a4:	6785                	lui	a5,0x1
    800014a6:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800014a8:	95be                	add	a1,a1,a5
    800014aa:	77fd                	lui	a5,0xfffff
    800014ac:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014b0:	08c9f363          	bgeu	s3,a2,80001536 <uvmalloc+0xae>
    800014b4:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014b6:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800014ba:	fffff097          	auipc	ra,0xfffff
    800014be:	69e080e7          	jalr	1694(ra) # 80000b58 <kalloc>
    800014c2:	84aa                	mv	s1,a0
    if(mem == 0){
    800014c4:	c51d                	beqz	a0,800014f2 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    800014c6:	6605                	lui	a2,0x1
    800014c8:	4581                	li	a1,0
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	87a080e7          	jalr	-1926(ra) # 80000d44 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014d2:	875a                	mv	a4,s6
    800014d4:	86a6                	mv	a3,s1
    800014d6:	6605                	lui	a2,0x1
    800014d8:	85ca                	mv	a1,s2
    800014da:	8556                	mv	a0,s5
    800014dc:	00000097          	auipc	ra,0x0
    800014e0:	c3a080e7          	jalr	-966(ra) # 80001116 <mappages>
    800014e4:	e90d                	bnez	a0,80001516 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014e6:	6785                	lui	a5,0x1
    800014e8:	993e                	add	s2,s2,a5
    800014ea:	fd4968e3          	bltu	s2,s4,800014ba <uvmalloc+0x32>
  return newsz;
    800014ee:	8552                	mv	a0,s4
    800014f0:	a809                	j	80001502 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800014f2:	864e                	mv	a2,s3
    800014f4:	85ca                	mv	a1,s2
    800014f6:	8556                	mv	a0,s5
    800014f8:	00000097          	auipc	ra,0x0
    800014fc:	f48080e7          	jalr	-184(ra) # 80001440 <uvmdealloc>
      return 0;
    80001500:	4501                	li	a0,0
}
    80001502:	70e2                	ld	ra,56(sp)
    80001504:	7442                	ld	s0,48(sp)
    80001506:	74a2                	ld	s1,40(sp)
    80001508:	7902                	ld	s2,32(sp)
    8000150a:	69e2                	ld	s3,24(sp)
    8000150c:	6a42                	ld	s4,16(sp)
    8000150e:	6aa2                	ld	s5,8(sp)
    80001510:	6b02                	ld	s6,0(sp)
    80001512:	6121                	addi	sp,sp,64
    80001514:	8082                	ret
      kfree(mem);
    80001516:	8526                	mv	a0,s1
    80001518:	fffff097          	auipc	ra,0xfffff
    8000151c:	542080e7          	jalr	1346(ra) # 80000a5a <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001520:	864e                	mv	a2,s3
    80001522:	85ca                	mv	a1,s2
    80001524:	8556                	mv	a0,s5
    80001526:	00000097          	auipc	ra,0x0
    8000152a:	f1a080e7          	jalr	-230(ra) # 80001440 <uvmdealloc>
      return 0;
    8000152e:	4501                	li	a0,0
    80001530:	bfc9                	j	80001502 <uvmalloc+0x7a>
    return oldsz;
    80001532:	852e                	mv	a0,a1
}
    80001534:	8082                	ret
  return newsz;
    80001536:	8532                	mv	a0,a2
    80001538:	b7e9                	j	80001502 <uvmalloc+0x7a>

000000008000153a <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000153a:	7179                	addi	sp,sp,-48
    8000153c:	f406                	sd	ra,40(sp)
    8000153e:	f022                	sd	s0,32(sp)
    80001540:	ec26                	sd	s1,24(sp)
    80001542:	e84a                	sd	s2,16(sp)
    80001544:	e44e                	sd	s3,8(sp)
    80001546:	e052                	sd	s4,0(sp)
    80001548:	1800                	addi	s0,sp,48
    8000154a:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000154c:	84aa                	mv	s1,a0
    8000154e:	6905                	lui	s2,0x1
    80001550:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001552:	4985                	li	s3,1
    80001554:	a829                	j	8000156e <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001556:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001558:	00c79513          	slli	a0,a5,0xc
    8000155c:	00000097          	auipc	ra,0x0
    80001560:	fde080e7          	jalr	-34(ra) # 8000153a <freewalk>
      pagetable[i] = 0;
    80001564:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001568:	04a1                	addi	s1,s1,8
    8000156a:	03248163          	beq	s1,s2,8000158c <freewalk+0x52>
    pte_t pte = pagetable[i];
    8000156e:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001570:	00f7f713          	andi	a4,a5,15
    80001574:	ff3701e3          	beq	a4,s3,80001556 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001578:	8b85                	andi	a5,a5,1
    8000157a:	d7fd                	beqz	a5,80001568 <freewalk+0x2e>
      panic("freewalk: leaf");
    8000157c:	00007517          	auipc	a0,0x7
    80001580:	bfc50513          	addi	a0,a0,-1028 # 80008178 <digits+0x138>
    80001584:	fffff097          	auipc	ra,0xfffff
    80001588:	fbc080e7          	jalr	-68(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    8000158c:	8552                	mv	a0,s4
    8000158e:	fffff097          	auipc	ra,0xfffff
    80001592:	4cc080e7          	jalr	1228(ra) # 80000a5a <kfree>
}
    80001596:	70a2                	ld	ra,40(sp)
    80001598:	7402                	ld	s0,32(sp)
    8000159a:	64e2                	ld	s1,24(sp)
    8000159c:	6942                	ld	s2,16(sp)
    8000159e:	69a2                	ld	s3,8(sp)
    800015a0:	6a02                	ld	s4,0(sp)
    800015a2:	6145                	addi	sp,sp,48
    800015a4:	8082                	ret

00000000800015a6 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015a6:	1101                	addi	sp,sp,-32
    800015a8:	ec06                	sd	ra,24(sp)
    800015aa:	e822                	sd	s0,16(sp)
    800015ac:	e426                	sd	s1,8(sp)
    800015ae:	1000                	addi	s0,sp,32
    800015b0:	84aa                	mv	s1,a0
  if(sz > 0)
    800015b2:	e999                	bnez	a1,800015c8 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015b4:	8526                	mv	a0,s1
    800015b6:	00000097          	auipc	ra,0x0
    800015ba:	f84080e7          	jalr	-124(ra) # 8000153a <freewalk>
}
    800015be:	60e2                	ld	ra,24(sp)
    800015c0:	6442                	ld	s0,16(sp)
    800015c2:	64a2                	ld	s1,8(sp)
    800015c4:	6105                	addi	sp,sp,32
    800015c6:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015c8:	6785                	lui	a5,0x1
    800015ca:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800015cc:	95be                	add	a1,a1,a5
    800015ce:	4685                	li	a3,1
    800015d0:	00c5d613          	srli	a2,a1,0xc
    800015d4:	4581                	li	a1,0
    800015d6:	00000097          	auipc	ra,0x0
    800015da:	d06080e7          	jalr	-762(ra) # 800012dc <uvmunmap>
    800015de:	bfd9                	j	800015b4 <uvmfree+0xe>

00000000800015e0 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015e0:	c679                	beqz	a2,800016ae <uvmcopy+0xce>
{
    800015e2:	715d                	addi	sp,sp,-80
    800015e4:	e486                	sd	ra,72(sp)
    800015e6:	e0a2                	sd	s0,64(sp)
    800015e8:	fc26                	sd	s1,56(sp)
    800015ea:	f84a                	sd	s2,48(sp)
    800015ec:	f44e                	sd	s3,40(sp)
    800015ee:	f052                	sd	s4,32(sp)
    800015f0:	ec56                	sd	s5,24(sp)
    800015f2:	e85a                	sd	s6,16(sp)
    800015f4:	e45e                	sd	s7,8(sp)
    800015f6:	0880                	addi	s0,sp,80
    800015f8:	8b2a                	mv	s6,a0
    800015fa:	8aae                	mv	s5,a1
    800015fc:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015fe:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001600:	4601                	li	a2,0
    80001602:	85ce                	mv	a1,s3
    80001604:	855a                	mv	a0,s6
    80001606:	00000097          	auipc	ra,0x0
    8000160a:	a28080e7          	jalr	-1496(ra) # 8000102e <walk>
    8000160e:	c531                	beqz	a0,8000165a <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001610:	6118                	ld	a4,0(a0)
    80001612:	00177793          	andi	a5,a4,1
    80001616:	cbb1                	beqz	a5,8000166a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001618:	00a75593          	srli	a1,a4,0xa
    8000161c:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001620:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001624:	fffff097          	auipc	ra,0xfffff
    80001628:	534080e7          	jalr	1332(ra) # 80000b58 <kalloc>
    8000162c:	892a                	mv	s2,a0
    8000162e:	c939                	beqz	a0,80001684 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001630:	6605                	lui	a2,0x1
    80001632:	85de                	mv	a1,s7
    80001634:	fffff097          	auipc	ra,0xfffff
    80001638:	76c080e7          	jalr	1900(ra) # 80000da0 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000163c:	8726                	mv	a4,s1
    8000163e:	86ca                	mv	a3,s2
    80001640:	6605                	lui	a2,0x1
    80001642:	85ce                	mv	a1,s3
    80001644:	8556                	mv	a0,s5
    80001646:	00000097          	auipc	ra,0x0
    8000164a:	ad0080e7          	jalr	-1328(ra) # 80001116 <mappages>
    8000164e:	e515                	bnez	a0,8000167a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001650:	6785                	lui	a5,0x1
    80001652:	99be                	add	s3,s3,a5
    80001654:	fb49e6e3          	bltu	s3,s4,80001600 <uvmcopy+0x20>
    80001658:	a081                	j	80001698 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000165a:	00007517          	auipc	a0,0x7
    8000165e:	b2e50513          	addi	a0,a0,-1234 # 80008188 <digits+0x148>
    80001662:	fffff097          	auipc	ra,0xfffff
    80001666:	ede080e7          	jalr	-290(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    8000166a:	00007517          	auipc	a0,0x7
    8000166e:	b3e50513          	addi	a0,a0,-1218 # 800081a8 <digits+0x168>
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	ece080e7          	jalr	-306(ra) # 80000540 <panic>
      kfree(mem);
    8000167a:	854a                	mv	a0,s2
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	3de080e7          	jalr	990(ra) # 80000a5a <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001684:	4685                	li	a3,1
    80001686:	00c9d613          	srli	a2,s3,0xc
    8000168a:	4581                	li	a1,0
    8000168c:	8556                	mv	a0,s5
    8000168e:	00000097          	auipc	ra,0x0
    80001692:	c4e080e7          	jalr	-946(ra) # 800012dc <uvmunmap>
  return -1;
    80001696:	557d                	li	a0,-1
}
    80001698:	60a6                	ld	ra,72(sp)
    8000169a:	6406                	ld	s0,64(sp)
    8000169c:	74e2                	ld	s1,56(sp)
    8000169e:	7942                	ld	s2,48(sp)
    800016a0:	79a2                	ld	s3,40(sp)
    800016a2:	7a02                	ld	s4,32(sp)
    800016a4:	6ae2                	ld	s5,24(sp)
    800016a6:	6b42                	ld	s6,16(sp)
    800016a8:	6ba2                	ld	s7,8(sp)
    800016aa:	6161                	addi	sp,sp,80
    800016ac:	8082                	ret
  return 0;
    800016ae:	4501                	li	a0,0
}
    800016b0:	8082                	ret

00000000800016b2 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016b2:	1141                	addi	sp,sp,-16
    800016b4:	e406                	sd	ra,8(sp)
    800016b6:	e022                	sd	s0,0(sp)
    800016b8:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016ba:	4601                	li	a2,0
    800016bc:	00000097          	auipc	ra,0x0
    800016c0:	972080e7          	jalr	-1678(ra) # 8000102e <walk>
  if(pte == 0)
    800016c4:	c901                	beqz	a0,800016d4 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016c6:	611c                	ld	a5,0(a0)
    800016c8:	9bbd                	andi	a5,a5,-17
    800016ca:	e11c                	sd	a5,0(a0)
}
    800016cc:	60a2                	ld	ra,8(sp)
    800016ce:	6402                	ld	s0,0(sp)
    800016d0:	0141                	addi	sp,sp,16
    800016d2:	8082                	ret
    panic("uvmclear");
    800016d4:	00007517          	auipc	a0,0x7
    800016d8:	af450513          	addi	a0,a0,-1292 # 800081c8 <digits+0x188>
    800016dc:	fffff097          	auipc	ra,0xfffff
    800016e0:	e64080e7          	jalr	-412(ra) # 80000540 <panic>

00000000800016e4 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e4:	c6bd                	beqz	a3,80001752 <copyout+0x6e>
{
    800016e6:	715d                	addi	sp,sp,-80
    800016e8:	e486                	sd	ra,72(sp)
    800016ea:	e0a2                	sd	s0,64(sp)
    800016ec:	fc26                	sd	s1,56(sp)
    800016ee:	f84a                	sd	s2,48(sp)
    800016f0:	f44e                	sd	s3,40(sp)
    800016f2:	f052                	sd	s4,32(sp)
    800016f4:	ec56                	sd	s5,24(sp)
    800016f6:	e85a                	sd	s6,16(sp)
    800016f8:	e45e                	sd	s7,8(sp)
    800016fa:	e062                	sd	s8,0(sp)
    800016fc:	0880                	addi	s0,sp,80
    800016fe:	8b2a                	mv	s6,a0
    80001700:	8c2e                	mv	s8,a1
    80001702:	8a32                	mv	s4,a2
    80001704:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001706:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001708:	6a85                	lui	s5,0x1
    8000170a:	a015                	j	8000172e <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000170c:	9562                	add	a0,a0,s8
    8000170e:	0004861b          	sext.w	a2,s1
    80001712:	85d2                	mv	a1,s4
    80001714:	41250533          	sub	a0,a0,s2
    80001718:	fffff097          	auipc	ra,0xfffff
    8000171c:	688080e7          	jalr	1672(ra) # 80000da0 <memmove>

    len -= n;
    80001720:	409989b3          	sub	s3,s3,s1
    src += n;
    80001724:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001726:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000172a:	02098263          	beqz	s3,8000174e <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000172e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001732:	85ca                	mv	a1,s2
    80001734:	855a                	mv	a0,s6
    80001736:	00000097          	auipc	ra,0x0
    8000173a:	99e080e7          	jalr	-1634(ra) # 800010d4 <walkaddr>
    if(pa0 == 0)
    8000173e:	cd01                	beqz	a0,80001756 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001740:	418904b3          	sub	s1,s2,s8
    80001744:	94d6                	add	s1,s1,s5
    80001746:	fc99f3e3          	bgeu	s3,s1,8000170c <copyout+0x28>
    8000174a:	84ce                	mv	s1,s3
    8000174c:	b7c1                	j	8000170c <copyout+0x28>
  }
  return 0;
    8000174e:	4501                	li	a0,0
    80001750:	a021                	j	80001758 <copyout+0x74>
    80001752:	4501                	li	a0,0
}
    80001754:	8082                	ret
      return -1;
    80001756:	557d                	li	a0,-1
}
    80001758:	60a6                	ld	ra,72(sp)
    8000175a:	6406                	ld	s0,64(sp)
    8000175c:	74e2                	ld	s1,56(sp)
    8000175e:	7942                	ld	s2,48(sp)
    80001760:	79a2                	ld	s3,40(sp)
    80001762:	7a02                	ld	s4,32(sp)
    80001764:	6ae2                	ld	s5,24(sp)
    80001766:	6b42                	ld	s6,16(sp)
    80001768:	6ba2                	ld	s7,8(sp)
    8000176a:	6c02                	ld	s8,0(sp)
    8000176c:	6161                	addi	sp,sp,80
    8000176e:	8082                	ret

0000000080001770 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001770:	caa5                	beqz	a3,800017e0 <copyin+0x70>
{
    80001772:	715d                	addi	sp,sp,-80
    80001774:	e486                	sd	ra,72(sp)
    80001776:	e0a2                	sd	s0,64(sp)
    80001778:	fc26                	sd	s1,56(sp)
    8000177a:	f84a                	sd	s2,48(sp)
    8000177c:	f44e                	sd	s3,40(sp)
    8000177e:	f052                	sd	s4,32(sp)
    80001780:	ec56                	sd	s5,24(sp)
    80001782:	e85a                	sd	s6,16(sp)
    80001784:	e45e                	sd	s7,8(sp)
    80001786:	e062                	sd	s8,0(sp)
    80001788:	0880                	addi	s0,sp,80
    8000178a:	8b2a                	mv	s6,a0
    8000178c:	8a2e                	mv	s4,a1
    8000178e:	8c32                	mv	s8,a2
    80001790:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001792:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001794:	6a85                	lui	s5,0x1
    80001796:	a01d                	j	800017bc <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001798:	018505b3          	add	a1,a0,s8
    8000179c:	0004861b          	sext.w	a2,s1
    800017a0:	412585b3          	sub	a1,a1,s2
    800017a4:	8552                	mv	a0,s4
    800017a6:	fffff097          	auipc	ra,0xfffff
    800017aa:	5fa080e7          	jalr	1530(ra) # 80000da0 <memmove>

    len -= n;
    800017ae:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017b2:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017b8:	02098263          	beqz	s3,800017dc <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800017bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017c0:	85ca                	mv	a1,s2
    800017c2:	855a                	mv	a0,s6
    800017c4:	00000097          	auipc	ra,0x0
    800017c8:	910080e7          	jalr	-1776(ra) # 800010d4 <walkaddr>
    if(pa0 == 0)
    800017cc:	cd01                	beqz	a0,800017e4 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800017ce:	418904b3          	sub	s1,s2,s8
    800017d2:	94d6                	add	s1,s1,s5
    800017d4:	fc99f2e3          	bgeu	s3,s1,80001798 <copyin+0x28>
    800017d8:	84ce                	mv	s1,s3
    800017da:	bf7d                	j	80001798 <copyin+0x28>
  }
  return 0;
    800017dc:	4501                	li	a0,0
    800017de:	a021                	j	800017e6 <copyin+0x76>
    800017e0:	4501                	li	a0,0
}
    800017e2:	8082                	ret
      return -1;
    800017e4:	557d                	li	a0,-1
}
    800017e6:	60a6                	ld	ra,72(sp)
    800017e8:	6406                	ld	s0,64(sp)
    800017ea:	74e2                	ld	s1,56(sp)
    800017ec:	7942                	ld	s2,48(sp)
    800017ee:	79a2                	ld	s3,40(sp)
    800017f0:	7a02                	ld	s4,32(sp)
    800017f2:	6ae2                	ld	s5,24(sp)
    800017f4:	6b42                	ld	s6,16(sp)
    800017f6:	6ba2                	ld	s7,8(sp)
    800017f8:	6c02                	ld	s8,0(sp)
    800017fa:	6161                	addi	sp,sp,80
    800017fc:	8082                	ret

00000000800017fe <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017fe:	c2dd                	beqz	a3,800018a4 <copyinstr+0xa6>
{
    80001800:	715d                	addi	sp,sp,-80
    80001802:	e486                	sd	ra,72(sp)
    80001804:	e0a2                	sd	s0,64(sp)
    80001806:	fc26                	sd	s1,56(sp)
    80001808:	f84a                	sd	s2,48(sp)
    8000180a:	f44e                	sd	s3,40(sp)
    8000180c:	f052                	sd	s4,32(sp)
    8000180e:	ec56                	sd	s5,24(sp)
    80001810:	e85a                	sd	s6,16(sp)
    80001812:	e45e                	sd	s7,8(sp)
    80001814:	0880                	addi	s0,sp,80
    80001816:	8a2a                	mv	s4,a0
    80001818:	8b2e                	mv	s6,a1
    8000181a:	8bb2                	mv	s7,a2
    8000181c:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000181e:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001820:	6985                	lui	s3,0x1
    80001822:	a02d                	j	8000184c <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001824:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001828:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000182a:	37fd                	addiw	a5,a5,-1
    8000182c:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001830:	60a6                	ld	ra,72(sp)
    80001832:	6406                	ld	s0,64(sp)
    80001834:	74e2                	ld	s1,56(sp)
    80001836:	7942                	ld	s2,48(sp)
    80001838:	79a2                	ld	s3,40(sp)
    8000183a:	7a02                	ld	s4,32(sp)
    8000183c:	6ae2                	ld	s5,24(sp)
    8000183e:	6b42                	ld	s6,16(sp)
    80001840:	6ba2                	ld	s7,8(sp)
    80001842:	6161                	addi	sp,sp,80
    80001844:	8082                	ret
    srcva = va0 + PGSIZE;
    80001846:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000184a:	c8a9                	beqz	s1,8000189c <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    8000184c:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001850:	85ca                	mv	a1,s2
    80001852:	8552                	mv	a0,s4
    80001854:	00000097          	auipc	ra,0x0
    80001858:	880080e7          	jalr	-1920(ra) # 800010d4 <walkaddr>
    if(pa0 == 0)
    8000185c:	c131                	beqz	a0,800018a0 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    8000185e:	417906b3          	sub	a3,s2,s7
    80001862:	96ce                	add	a3,a3,s3
    80001864:	00d4f363          	bgeu	s1,a3,8000186a <copyinstr+0x6c>
    80001868:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000186a:	955e                	add	a0,a0,s7
    8000186c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001870:	daf9                	beqz	a3,80001846 <copyinstr+0x48>
    80001872:	87da                	mv	a5,s6
    80001874:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001876:	41650633          	sub	a2,a0,s6
    while(n > 0){
    8000187a:	96da                	add	a3,a3,s6
    8000187c:	85be                	mv	a1,a5
      if(*p == '\0'){
    8000187e:	00f60733          	add	a4,a2,a5
    80001882:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd5430>
    80001886:	df59                	beqz	a4,80001824 <copyinstr+0x26>
        *dst = *p;
    80001888:	00e78023          	sb	a4,0(a5)
      dst++;
    8000188c:	0785                	addi	a5,a5,1
    while(n > 0){
    8000188e:	fed797e3          	bne	a5,a3,8000187c <copyinstr+0x7e>
    80001892:	14fd                	addi	s1,s1,-1
    80001894:	94c2                	add	s1,s1,a6
      --max;
    80001896:	8c8d                	sub	s1,s1,a1
      dst++;
    80001898:	8b3e                	mv	s6,a5
    8000189a:	b775                	j	80001846 <copyinstr+0x48>
    8000189c:	4781                	li	a5,0
    8000189e:	b771                	j	8000182a <copyinstr+0x2c>
      return -1;
    800018a0:	557d                	li	a0,-1
    800018a2:	b779                	j	80001830 <copyinstr+0x32>
  int got_null = 0;
    800018a4:	4781                	li	a5,0
  if(got_null){
    800018a6:	37fd                	addiw	a5,a5,-1
    800018a8:	0007851b          	sext.w	a0,a5
}
    800018ac:	8082                	ret

00000000800018ae <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    800018ae:	7139                	addi	sp,sp,-64
    800018b0:	fc06                	sd	ra,56(sp)
    800018b2:	f822                	sd	s0,48(sp)
    800018b4:	f426                	sd	s1,40(sp)
    800018b6:	f04a                	sd	s2,32(sp)
    800018b8:	ec4e                	sd	s3,24(sp)
    800018ba:	e852                	sd	s4,16(sp)
    800018bc:	e456                	sd	s5,8(sp)
    800018be:	e05a                	sd	s6,0(sp)
    800018c0:	0080                	addi	s0,sp,64
    800018c2:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800018c4:	00017497          	auipc	s1,0x17
    800018c8:	15c48493          	addi	s1,s1,348 # 80018a20 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800018cc:	8b26                	mv	s6,s1
    800018ce:	00006a97          	auipc	s5,0x6
    800018d2:	732a8a93          	addi	s5,s5,1842 # 80008000 <etext>
    800018d6:	04000937          	lui	s2,0x4000
    800018da:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800018dc:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018de:	0001da17          	auipc	s4,0x1d
    800018e2:	d42a0a13          	addi	s4,s4,-702 # 8001e620 <tickslock>
    char *pa = kalloc();
    800018e6:	fffff097          	auipc	ra,0xfffff
    800018ea:	272080e7          	jalr	626(ra) # 80000b58 <kalloc>
    800018ee:	862a                	mv	a2,a0
    if(pa == 0)
    800018f0:	c131                	beqz	a0,80001934 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018f2:	416485b3          	sub	a1,s1,s6
    800018f6:	8591                	srai	a1,a1,0x4
    800018f8:	000ab783          	ld	a5,0(s5)
    800018fc:	02f585b3          	mul	a1,a1,a5
    80001900:	2585                	addiw	a1,a1,1
    80001902:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001906:	4719                	li	a4,6
    80001908:	6685                	lui	a3,0x1
    8000190a:	40b905b3          	sub	a1,s2,a1
    8000190e:	854e                	mv	a0,s3
    80001910:	00000097          	auipc	ra,0x0
    80001914:	8a6080e7          	jalr	-1882(ra) # 800011b6 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001918:	17048493          	addi	s1,s1,368
    8000191c:	fd4495e3          	bne	s1,s4,800018e6 <proc_mapstacks+0x38>
  }
}
    80001920:	70e2                	ld	ra,56(sp)
    80001922:	7442                	ld	s0,48(sp)
    80001924:	74a2                	ld	s1,40(sp)
    80001926:	7902                	ld	s2,32(sp)
    80001928:	69e2                	ld	s3,24(sp)
    8000192a:	6a42                	ld	s4,16(sp)
    8000192c:	6aa2                	ld	s5,8(sp)
    8000192e:	6b02                	ld	s6,0(sp)
    80001930:	6121                	addi	sp,sp,64
    80001932:	8082                	ret
      panic("kalloc");
    80001934:	00007517          	auipc	a0,0x7
    80001938:	8a450513          	addi	a0,a0,-1884 # 800081d8 <digits+0x198>
    8000193c:	fffff097          	auipc	ra,0xfffff
    80001940:	c04080e7          	jalr	-1020(ra) # 80000540 <panic>

0000000080001944 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001944:	7139                	addi	sp,sp,-64
    80001946:	fc06                	sd	ra,56(sp)
    80001948:	f822                	sd	s0,48(sp)
    8000194a:	f426                	sd	s1,40(sp)
    8000194c:	f04a                	sd	s2,32(sp)
    8000194e:	ec4e                	sd	s3,24(sp)
    80001950:	e852                	sd	s4,16(sp)
    80001952:	e456                	sd	s5,8(sp)
    80001954:	e05a                	sd	s6,0(sp)
    80001956:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001958:	00007597          	auipc	a1,0x7
    8000195c:	88858593          	addi	a1,a1,-1912 # 800081e0 <digits+0x1a0>
    80001960:	00017517          	auipc	a0,0x17
    80001964:	c9050513          	addi	a0,a0,-880 # 800185f0 <pid_lock>
    80001968:	fffff097          	auipc	ra,0xfffff
    8000196c:	250080e7          	jalr	592(ra) # 80000bb8 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001970:	00007597          	auipc	a1,0x7
    80001974:	87858593          	addi	a1,a1,-1928 # 800081e8 <digits+0x1a8>
    80001978:	00017517          	auipc	a0,0x17
    8000197c:	c9050513          	addi	a0,a0,-880 # 80018608 <wait_lock>
    80001980:	fffff097          	auipc	ra,0xfffff
    80001984:	238080e7          	jalr	568(ra) # 80000bb8 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001988:	00017497          	auipc	s1,0x17
    8000198c:	09848493          	addi	s1,s1,152 # 80018a20 <proc>
      initlock(&p->lock, "proc");
    80001990:	00007b17          	auipc	s6,0x7
    80001994:	868b0b13          	addi	s6,s6,-1944 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001998:	8aa6                	mv	s5,s1
    8000199a:	00006a17          	auipc	s4,0x6
    8000199e:	666a0a13          	addi	s4,s4,1638 # 80008000 <etext>
    800019a2:	04000937          	lui	s2,0x4000
    800019a6:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800019a8:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019aa:	0001d997          	auipc	s3,0x1d
    800019ae:	c7698993          	addi	s3,s3,-906 # 8001e620 <tickslock>
      initlock(&p->lock, "proc");
    800019b2:	85da                	mv	a1,s6
    800019b4:	8526                	mv	a0,s1
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	202080e7          	jalr	514(ra) # 80000bb8 <initlock>
      p->state = UNUSED;
    800019be:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    800019c2:	415487b3          	sub	a5,s1,s5
    800019c6:	8791                	srai	a5,a5,0x4
    800019c8:	000a3703          	ld	a4,0(s4)
    800019cc:	02e787b3          	mul	a5,a5,a4
    800019d0:	2785                	addiw	a5,a5,1
    800019d2:	00d7979b          	slliw	a5,a5,0xd
    800019d6:	40f907b3          	sub	a5,s2,a5
    800019da:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019dc:	17048493          	addi	s1,s1,368
    800019e0:	fd3499e3          	bne	s1,s3,800019b2 <procinit+0x6e>
  }
}
    800019e4:	70e2                	ld	ra,56(sp)
    800019e6:	7442                	ld	s0,48(sp)
    800019e8:	74a2                	ld	s1,40(sp)
    800019ea:	7902                	ld	s2,32(sp)
    800019ec:	69e2                	ld	s3,24(sp)
    800019ee:	6a42                	ld	s4,16(sp)
    800019f0:	6aa2                	ld	s5,8(sp)
    800019f2:	6b02                	ld	s6,0(sp)
    800019f4:	6121                	addi	sp,sp,64
    800019f6:	8082                	ret

00000000800019f8 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019f8:	1141                	addi	sp,sp,-16
    800019fa:	e422                	sd	s0,8(sp)
    800019fc:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019fe:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a00:	2501                	sext.w	a0,a0
    80001a02:	6422                	ld	s0,8(sp)
    80001a04:	0141                	addi	sp,sp,16
    80001a06:	8082                	ret

0000000080001a08 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001a08:	1141                	addi	sp,sp,-16
    80001a0a:	e422                	sd	s0,8(sp)
    80001a0c:	0800                	addi	s0,sp,16
    80001a0e:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a10:	2781                	sext.w	a5,a5
    80001a12:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a14:	00017517          	auipc	a0,0x17
    80001a18:	c0c50513          	addi	a0,a0,-1012 # 80018620 <cpus>
    80001a1c:	953e                	add	a0,a0,a5
    80001a1e:	6422                	ld	s0,8(sp)
    80001a20:	0141                	addi	sp,sp,16
    80001a22:	8082                	ret

0000000080001a24 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001a24:	1101                	addi	sp,sp,-32
    80001a26:	ec06                	sd	ra,24(sp)
    80001a28:	e822                	sd	s0,16(sp)
    80001a2a:	e426                	sd	s1,8(sp)
    80001a2c:	1000                	addi	s0,sp,32
  push_off();
    80001a2e:	fffff097          	auipc	ra,0xfffff
    80001a32:	1ce080e7          	jalr	462(ra) # 80000bfc <push_off>
    80001a36:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a38:	2781                	sext.w	a5,a5
    80001a3a:	079e                	slli	a5,a5,0x7
    80001a3c:	00017717          	auipc	a4,0x17
    80001a40:	bb470713          	addi	a4,a4,-1100 # 800185f0 <pid_lock>
    80001a44:	97ba                	add	a5,a5,a4
    80001a46:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a48:	fffff097          	auipc	ra,0xfffff
    80001a4c:	254080e7          	jalr	596(ra) # 80000c9c <pop_off>
  return p;
}
    80001a50:	8526                	mv	a0,s1
    80001a52:	60e2                	ld	ra,24(sp)
    80001a54:	6442                	ld	s0,16(sp)
    80001a56:	64a2                	ld	s1,8(sp)
    80001a58:	6105                	addi	sp,sp,32
    80001a5a:	8082                	ret

0000000080001a5c <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a5c:	1141                	addi	sp,sp,-16
    80001a5e:	e406                	sd	ra,8(sp)
    80001a60:	e022                	sd	s0,0(sp)
    80001a62:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a64:	00000097          	auipc	ra,0x0
    80001a68:	fc0080e7          	jalr	-64(ra) # 80001a24 <myproc>
    80001a6c:	fffff097          	auipc	ra,0xfffff
    80001a70:	290080e7          	jalr	656(ra) # 80000cfc <release>

  if (first) {
    80001a74:	0000f797          	auipc	a5,0xf
    80001a78:	87c7a783          	lw	a5,-1924(a5) # 800102f0 <first.1>
    80001a7c:	eb89                	bnez	a5,80001a8e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a7e:	00001097          	auipc	ra,0x1
    80001a82:	c96080e7          	jalr	-874(ra) # 80002714 <usertrapret>
}
    80001a86:	60a2                	ld	ra,8(sp)
    80001a88:	6402                	ld	s0,0(sp)
    80001a8a:	0141                	addi	sp,sp,16
    80001a8c:	8082                	ret
    first = 0;
    80001a8e:	0000f797          	auipc	a5,0xf
    80001a92:	8607a123          	sw	zero,-1950(a5) # 800102f0 <first.1>
    fsinit(ROOTDEV);
    80001a96:	4505                	li	a0,1
    80001a98:	00002097          	auipc	ra,0x2
    80001a9c:	a02080e7          	jalr	-1534(ra) # 8000349a <fsinit>
    80001aa0:	bff9                	j	80001a7e <forkret+0x22>

0000000080001aa2 <allocpid>:
{
    80001aa2:	1101                	addi	sp,sp,-32
    80001aa4:	ec06                	sd	ra,24(sp)
    80001aa6:	e822                	sd	s0,16(sp)
    80001aa8:	e426                	sd	s1,8(sp)
    80001aaa:	e04a                	sd	s2,0(sp)
    80001aac:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001aae:	00017917          	auipc	s2,0x17
    80001ab2:	b4290913          	addi	s2,s2,-1214 # 800185f0 <pid_lock>
    80001ab6:	854a                	mv	a0,s2
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	190080e7          	jalr	400(ra) # 80000c48 <acquire>
  pid = nextpid;
    80001ac0:	0000f797          	auipc	a5,0xf
    80001ac4:	83478793          	addi	a5,a5,-1996 # 800102f4 <nextpid>
    80001ac8:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001aca:	0014871b          	addiw	a4,s1,1
    80001ace:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ad0:	854a                	mv	a0,s2
    80001ad2:	fffff097          	auipc	ra,0xfffff
    80001ad6:	22a080e7          	jalr	554(ra) # 80000cfc <release>
}
    80001ada:	8526                	mv	a0,s1
    80001adc:	60e2                	ld	ra,24(sp)
    80001ade:	6442                	ld	s0,16(sp)
    80001ae0:	64a2                	ld	s1,8(sp)
    80001ae2:	6902                	ld	s2,0(sp)
    80001ae4:	6105                	addi	sp,sp,32
    80001ae6:	8082                	ret

0000000080001ae8 <proc_pagetable>:
{
    80001ae8:	1101                	addi	sp,sp,-32
    80001aea:	ec06                	sd	ra,24(sp)
    80001aec:	e822                	sd	s0,16(sp)
    80001aee:	e426                	sd	s1,8(sp)
    80001af0:	e04a                	sd	s2,0(sp)
    80001af2:	1000                	addi	s0,sp,32
    80001af4:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001af6:	00000097          	auipc	ra,0x0
    80001afa:	8aa080e7          	jalr	-1878(ra) # 800013a0 <uvmcreate>
    80001afe:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b00:	c121                	beqz	a0,80001b40 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b02:	4729                	li	a4,10
    80001b04:	00005697          	auipc	a3,0x5
    80001b08:	4fc68693          	addi	a3,a3,1276 # 80007000 <_trampoline>
    80001b0c:	6605                	lui	a2,0x1
    80001b0e:	040005b7          	lui	a1,0x4000
    80001b12:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b14:	05b2                	slli	a1,a1,0xc
    80001b16:	fffff097          	auipc	ra,0xfffff
    80001b1a:	600080e7          	jalr	1536(ra) # 80001116 <mappages>
    80001b1e:	02054863          	bltz	a0,80001b4e <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b22:	4719                	li	a4,6
    80001b24:	05893683          	ld	a3,88(s2)
    80001b28:	6605                	lui	a2,0x1
    80001b2a:	020005b7          	lui	a1,0x2000
    80001b2e:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b30:	05b6                	slli	a1,a1,0xd
    80001b32:	8526                	mv	a0,s1
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	5e2080e7          	jalr	1506(ra) # 80001116 <mappages>
    80001b3c:	02054163          	bltz	a0,80001b5e <proc_pagetable+0x76>
}
    80001b40:	8526                	mv	a0,s1
    80001b42:	60e2                	ld	ra,24(sp)
    80001b44:	6442                	ld	s0,16(sp)
    80001b46:	64a2                	ld	s1,8(sp)
    80001b48:	6902                	ld	s2,0(sp)
    80001b4a:	6105                	addi	sp,sp,32
    80001b4c:	8082                	ret
    uvmfree(pagetable, 0);
    80001b4e:	4581                	li	a1,0
    80001b50:	8526                	mv	a0,s1
    80001b52:	00000097          	auipc	ra,0x0
    80001b56:	a54080e7          	jalr	-1452(ra) # 800015a6 <uvmfree>
    return 0;
    80001b5a:	4481                	li	s1,0
    80001b5c:	b7d5                	j	80001b40 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b5e:	4681                	li	a3,0
    80001b60:	4605                	li	a2,1
    80001b62:	040005b7          	lui	a1,0x4000
    80001b66:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b68:	05b2                	slli	a1,a1,0xc
    80001b6a:	8526                	mv	a0,s1
    80001b6c:	fffff097          	auipc	ra,0xfffff
    80001b70:	770080e7          	jalr	1904(ra) # 800012dc <uvmunmap>
    uvmfree(pagetable, 0);
    80001b74:	4581                	li	a1,0
    80001b76:	8526                	mv	a0,s1
    80001b78:	00000097          	auipc	ra,0x0
    80001b7c:	a2e080e7          	jalr	-1490(ra) # 800015a6 <uvmfree>
    return 0;
    80001b80:	4481                	li	s1,0
    80001b82:	bf7d                	j	80001b40 <proc_pagetable+0x58>

0000000080001b84 <proc_freepagetable>:
{
    80001b84:	1101                	addi	sp,sp,-32
    80001b86:	ec06                	sd	ra,24(sp)
    80001b88:	e822                	sd	s0,16(sp)
    80001b8a:	e426                	sd	s1,8(sp)
    80001b8c:	e04a                	sd	s2,0(sp)
    80001b8e:	1000                	addi	s0,sp,32
    80001b90:	84aa                	mv	s1,a0
    80001b92:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b94:	4681                	li	a3,0
    80001b96:	4605                	li	a2,1
    80001b98:	040005b7          	lui	a1,0x4000
    80001b9c:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b9e:	05b2                	slli	a1,a1,0xc
    80001ba0:	fffff097          	auipc	ra,0xfffff
    80001ba4:	73c080e7          	jalr	1852(ra) # 800012dc <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001ba8:	4681                	li	a3,0
    80001baa:	4605                	li	a2,1
    80001bac:	020005b7          	lui	a1,0x2000
    80001bb0:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001bb2:	05b6                	slli	a1,a1,0xd
    80001bb4:	8526                	mv	a0,s1
    80001bb6:	fffff097          	auipc	ra,0xfffff
    80001bba:	726080e7          	jalr	1830(ra) # 800012dc <uvmunmap>
  uvmfree(pagetable, sz);
    80001bbe:	85ca                	mv	a1,s2
    80001bc0:	8526                	mv	a0,s1
    80001bc2:	00000097          	auipc	ra,0x0
    80001bc6:	9e4080e7          	jalr	-1564(ra) # 800015a6 <uvmfree>
}
    80001bca:	60e2                	ld	ra,24(sp)
    80001bcc:	6442                	ld	s0,16(sp)
    80001bce:	64a2                	ld	s1,8(sp)
    80001bd0:	6902                	ld	s2,0(sp)
    80001bd2:	6105                	addi	sp,sp,32
    80001bd4:	8082                	ret

0000000080001bd6 <freeproc>:
{
    80001bd6:	1101                	addi	sp,sp,-32
    80001bd8:	ec06                	sd	ra,24(sp)
    80001bda:	e822                	sd	s0,16(sp)
    80001bdc:	e426                	sd	s1,8(sp)
    80001bde:	1000                	addi	s0,sp,32
    80001be0:	84aa                	mv	s1,a0
  if (strncmp(p->name, "vm-", 3) == 0) {
    80001be2:	460d                	li	a2,3
    80001be4:	00006597          	auipc	a1,0x6
    80001be8:	61c58593          	addi	a1,a1,1564 # 80008200 <digits+0x1c0>
    80001bec:	15850513          	addi	a0,a0,344
    80001bf0:	fffff097          	auipc	ra,0xfffff
    80001bf4:	224080e7          	jalr	548(ra) # 80000e14 <strncmp>
    80001bf8:	c929                	beqz	a0,80001c4a <freeproc+0x74>
  if(p->trapframe)
    80001bfa:	6ca8                	ld	a0,88(s1)
    80001bfc:	c509                	beqz	a0,80001c06 <freeproc+0x30>
    kfree((void*)p->trapframe);
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	e5c080e7          	jalr	-420(ra) # 80000a5a <kfree>
  p->trapframe = 0;
    80001c06:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c0a:	68a8                	ld	a0,80(s1)
    80001c0c:	c511                	beqz	a0,80001c18 <freeproc+0x42>
    proc_freepagetable(p->pagetable, p->sz);
    80001c0e:	64ac                	ld	a1,72(s1)
    80001c10:	00000097          	auipc	ra,0x0
    80001c14:	f74080e7          	jalr	-140(ra) # 80001b84 <proc_freepagetable>
  p->pagetable = 0;
    80001c18:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c1c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c20:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c24:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c28:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c2c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c30:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c34:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c38:	0004ac23          	sw	zero,24(s1)
  p->proc_te_vm = 0;
    80001c3c:	1604a423          	sw	zero,360(s1)
}
    80001c40:	60e2                	ld	ra,24(sp)
    80001c42:	6442                	ld	s0,16(sp)
    80001c44:	64a2                	ld	s1,8(sp)
    80001c46:	6105                	addi	sp,sp,32
    80001c48:	8082                	ret
    uvmunmap(p->pagetable, memaddr_start, memaddr_count, 0);
    80001c4a:	4681                	li	a3,0
    80001c4c:	40000613          	li	a2,1024
    80001c50:	4585                	li	a1,1
    80001c52:	05fe                	slli	a1,a1,0x1f
    80001c54:	68a8                	ld	a0,80(s1)
    80001c56:	fffff097          	auipc	ra,0xfffff
    80001c5a:	686080e7          	jalr	1670(ra) # 800012dc <uvmunmap>
    trap_and_emulate_init();
    80001c5e:	00005097          	auipc	ra,0x5
    80001c62:	a26080e7          	jalr	-1498(ra) # 80006684 <trap_and_emulate_init>
    80001c66:	bf51                	j	80001bfa <freeproc+0x24>

0000000080001c68 <allocproc>:
{
    80001c68:	1101                	addi	sp,sp,-32
    80001c6a:	ec06                	sd	ra,24(sp)
    80001c6c:	e822                	sd	s0,16(sp)
    80001c6e:	e426                	sd	s1,8(sp)
    80001c70:	e04a                	sd	s2,0(sp)
    80001c72:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c74:	00017497          	auipc	s1,0x17
    80001c78:	dac48493          	addi	s1,s1,-596 # 80018a20 <proc>
    80001c7c:	0001d917          	auipc	s2,0x1d
    80001c80:	9a490913          	addi	s2,s2,-1628 # 8001e620 <tickslock>
    acquire(&p->lock);
    80001c84:	8526                	mv	a0,s1
    80001c86:	fffff097          	auipc	ra,0xfffff
    80001c8a:	fc2080e7          	jalr	-62(ra) # 80000c48 <acquire>
    if(p->state == UNUSED) {
    80001c8e:	4c9c                	lw	a5,24(s1)
    80001c90:	cf81                	beqz	a5,80001ca8 <allocproc+0x40>
      release(&p->lock);
    80001c92:	8526                	mv	a0,s1
    80001c94:	fffff097          	auipc	ra,0xfffff
    80001c98:	068080e7          	jalr	104(ra) # 80000cfc <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c9c:	17048493          	addi	s1,s1,368
    80001ca0:	ff2492e3          	bne	s1,s2,80001c84 <allocproc+0x1c>
  return 0;
    80001ca4:	4481                	li	s1,0
    80001ca6:	a889                	j	80001cf8 <allocproc+0x90>
  p->pid = allocpid();
    80001ca8:	00000097          	auipc	ra,0x0
    80001cac:	dfa080e7          	jalr	-518(ra) # 80001aa2 <allocpid>
    80001cb0:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001cb2:	4785                	li	a5,1
    80001cb4:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001cb6:	fffff097          	auipc	ra,0xfffff
    80001cba:	ea2080e7          	jalr	-350(ra) # 80000b58 <kalloc>
    80001cbe:	892a                	mv	s2,a0
    80001cc0:	eca8                	sd	a0,88(s1)
    80001cc2:	c131                	beqz	a0,80001d06 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001cc4:	8526                	mv	a0,s1
    80001cc6:	00000097          	auipc	ra,0x0
    80001cca:	e22080e7          	jalr	-478(ra) # 80001ae8 <proc_pagetable>
    80001cce:	892a                	mv	s2,a0
    80001cd0:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001cd2:	c531                	beqz	a0,80001d1e <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001cd4:	07000613          	li	a2,112
    80001cd8:	4581                	li	a1,0
    80001cda:	06048513          	addi	a0,s1,96
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	066080e7          	jalr	102(ra) # 80000d44 <memset>
  p->context.ra = (uint64)forkret;
    80001ce6:	00000797          	auipc	a5,0x0
    80001cea:	d7678793          	addi	a5,a5,-650 # 80001a5c <forkret>
    80001cee:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cf0:	60bc                	ld	a5,64(s1)
    80001cf2:	6705                	lui	a4,0x1
    80001cf4:	97ba                	add	a5,a5,a4
    80001cf6:	f4bc                	sd	a5,104(s1)
}
    80001cf8:	8526                	mv	a0,s1
    80001cfa:	60e2                	ld	ra,24(sp)
    80001cfc:	6442                	ld	s0,16(sp)
    80001cfe:	64a2                	ld	s1,8(sp)
    80001d00:	6902                	ld	s2,0(sp)
    80001d02:	6105                	addi	sp,sp,32
    80001d04:	8082                	ret
    freeproc(p);
    80001d06:	8526                	mv	a0,s1
    80001d08:	00000097          	auipc	ra,0x0
    80001d0c:	ece080e7          	jalr	-306(ra) # 80001bd6 <freeproc>
    release(&p->lock);
    80001d10:	8526                	mv	a0,s1
    80001d12:	fffff097          	auipc	ra,0xfffff
    80001d16:	fea080e7          	jalr	-22(ra) # 80000cfc <release>
    return 0;
    80001d1a:	84ca                	mv	s1,s2
    80001d1c:	bff1                	j	80001cf8 <allocproc+0x90>
    freeproc(p);
    80001d1e:	8526                	mv	a0,s1
    80001d20:	00000097          	auipc	ra,0x0
    80001d24:	eb6080e7          	jalr	-330(ra) # 80001bd6 <freeproc>
    release(&p->lock);
    80001d28:	8526                	mv	a0,s1
    80001d2a:	fffff097          	auipc	ra,0xfffff
    80001d2e:	fd2080e7          	jalr	-46(ra) # 80000cfc <release>
    return 0;
    80001d32:	84ca                	mv	s1,s2
    80001d34:	b7d1                	j	80001cf8 <allocproc+0x90>

0000000080001d36 <userinit>:
{
    80001d36:	1101                	addi	sp,sp,-32
    80001d38:	ec06                	sd	ra,24(sp)
    80001d3a:	e822                	sd	s0,16(sp)
    80001d3c:	e426                	sd	s1,8(sp)
    80001d3e:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d40:	00000097          	auipc	ra,0x0
    80001d44:	f28080e7          	jalr	-216(ra) # 80001c68 <allocproc>
    80001d48:	84aa                	mv	s1,a0
  initproc = p;
    80001d4a:	0000e797          	auipc	a5,0xe
    80001d4e:	60a7bf23          	sd	a0,1566(a5) # 80010368 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001d52:	03400613          	li	a2,52
    80001d56:	0000e597          	auipc	a1,0xe
    80001d5a:	5aa58593          	addi	a1,a1,1450 # 80010300 <initcode>
    80001d5e:	6928                	ld	a0,80(a0)
    80001d60:	fffff097          	auipc	ra,0xfffff
    80001d64:	66e080e7          	jalr	1646(ra) # 800013ce <uvmfirst>
  p->sz = PGSIZE;
    80001d68:	6785                	lui	a5,0x1
    80001d6a:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d6c:	6cb8                	ld	a4,88(s1)
    80001d6e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d72:	6cb8                	ld	a4,88(s1)
    80001d74:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d76:	4641                	li	a2,16
    80001d78:	00006597          	auipc	a1,0x6
    80001d7c:	49058593          	addi	a1,a1,1168 # 80008208 <digits+0x1c8>
    80001d80:	15848513          	addi	a0,s1,344
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	108080e7          	jalr	264(ra) # 80000e8c <safestrcpy>
  p->cwd = namei("/");
    80001d8c:	00006517          	auipc	a0,0x6
    80001d90:	48c50513          	addi	a0,a0,1164 # 80008218 <digits+0x1d8>
    80001d94:	00002097          	auipc	ra,0x2
    80001d98:	124080e7          	jalr	292(ra) # 80003eb8 <namei>
    80001d9c:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001da0:	478d                	li	a5,3
    80001da2:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001da4:	8526                	mv	a0,s1
    80001da6:	fffff097          	auipc	ra,0xfffff
    80001daa:	f56080e7          	jalr	-170(ra) # 80000cfc <release>
}
    80001dae:	60e2                	ld	ra,24(sp)
    80001db0:	6442                	ld	s0,16(sp)
    80001db2:	64a2                	ld	s1,8(sp)
    80001db4:	6105                	addi	sp,sp,32
    80001db6:	8082                	ret

0000000080001db8 <growproc>:
{
    80001db8:	1101                	addi	sp,sp,-32
    80001dba:	ec06                	sd	ra,24(sp)
    80001dbc:	e822                	sd	s0,16(sp)
    80001dbe:	e426                	sd	s1,8(sp)
    80001dc0:	e04a                	sd	s2,0(sp)
    80001dc2:	1000                	addi	s0,sp,32
    80001dc4:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001dc6:	00000097          	auipc	ra,0x0
    80001dca:	c5e080e7          	jalr	-930(ra) # 80001a24 <myproc>
    80001dce:	84aa                	mv	s1,a0
  sz = p->sz;
    80001dd0:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001dd2:	01204c63          	bgtz	s2,80001dea <growproc+0x32>
  } else if(n < 0){
    80001dd6:	02094663          	bltz	s2,80001e02 <growproc+0x4a>
  p->sz = sz;
    80001dda:	e4ac                	sd	a1,72(s1)
  return 0;
    80001ddc:	4501                	li	a0,0
}
    80001dde:	60e2                	ld	ra,24(sp)
    80001de0:	6442                	ld	s0,16(sp)
    80001de2:	64a2                	ld	s1,8(sp)
    80001de4:	6902                	ld	s2,0(sp)
    80001de6:	6105                	addi	sp,sp,32
    80001de8:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001dea:	4691                	li	a3,4
    80001dec:	00b90633          	add	a2,s2,a1
    80001df0:	6928                	ld	a0,80(a0)
    80001df2:	fffff097          	auipc	ra,0xfffff
    80001df6:	696080e7          	jalr	1686(ra) # 80001488 <uvmalloc>
    80001dfa:	85aa                	mv	a1,a0
    80001dfc:	fd79                	bnez	a0,80001dda <growproc+0x22>
      return -1;
    80001dfe:	557d                	li	a0,-1
    80001e00:	bff9                	j	80001dde <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e02:	00b90633          	add	a2,s2,a1
    80001e06:	6928                	ld	a0,80(a0)
    80001e08:	fffff097          	auipc	ra,0xfffff
    80001e0c:	638080e7          	jalr	1592(ra) # 80001440 <uvmdealloc>
    80001e10:	85aa                	mv	a1,a0
    80001e12:	b7e1                	j	80001dda <growproc+0x22>

0000000080001e14 <fork>:
{
    80001e14:	7139                	addi	sp,sp,-64
    80001e16:	fc06                	sd	ra,56(sp)
    80001e18:	f822                	sd	s0,48(sp)
    80001e1a:	f426                	sd	s1,40(sp)
    80001e1c:	f04a                	sd	s2,32(sp)
    80001e1e:	ec4e                	sd	s3,24(sp)
    80001e20:	e852                	sd	s4,16(sp)
    80001e22:	e456                	sd	s5,8(sp)
    80001e24:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e26:	00000097          	auipc	ra,0x0
    80001e2a:	bfe080e7          	jalr	-1026(ra) # 80001a24 <myproc>
    80001e2e:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001e30:	00000097          	auipc	ra,0x0
    80001e34:	e38080e7          	jalr	-456(ra) # 80001c68 <allocproc>
    80001e38:	10050c63          	beqz	a0,80001f50 <fork+0x13c>
    80001e3c:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e3e:	048ab603          	ld	a2,72(s5)
    80001e42:	692c                	ld	a1,80(a0)
    80001e44:	050ab503          	ld	a0,80(s5)
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	798080e7          	jalr	1944(ra) # 800015e0 <uvmcopy>
    80001e50:	04054863          	bltz	a0,80001ea0 <fork+0x8c>
  np->sz = p->sz;
    80001e54:	048ab783          	ld	a5,72(s5)
    80001e58:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e5c:	058ab683          	ld	a3,88(s5)
    80001e60:	87b6                	mv	a5,a3
    80001e62:	058a3703          	ld	a4,88(s4)
    80001e66:	12068693          	addi	a3,a3,288
    80001e6a:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e6e:	6788                	ld	a0,8(a5)
    80001e70:	6b8c                	ld	a1,16(a5)
    80001e72:	6f90                	ld	a2,24(a5)
    80001e74:	01073023          	sd	a6,0(a4)
    80001e78:	e708                	sd	a0,8(a4)
    80001e7a:	eb0c                	sd	a1,16(a4)
    80001e7c:	ef10                	sd	a2,24(a4)
    80001e7e:	02078793          	addi	a5,a5,32
    80001e82:	02070713          	addi	a4,a4,32
    80001e86:	fed792e3          	bne	a5,a3,80001e6a <fork+0x56>
  np->trapframe->a0 = 0;
    80001e8a:	058a3783          	ld	a5,88(s4)
    80001e8e:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e92:	0d0a8493          	addi	s1,s5,208
    80001e96:	0d0a0913          	addi	s2,s4,208
    80001e9a:	150a8993          	addi	s3,s5,336
    80001e9e:	a00d                	j	80001ec0 <fork+0xac>
    freeproc(np);
    80001ea0:	8552                	mv	a0,s4
    80001ea2:	00000097          	auipc	ra,0x0
    80001ea6:	d34080e7          	jalr	-716(ra) # 80001bd6 <freeproc>
    release(&np->lock);
    80001eaa:	8552                	mv	a0,s4
    80001eac:	fffff097          	auipc	ra,0xfffff
    80001eb0:	e50080e7          	jalr	-432(ra) # 80000cfc <release>
    return -1;
    80001eb4:	597d                	li	s2,-1
    80001eb6:	a059                	j	80001f3c <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001eb8:	04a1                	addi	s1,s1,8
    80001eba:	0921                	addi	s2,s2,8
    80001ebc:	01348b63          	beq	s1,s3,80001ed2 <fork+0xbe>
    if(p->ofile[i])
    80001ec0:	6088                	ld	a0,0(s1)
    80001ec2:	d97d                	beqz	a0,80001eb8 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ec4:	00002097          	auipc	ra,0x2
    80001ec8:	666080e7          	jalr	1638(ra) # 8000452a <filedup>
    80001ecc:	00a93023          	sd	a0,0(s2)
    80001ed0:	b7e5                	j	80001eb8 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001ed2:	150ab503          	ld	a0,336(s5)
    80001ed6:	00001097          	auipc	ra,0x1
    80001eda:	7fe080e7          	jalr	2046(ra) # 800036d4 <idup>
    80001ede:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ee2:	4641                	li	a2,16
    80001ee4:	158a8593          	addi	a1,s5,344
    80001ee8:	158a0513          	addi	a0,s4,344
    80001eec:	fffff097          	auipc	ra,0xfffff
    80001ef0:	fa0080e7          	jalr	-96(ra) # 80000e8c <safestrcpy>
  pid = np->pid;
    80001ef4:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001ef8:	8552                	mv	a0,s4
    80001efa:	fffff097          	auipc	ra,0xfffff
    80001efe:	e02080e7          	jalr	-510(ra) # 80000cfc <release>
  acquire(&wait_lock);
    80001f02:	00016497          	auipc	s1,0x16
    80001f06:	70648493          	addi	s1,s1,1798 # 80018608 <wait_lock>
    80001f0a:	8526                	mv	a0,s1
    80001f0c:	fffff097          	auipc	ra,0xfffff
    80001f10:	d3c080e7          	jalr	-708(ra) # 80000c48 <acquire>
  np->parent = p;
    80001f14:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001f18:	8526                	mv	a0,s1
    80001f1a:	fffff097          	auipc	ra,0xfffff
    80001f1e:	de2080e7          	jalr	-542(ra) # 80000cfc <release>
  acquire(&np->lock);
    80001f22:	8552                	mv	a0,s4
    80001f24:	fffff097          	auipc	ra,0xfffff
    80001f28:	d24080e7          	jalr	-732(ra) # 80000c48 <acquire>
  np->state = RUNNABLE;
    80001f2c:	478d                	li	a5,3
    80001f2e:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001f32:	8552                	mv	a0,s4
    80001f34:	fffff097          	auipc	ra,0xfffff
    80001f38:	dc8080e7          	jalr	-568(ra) # 80000cfc <release>
}
    80001f3c:	854a                	mv	a0,s2
    80001f3e:	70e2                	ld	ra,56(sp)
    80001f40:	7442                	ld	s0,48(sp)
    80001f42:	74a2                	ld	s1,40(sp)
    80001f44:	7902                	ld	s2,32(sp)
    80001f46:	69e2                	ld	s3,24(sp)
    80001f48:	6a42                	ld	s4,16(sp)
    80001f4a:	6aa2                	ld	s5,8(sp)
    80001f4c:	6121                	addi	sp,sp,64
    80001f4e:	8082                	ret
    return -1;
    80001f50:	597d                	li	s2,-1
    80001f52:	b7ed                	j	80001f3c <fork+0x128>

0000000080001f54 <scheduler>:
{
    80001f54:	7139                	addi	sp,sp,-64
    80001f56:	fc06                	sd	ra,56(sp)
    80001f58:	f822                	sd	s0,48(sp)
    80001f5a:	f426                	sd	s1,40(sp)
    80001f5c:	f04a                	sd	s2,32(sp)
    80001f5e:	ec4e                	sd	s3,24(sp)
    80001f60:	e852                	sd	s4,16(sp)
    80001f62:	e456                	sd	s5,8(sp)
    80001f64:	e05a                	sd	s6,0(sp)
    80001f66:	0080                	addi	s0,sp,64
    80001f68:	8792                	mv	a5,tp
  int id = r_tp();
    80001f6a:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f6c:	00779a93          	slli	s5,a5,0x7
    80001f70:	00016717          	auipc	a4,0x16
    80001f74:	68070713          	addi	a4,a4,1664 # 800185f0 <pid_lock>
    80001f78:	9756                	add	a4,a4,s5
    80001f7a:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f7e:	00016717          	auipc	a4,0x16
    80001f82:	6aa70713          	addi	a4,a4,1706 # 80018628 <cpus+0x8>
    80001f86:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f88:	498d                	li	s3,3
        p->state = RUNNING;
    80001f8a:	4b11                	li	s6,4
        c->proc = p;
    80001f8c:	079e                	slli	a5,a5,0x7
    80001f8e:	00016a17          	auipc	s4,0x16
    80001f92:	662a0a13          	addi	s4,s4,1634 # 800185f0 <pid_lock>
    80001f96:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f98:	0001c917          	auipc	s2,0x1c
    80001f9c:	68890913          	addi	s2,s2,1672 # 8001e620 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fa0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fa4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fa8:	10079073          	csrw	sstatus,a5
    80001fac:	00017497          	auipc	s1,0x17
    80001fb0:	a7448493          	addi	s1,s1,-1420 # 80018a20 <proc>
    80001fb4:	a811                	j	80001fc8 <scheduler+0x74>
      release(&p->lock);
    80001fb6:	8526                	mv	a0,s1
    80001fb8:	fffff097          	auipc	ra,0xfffff
    80001fbc:	d44080e7          	jalr	-700(ra) # 80000cfc <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fc0:	17048493          	addi	s1,s1,368
    80001fc4:	fd248ee3          	beq	s1,s2,80001fa0 <scheduler+0x4c>
      acquire(&p->lock);
    80001fc8:	8526                	mv	a0,s1
    80001fca:	fffff097          	auipc	ra,0xfffff
    80001fce:	c7e080e7          	jalr	-898(ra) # 80000c48 <acquire>
      if(p->state == RUNNABLE) {
    80001fd2:	4c9c                	lw	a5,24(s1)
    80001fd4:	ff3791e3          	bne	a5,s3,80001fb6 <scheduler+0x62>
        p->state = RUNNING;
    80001fd8:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001fdc:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001fe0:	06048593          	addi	a1,s1,96
    80001fe4:	8556                	mv	a0,s5
    80001fe6:	00000097          	auipc	ra,0x0
    80001fea:	684080e7          	jalr	1668(ra) # 8000266a <swtch>
        c->proc = 0;
    80001fee:	020a3823          	sd	zero,48(s4)
    80001ff2:	b7d1                	j	80001fb6 <scheduler+0x62>

0000000080001ff4 <sched>:
{
    80001ff4:	7179                	addi	sp,sp,-48
    80001ff6:	f406                	sd	ra,40(sp)
    80001ff8:	f022                	sd	s0,32(sp)
    80001ffa:	ec26                	sd	s1,24(sp)
    80001ffc:	e84a                	sd	s2,16(sp)
    80001ffe:	e44e                	sd	s3,8(sp)
    80002000:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002002:	00000097          	auipc	ra,0x0
    80002006:	a22080e7          	jalr	-1502(ra) # 80001a24 <myproc>
    8000200a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000200c:	fffff097          	auipc	ra,0xfffff
    80002010:	bc2080e7          	jalr	-1086(ra) # 80000bce <holding>
    80002014:	c93d                	beqz	a0,8000208a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002016:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002018:	2781                	sext.w	a5,a5
    8000201a:	079e                	slli	a5,a5,0x7
    8000201c:	00016717          	auipc	a4,0x16
    80002020:	5d470713          	addi	a4,a4,1492 # 800185f0 <pid_lock>
    80002024:	97ba                	add	a5,a5,a4
    80002026:	0a87a703          	lw	a4,168(a5)
    8000202a:	4785                	li	a5,1
    8000202c:	06f71763          	bne	a4,a5,8000209a <sched+0xa6>
  if(p->state == RUNNING)
    80002030:	4c98                	lw	a4,24(s1)
    80002032:	4791                	li	a5,4
    80002034:	06f70b63          	beq	a4,a5,800020aa <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002038:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000203c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000203e:	efb5                	bnez	a5,800020ba <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002040:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002042:	00016917          	auipc	s2,0x16
    80002046:	5ae90913          	addi	s2,s2,1454 # 800185f0 <pid_lock>
    8000204a:	2781                	sext.w	a5,a5
    8000204c:	079e                	slli	a5,a5,0x7
    8000204e:	97ca                	add	a5,a5,s2
    80002050:	0ac7a983          	lw	s3,172(a5)
    80002054:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002056:	2781                	sext.w	a5,a5
    80002058:	079e                	slli	a5,a5,0x7
    8000205a:	00016597          	auipc	a1,0x16
    8000205e:	5ce58593          	addi	a1,a1,1486 # 80018628 <cpus+0x8>
    80002062:	95be                	add	a1,a1,a5
    80002064:	06048513          	addi	a0,s1,96
    80002068:	00000097          	auipc	ra,0x0
    8000206c:	602080e7          	jalr	1538(ra) # 8000266a <swtch>
    80002070:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002072:	2781                	sext.w	a5,a5
    80002074:	079e                	slli	a5,a5,0x7
    80002076:	993e                	add	s2,s2,a5
    80002078:	0b392623          	sw	s3,172(s2)
}
    8000207c:	70a2                	ld	ra,40(sp)
    8000207e:	7402                	ld	s0,32(sp)
    80002080:	64e2                	ld	s1,24(sp)
    80002082:	6942                	ld	s2,16(sp)
    80002084:	69a2                	ld	s3,8(sp)
    80002086:	6145                	addi	sp,sp,48
    80002088:	8082                	ret
    panic("sched p->lock");
    8000208a:	00006517          	auipc	a0,0x6
    8000208e:	19650513          	addi	a0,a0,406 # 80008220 <digits+0x1e0>
    80002092:	ffffe097          	auipc	ra,0xffffe
    80002096:	4ae080e7          	jalr	1198(ra) # 80000540 <panic>
    panic("sched locks");
    8000209a:	00006517          	auipc	a0,0x6
    8000209e:	19650513          	addi	a0,a0,406 # 80008230 <digits+0x1f0>
    800020a2:	ffffe097          	auipc	ra,0xffffe
    800020a6:	49e080e7          	jalr	1182(ra) # 80000540 <panic>
    panic("sched running");
    800020aa:	00006517          	auipc	a0,0x6
    800020ae:	19650513          	addi	a0,a0,406 # 80008240 <digits+0x200>
    800020b2:	ffffe097          	auipc	ra,0xffffe
    800020b6:	48e080e7          	jalr	1166(ra) # 80000540 <panic>
    panic("sched interruptible");
    800020ba:	00006517          	auipc	a0,0x6
    800020be:	19650513          	addi	a0,a0,406 # 80008250 <digits+0x210>
    800020c2:	ffffe097          	auipc	ra,0xffffe
    800020c6:	47e080e7          	jalr	1150(ra) # 80000540 <panic>

00000000800020ca <yield>:
{
    800020ca:	1101                	addi	sp,sp,-32
    800020cc:	ec06                	sd	ra,24(sp)
    800020ce:	e822                	sd	s0,16(sp)
    800020d0:	e426                	sd	s1,8(sp)
    800020d2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020d4:	00000097          	auipc	ra,0x0
    800020d8:	950080e7          	jalr	-1712(ra) # 80001a24 <myproc>
    800020dc:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020de:	fffff097          	auipc	ra,0xfffff
    800020e2:	b6a080e7          	jalr	-1174(ra) # 80000c48 <acquire>
  p->state = RUNNABLE;
    800020e6:	478d                	li	a5,3
    800020e8:	cc9c                	sw	a5,24(s1)
  sched();
    800020ea:	00000097          	auipc	ra,0x0
    800020ee:	f0a080e7          	jalr	-246(ra) # 80001ff4 <sched>
  release(&p->lock);
    800020f2:	8526                	mv	a0,s1
    800020f4:	fffff097          	auipc	ra,0xfffff
    800020f8:	c08080e7          	jalr	-1016(ra) # 80000cfc <release>
}
    800020fc:	60e2                	ld	ra,24(sp)
    800020fe:	6442                	ld	s0,16(sp)
    80002100:	64a2                	ld	s1,8(sp)
    80002102:	6105                	addi	sp,sp,32
    80002104:	8082                	ret

0000000080002106 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002106:	7179                	addi	sp,sp,-48
    80002108:	f406                	sd	ra,40(sp)
    8000210a:	f022                	sd	s0,32(sp)
    8000210c:	ec26                	sd	s1,24(sp)
    8000210e:	e84a                	sd	s2,16(sp)
    80002110:	e44e                	sd	s3,8(sp)
    80002112:	1800                	addi	s0,sp,48
    80002114:	89aa                	mv	s3,a0
    80002116:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002118:	00000097          	auipc	ra,0x0
    8000211c:	90c080e7          	jalr	-1780(ra) # 80001a24 <myproc>
    80002120:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002122:	fffff097          	auipc	ra,0xfffff
    80002126:	b26080e7          	jalr	-1242(ra) # 80000c48 <acquire>
  release(lk);
    8000212a:	854a                	mv	a0,s2
    8000212c:	fffff097          	auipc	ra,0xfffff
    80002130:	bd0080e7          	jalr	-1072(ra) # 80000cfc <release>

  // Go to sleep.
  p->chan = chan;
    80002134:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002138:	4789                	li	a5,2
    8000213a:	cc9c                	sw	a5,24(s1)

  sched();
    8000213c:	00000097          	auipc	ra,0x0
    80002140:	eb8080e7          	jalr	-328(ra) # 80001ff4 <sched>

  // Tidy up.
  p->chan = 0;
    80002144:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002148:	8526                	mv	a0,s1
    8000214a:	fffff097          	auipc	ra,0xfffff
    8000214e:	bb2080e7          	jalr	-1102(ra) # 80000cfc <release>
  acquire(lk);
    80002152:	854a                	mv	a0,s2
    80002154:	fffff097          	auipc	ra,0xfffff
    80002158:	af4080e7          	jalr	-1292(ra) # 80000c48 <acquire>
}
    8000215c:	70a2                	ld	ra,40(sp)
    8000215e:	7402                	ld	s0,32(sp)
    80002160:	64e2                	ld	s1,24(sp)
    80002162:	6942                	ld	s2,16(sp)
    80002164:	69a2                	ld	s3,8(sp)
    80002166:	6145                	addi	sp,sp,48
    80002168:	8082                	ret

000000008000216a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000216a:	7139                	addi	sp,sp,-64
    8000216c:	fc06                	sd	ra,56(sp)
    8000216e:	f822                	sd	s0,48(sp)
    80002170:	f426                	sd	s1,40(sp)
    80002172:	f04a                	sd	s2,32(sp)
    80002174:	ec4e                	sd	s3,24(sp)
    80002176:	e852                	sd	s4,16(sp)
    80002178:	e456                	sd	s5,8(sp)
    8000217a:	0080                	addi	s0,sp,64
    8000217c:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000217e:	00017497          	auipc	s1,0x17
    80002182:	8a248493          	addi	s1,s1,-1886 # 80018a20 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002186:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002188:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000218a:	0001c917          	auipc	s2,0x1c
    8000218e:	49690913          	addi	s2,s2,1174 # 8001e620 <tickslock>
    80002192:	a811                	j	800021a6 <wakeup+0x3c>
      }
      release(&p->lock);
    80002194:	8526                	mv	a0,s1
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	b66080e7          	jalr	-1178(ra) # 80000cfc <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000219e:	17048493          	addi	s1,s1,368
    800021a2:	03248663          	beq	s1,s2,800021ce <wakeup+0x64>
    if(p != myproc()){
    800021a6:	00000097          	auipc	ra,0x0
    800021aa:	87e080e7          	jalr	-1922(ra) # 80001a24 <myproc>
    800021ae:	fea488e3          	beq	s1,a0,8000219e <wakeup+0x34>
      acquire(&p->lock);
    800021b2:	8526                	mv	a0,s1
    800021b4:	fffff097          	auipc	ra,0xfffff
    800021b8:	a94080e7          	jalr	-1388(ra) # 80000c48 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800021bc:	4c9c                	lw	a5,24(s1)
    800021be:	fd379be3          	bne	a5,s3,80002194 <wakeup+0x2a>
    800021c2:	709c                	ld	a5,32(s1)
    800021c4:	fd4798e3          	bne	a5,s4,80002194 <wakeup+0x2a>
        p->state = RUNNABLE;
    800021c8:	0154ac23          	sw	s5,24(s1)
    800021cc:	b7e1                	j	80002194 <wakeup+0x2a>
    }
  }
}
    800021ce:	70e2                	ld	ra,56(sp)
    800021d0:	7442                	ld	s0,48(sp)
    800021d2:	74a2                	ld	s1,40(sp)
    800021d4:	7902                	ld	s2,32(sp)
    800021d6:	69e2                	ld	s3,24(sp)
    800021d8:	6a42                	ld	s4,16(sp)
    800021da:	6aa2                	ld	s5,8(sp)
    800021dc:	6121                	addi	sp,sp,64
    800021de:	8082                	ret

00000000800021e0 <reparent>:
{
    800021e0:	7179                	addi	sp,sp,-48
    800021e2:	f406                	sd	ra,40(sp)
    800021e4:	f022                	sd	s0,32(sp)
    800021e6:	ec26                	sd	s1,24(sp)
    800021e8:	e84a                	sd	s2,16(sp)
    800021ea:	e44e                	sd	s3,8(sp)
    800021ec:	e052                	sd	s4,0(sp)
    800021ee:	1800                	addi	s0,sp,48
    800021f0:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021f2:	00017497          	auipc	s1,0x17
    800021f6:	82e48493          	addi	s1,s1,-2002 # 80018a20 <proc>
      pp->parent = initproc;
    800021fa:	0000ea17          	auipc	s4,0xe
    800021fe:	16ea0a13          	addi	s4,s4,366 # 80010368 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002202:	0001c997          	auipc	s3,0x1c
    80002206:	41e98993          	addi	s3,s3,1054 # 8001e620 <tickslock>
    8000220a:	a029                	j	80002214 <reparent+0x34>
    8000220c:	17048493          	addi	s1,s1,368
    80002210:	01348d63          	beq	s1,s3,8000222a <reparent+0x4a>
    if(pp->parent == p){
    80002214:	7c9c                	ld	a5,56(s1)
    80002216:	ff279be3          	bne	a5,s2,8000220c <reparent+0x2c>
      pp->parent = initproc;
    8000221a:	000a3503          	ld	a0,0(s4)
    8000221e:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002220:	00000097          	auipc	ra,0x0
    80002224:	f4a080e7          	jalr	-182(ra) # 8000216a <wakeup>
    80002228:	b7d5                	j	8000220c <reparent+0x2c>
}
    8000222a:	70a2                	ld	ra,40(sp)
    8000222c:	7402                	ld	s0,32(sp)
    8000222e:	64e2                	ld	s1,24(sp)
    80002230:	6942                	ld	s2,16(sp)
    80002232:	69a2                	ld	s3,8(sp)
    80002234:	6a02                	ld	s4,0(sp)
    80002236:	6145                	addi	sp,sp,48
    80002238:	8082                	ret

000000008000223a <exit>:
{
    8000223a:	7179                	addi	sp,sp,-48
    8000223c:	f406                	sd	ra,40(sp)
    8000223e:	f022                	sd	s0,32(sp)
    80002240:	ec26                	sd	s1,24(sp)
    80002242:	e84a                	sd	s2,16(sp)
    80002244:	e44e                	sd	s3,8(sp)
    80002246:	e052                	sd	s4,0(sp)
    80002248:	1800                	addi	s0,sp,48
    8000224a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000224c:	fffff097          	auipc	ra,0xfffff
    80002250:	7d8080e7          	jalr	2008(ra) # 80001a24 <myproc>
    80002254:	89aa                	mv	s3,a0
  if(p == initproc)
    80002256:	0000e797          	auipc	a5,0xe
    8000225a:	1127b783          	ld	a5,274(a5) # 80010368 <initproc>
    8000225e:	0d050493          	addi	s1,a0,208
    80002262:	15050913          	addi	s2,a0,336
    80002266:	02a79363          	bne	a5,a0,8000228c <exit+0x52>
    panic("init exiting");
    8000226a:	00006517          	auipc	a0,0x6
    8000226e:	ffe50513          	addi	a0,a0,-2 # 80008268 <digits+0x228>
    80002272:	ffffe097          	auipc	ra,0xffffe
    80002276:	2ce080e7          	jalr	718(ra) # 80000540 <panic>
      fileclose(f);
    8000227a:	00002097          	auipc	ra,0x2
    8000227e:	302080e7          	jalr	770(ra) # 8000457c <fileclose>
      p->ofile[fd] = 0;
    80002282:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002286:	04a1                	addi	s1,s1,8
    80002288:	01248563          	beq	s1,s2,80002292 <exit+0x58>
    if(p->ofile[fd]){
    8000228c:	6088                	ld	a0,0(s1)
    8000228e:	f575                	bnez	a0,8000227a <exit+0x40>
    80002290:	bfdd                	j	80002286 <exit+0x4c>
  begin_op();
    80002292:	00002097          	auipc	ra,0x2
    80002296:	e26080e7          	jalr	-474(ra) # 800040b8 <begin_op>
  iput(p->cwd);
    8000229a:	1509b503          	ld	a0,336(s3)
    8000229e:	00001097          	auipc	ra,0x1
    800022a2:	62e080e7          	jalr	1582(ra) # 800038cc <iput>
  end_op();
    800022a6:	00002097          	auipc	ra,0x2
    800022aa:	e8c080e7          	jalr	-372(ra) # 80004132 <end_op>
  p->cwd = 0;
    800022ae:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800022b2:	00016497          	auipc	s1,0x16
    800022b6:	35648493          	addi	s1,s1,854 # 80018608 <wait_lock>
    800022ba:	8526                	mv	a0,s1
    800022bc:	fffff097          	auipc	ra,0xfffff
    800022c0:	98c080e7          	jalr	-1652(ra) # 80000c48 <acquire>
  reparent(p);
    800022c4:	854e                	mv	a0,s3
    800022c6:	00000097          	auipc	ra,0x0
    800022ca:	f1a080e7          	jalr	-230(ra) # 800021e0 <reparent>
  wakeup(p->parent);
    800022ce:	0389b503          	ld	a0,56(s3)
    800022d2:	00000097          	auipc	ra,0x0
    800022d6:	e98080e7          	jalr	-360(ra) # 8000216a <wakeup>
  acquire(&p->lock);
    800022da:	854e                	mv	a0,s3
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	96c080e7          	jalr	-1684(ra) # 80000c48 <acquire>
  p->xstate = status;
    800022e4:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022e8:	4795                	li	a5,5
    800022ea:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800022ee:	8526                	mv	a0,s1
    800022f0:	fffff097          	auipc	ra,0xfffff
    800022f4:	a0c080e7          	jalr	-1524(ra) # 80000cfc <release>
  sched();
    800022f8:	00000097          	auipc	ra,0x0
    800022fc:	cfc080e7          	jalr	-772(ra) # 80001ff4 <sched>
  panic("zombie exit");
    80002300:	00006517          	auipc	a0,0x6
    80002304:	f7850513          	addi	a0,a0,-136 # 80008278 <digits+0x238>
    80002308:	ffffe097          	auipc	ra,0xffffe
    8000230c:	238080e7          	jalr	568(ra) # 80000540 <panic>

0000000080002310 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002310:	7179                	addi	sp,sp,-48
    80002312:	f406                	sd	ra,40(sp)
    80002314:	f022                	sd	s0,32(sp)
    80002316:	ec26                	sd	s1,24(sp)
    80002318:	e84a                	sd	s2,16(sp)
    8000231a:	e44e                	sd	s3,8(sp)
    8000231c:	1800                	addi	s0,sp,48
    8000231e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002320:	00016497          	auipc	s1,0x16
    80002324:	70048493          	addi	s1,s1,1792 # 80018a20 <proc>
    80002328:	0001c997          	auipc	s3,0x1c
    8000232c:	2f898993          	addi	s3,s3,760 # 8001e620 <tickslock>
    acquire(&p->lock);
    80002330:	8526                	mv	a0,s1
    80002332:	fffff097          	auipc	ra,0xfffff
    80002336:	916080e7          	jalr	-1770(ra) # 80000c48 <acquire>
    if(p->pid == pid){
    8000233a:	589c                	lw	a5,48(s1)
    8000233c:	01278d63          	beq	a5,s2,80002356 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002340:	8526                	mv	a0,s1
    80002342:	fffff097          	auipc	ra,0xfffff
    80002346:	9ba080e7          	jalr	-1606(ra) # 80000cfc <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000234a:	17048493          	addi	s1,s1,368
    8000234e:	ff3491e3          	bne	s1,s3,80002330 <kill+0x20>
  }
  return -1;
    80002352:	557d                	li	a0,-1
    80002354:	a829                	j	8000236e <kill+0x5e>
      p->killed = 1;
    80002356:	4785                	li	a5,1
    80002358:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000235a:	4c98                	lw	a4,24(s1)
    8000235c:	4789                	li	a5,2
    8000235e:	00f70f63          	beq	a4,a5,8000237c <kill+0x6c>
      release(&p->lock);
    80002362:	8526                	mv	a0,s1
    80002364:	fffff097          	auipc	ra,0xfffff
    80002368:	998080e7          	jalr	-1640(ra) # 80000cfc <release>
      return 0;
    8000236c:	4501                	li	a0,0
}
    8000236e:	70a2                	ld	ra,40(sp)
    80002370:	7402                	ld	s0,32(sp)
    80002372:	64e2                	ld	s1,24(sp)
    80002374:	6942                	ld	s2,16(sp)
    80002376:	69a2                	ld	s3,8(sp)
    80002378:	6145                	addi	sp,sp,48
    8000237a:	8082                	ret
        p->state = RUNNABLE;
    8000237c:	478d                	li	a5,3
    8000237e:	cc9c                	sw	a5,24(s1)
    80002380:	b7cd                	j	80002362 <kill+0x52>

0000000080002382 <setkilled>:

void
setkilled(struct proc *p)
{
    80002382:	1101                	addi	sp,sp,-32
    80002384:	ec06                	sd	ra,24(sp)
    80002386:	e822                	sd	s0,16(sp)
    80002388:	e426                	sd	s1,8(sp)
    8000238a:	1000                	addi	s0,sp,32
    8000238c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000238e:	fffff097          	auipc	ra,0xfffff
    80002392:	8ba080e7          	jalr	-1862(ra) # 80000c48 <acquire>
  p->killed = 1;
    80002396:	4785                	li	a5,1
    80002398:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000239a:	8526                	mv	a0,s1
    8000239c:	fffff097          	auipc	ra,0xfffff
    800023a0:	960080e7          	jalr	-1696(ra) # 80000cfc <release>
}
    800023a4:	60e2                	ld	ra,24(sp)
    800023a6:	6442                	ld	s0,16(sp)
    800023a8:	64a2                	ld	s1,8(sp)
    800023aa:	6105                	addi	sp,sp,32
    800023ac:	8082                	ret

00000000800023ae <killed>:

int
killed(struct proc *p)
{
    800023ae:	1101                	addi	sp,sp,-32
    800023b0:	ec06                	sd	ra,24(sp)
    800023b2:	e822                	sd	s0,16(sp)
    800023b4:	e426                	sd	s1,8(sp)
    800023b6:	e04a                	sd	s2,0(sp)
    800023b8:	1000                	addi	s0,sp,32
    800023ba:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	88c080e7          	jalr	-1908(ra) # 80000c48 <acquire>
  k = p->killed;
    800023c4:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800023c8:	8526                	mv	a0,s1
    800023ca:	fffff097          	auipc	ra,0xfffff
    800023ce:	932080e7          	jalr	-1742(ra) # 80000cfc <release>
  return k;
}
    800023d2:	854a                	mv	a0,s2
    800023d4:	60e2                	ld	ra,24(sp)
    800023d6:	6442                	ld	s0,16(sp)
    800023d8:	64a2                	ld	s1,8(sp)
    800023da:	6902                	ld	s2,0(sp)
    800023dc:	6105                	addi	sp,sp,32
    800023de:	8082                	ret

00000000800023e0 <wait>:
{
    800023e0:	715d                	addi	sp,sp,-80
    800023e2:	e486                	sd	ra,72(sp)
    800023e4:	e0a2                	sd	s0,64(sp)
    800023e6:	fc26                	sd	s1,56(sp)
    800023e8:	f84a                	sd	s2,48(sp)
    800023ea:	f44e                	sd	s3,40(sp)
    800023ec:	f052                	sd	s4,32(sp)
    800023ee:	ec56                	sd	s5,24(sp)
    800023f0:	e85a                	sd	s6,16(sp)
    800023f2:	e45e                	sd	s7,8(sp)
    800023f4:	e062                	sd	s8,0(sp)
    800023f6:	0880                	addi	s0,sp,80
    800023f8:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023fa:	fffff097          	auipc	ra,0xfffff
    800023fe:	62a080e7          	jalr	1578(ra) # 80001a24 <myproc>
    80002402:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002404:	00016517          	auipc	a0,0x16
    80002408:	20450513          	addi	a0,a0,516 # 80018608 <wait_lock>
    8000240c:	fffff097          	auipc	ra,0xfffff
    80002410:	83c080e7          	jalr	-1988(ra) # 80000c48 <acquire>
    havekids = 0;
    80002414:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002416:	4a15                	li	s4,5
        havekids = 1;
    80002418:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000241a:	0001c997          	auipc	s3,0x1c
    8000241e:	20698993          	addi	s3,s3,518 # 8001e620 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002422:	00016c17          	auipc	s8,0x16
    80002426:	1e6c0c13          	addi	s8,s8,486 # 80018608 <wait_lock>
    8000242a:	a0d1                	j	800024ee <wait+0x10e>
          pid = pp->pid;
    8000242c:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002430:	000b0e63          	beqz	s6,8000244c <wait+0x6c>
    80002434:	4691                	li	a3,4
    80002436:	02c48613          	addi	a2,s1,44
    8000243a:	85da                	mv	a1,s6
    8000243c:	05093503          	ld	a0,80(s2)
    80002440:	fffff097          	auipc	ra,0xfffff
    80002444:	2a4080e7          	jalr	676(ra) # 800016e4 <copyout>
    80002448:	04054163          	bltz	a0,8000248a <wait+0xaa>
          freeproc(pp);
    8000244c:	8526                	mv	a0,s1
    8000244e:	fffff097          	auipc	ra,0xfffff
    80002452:	788080e7          	jalr	1928(ra) # 80001bd6 <freeproc>
          release(&pp->lock);
    80002456:	8526                	mv	a0,s1
    80002458:	fffff097          	auipc	ra,0xfffff
    8000245c:	8a4080e7          	jalr	-1884(ra) # 80000cfc <release>
          release(&wait_lock);
    80002460:	00016517          	auipc	a0,0x16
    80002464:	1a850513          	addi	a0,a0,424 # 80018608 <wait_lock>
    80002468:	fffff097          	auipc	ra,0xfffff
    8000246c:	894080e7          	jalr	-1900(ra) # 80000cfc <release>
}
    80002470:	854e                	mv	a0,s3
    80002472:	60a6                	ld	ra,72(sp)
    80002474:	6406                	ld	s0,64(sp)
    80002476:	74e2                	ld	s1,56(sp)
    80002478:	7942                	ld	s2,48(sp)
    8000247a:	79a2                	ld	s3,40(sp)
    8000247c:	7a02                	ld	s4,32(sp)
    8000247e:	6ae2                	ld	s5,24(sp)
    80002480:	6b42                	ld	s6,16(sp)
    80002482:	6ba2                	ld	s7,8(sp)
    80002484:	6c02                	ld	s8,0(sp)
    80002486:	6161                	addi	sp,sp,80
    80002488:	8082                	ret
            release(&pp->lock);
    8000248a:	8526                	mv	a0,s1
    8000248c:	fffff097          	auipc	ra,0xfffff
    80002490:	870080e7          	jalr	-1936(ra) # 80000cfc <release>
            release(&wait_lock);
    80002494:	00016517          	auipc	a0,0x16
    80002498:	17450513          	addi	a0,a0,372 # 80018608 <wait_lock>
    8000249c:	fffff097          	auipc	ra,0xfffff
    800024a0:	860080e7          	jalr	-1952(ra) # 80000cfc <release>
            return -1;
    800024a4:	59fd                	li	s3,-1
    800024a6:	b7e9                	j	80002470 <wait+0x90>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800024a8:	17048493          	addi	s1,s1,368
    800024ac:	03348463          	beq	s1,s3,800024d4 <wait+0xf4>
      if(pp->parent == p){
    800024b0:	7c9c                	ld	a5,56(s1)
    800024b2:	ff279be3          	bne	a5,s2,800024a8 <wait+0xc8>
        acquire(&pp->lock);
    800024b6:	8526                	mv	a0,s1
    800024b8:	ffffe097          	auipc	ra,0xffffe
    800024bc:	790080e7          	jalr	1936(ra) # 80000c48 <acquire>
        if(pp->state == ZOMBIE){
    800024c0:	4c9c                	lw	a5,24(s1)
    800024c2:	f74785e3          	beq	a5,s4,8000242c <wait+0x4c>
        release(&pp->lock);
    800024c6:	8526                	mv	a0,s1
    800024c8:	fffff097          	auipc	ra,0xfffff
    800024cc:	834080e7          	jalr	-1996(ra) # 80000cfc <release>
        havekids = 1;
    800024d0:	8756                	mv	a4,s5
    800024d2:	bfd9                	j	800024a8 <wait+0xc8>
    if(!havekids || killed(p)){
    800024d4:	c31d                	beqz	a4,800024fa <wait+0x11a>
    800024d6:	854a                	mv	a0,s2
    800024d8:	00000097          	auipc	ra,0x0
    800024dc:	ed6080e7          	jalr	-298(ra) # 800023ae <killed>
    800024e0:	ed09                	bnez	a0,800024fa <wait+0x11a>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024e2:	85e2                	mv	a1,s8
    800024e4:	854a                	mv	a0,s2
    800024e6:	00000097          	auipc	ra,0x0
    800024ea:	c20080e7          	jalr	-992(ra) # 80002106 <sleep>
    havekids = 0;
    800024ee:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800024f0:	00016497          	auipc	s1,0x16
    800024f4:	53048493          	addi	s1,s1,1328 # 80018a20 <proc>
    800024f8:	bf65                	j	800024b0 <wait+0xd0>
      release(&wait_lock);
    800024fa:	00016517          	auipc	a0,0x16
    800024fe:	10e50513          	addi	a0,a0,270 # 80018608 <wait_lock>
    80002502:	ffffe097          	auipc	ra,0xffffe
    80002506:	7fa080e7          	jalr	2042(ra) # 80000cfc <release>
      return -1;
    8000250a:	59fd                	li	s3,-1
    8000250c:	b795                	j	80002470 <wait+0x90>

000000008000250e <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000250e:	7179                	addi	sp,sp,-48
    80002510:	f406                	sd	ra,40(sp)
    80002512:	f022                	sd	s0,32(sp)
    80002514:	ec26                	sd	s1,24(sp)
    80002516:	e84a                	sd	s2,16(sp)
    80002518:	e44e                	sd	s3,8(sp)
    8000251a:	e052                	sd	s4,0(sp)
    8000251c:	1800                	addi	s0,sp,48
    8000251e:	84aa                	mv	s1,a0
    80002520:	892e                	mv	s2,a1
    80002522:	89b2                	mv	s3,a2
    80002524:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002526:	fffff097          	auipc	ra,0xfffff
    8000252a:	4fe080e7          	jalr	1278(ra) # 80001a24 <myproc>
  if(user_dst){
    8000252e:	c08d                	beqz	s1,80002550 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002530:	86d2                	mv	a3,s4
    80002532:	864e                	mv	a2,s3
    80002534:	85ca                	mv	a1,s2
    80002536:	6928                	ld	a0,80(a0)
    80002538:	fffff097          	auipc	ra,0xfffff
    8000253c:	1ac080e7          	jalr	428(ra) # 800016e4 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002540:	70a2                	ld	ra,40(sp)
    80002542:	7402                	ld	s0,32(sp)
    80002544:	64e2                	ld	s1,24(sp)
    80002546:	6942                	ld	s2,16(sp)
    80002548:	69a2                	ld	s3,8(sp)
    8000254a:	6a02                	ld	s4,0(sp)
    8000254c:	6145                	addi	sp,sp,48
    8000254e:	8082                	ret
    memmove((char *)dst, src, len);
    80002550:	000a061b          	sext.w	a2,s4
    80002554:	85ce                	mv	a1,s3
    80002556:	854a                	mv	a0,s2
    80002558:	fffff097          	auipc	ra,0xfffff
    8000255c:	848080e7          	jalr	-1976(ra) # 80000da0 <memmove>
    return 0;
    80002560:	8526                	mv	a0,s1
    80002562:	bff9                	j	80002540 <either_copyout+0x32>

0000000080002564 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002564:	7179                	addi	sp,sp,-48
    80002566:	f406                	sd	ra,40(sp)
    80002568:	f022                	sd	s0,32(sp)
    8000256a:	ec26                	sd	s1,24(sp)
    8000256c:	e84a                	sd	s2,16(sp)
    8000256e:	e44e                	sd	s3,8(sp)
    80002570:	e052                	sd	s4,0(sp)
    80002572:	1800                	addi	s0,sp,48
    80002574:	892a                	mv	s2,a0
    80002576:	84ae                	mv	s1,a1
    80002578:	89b2                	mv	s3,a2
    8000257a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000257c:	fffff097          	auipc	ra,0xfffff
    80002580:	4a8080e7          	jalr	1192(ra) # 80001a24 <myproc>
  if(user_src){
    80002584:	c08d                	beqz	s1,800025a6 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002586:	86d2                	mv	a3,s4
    80002588:	864e                	mv	a2,s3
    8000258a:	85ca                	mv	a1,s2
    8000258c:	6928                	ld	a0,80(a0)
    8000258e:	fffff097          	auipc	ra,0xfffff
    80002592:	1e2080e7          	jalr	482(ra) # 80001770 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002596:	70a2                	ld	ra,40(sp)
    80002598:	7402                	ld	s0,32(sp)
    8000259a:	64e2                	ld	s1,24(sp)
    8000259c:	6942                	ld	s2,16(sp)
    8000259e:	69a2                	ld	s3,8(sp)
    800025a0:	6a02                	ld	s4,0(sp)
    800025a2:	6145                	addi	sp,sp,48
    800025a4:	8082                	ret
    memmove(dst, (char*)src, len);
    800025a6:	000a061b          	sext.w	a2,s4
    800025aa:	85ce                	mv	a1,s3
    800025ac:	854a                	mv	a0,s2
    800025ae:	ffffe097          	auipc	ra,0xffffe
    800025b2:	7f2080e7          	jalr	2034(ra) # 80000da0 <memmove>
    return 0;
    800025b6:	8526                	mv	a0,s1
    800025b8:	bff9                	j	80002596 <either_copyin+0x32>

00000000800025ba <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025ba:	715d                	addi	sp,sp,-80
    800025bc:	e486                	sd	ra,72(sp)
    800025be:	e0a2                	sd	s0,64(sp)
    800025c0:	fc26                	sd	s1,56(sp)
    800025c2:	f84a                	sd	s2,48(sp)
    800025c4:	f44e                	sd	s3,40(sp)
    800025c6:	f052                	sd	s4,32(sp)
    800025c8:	ec56                	sd	s5,24(sp)
    800025ca:	e85a                	sd	s6,16(sp)
    800025cc:	e45e                	sd	s7,8(sp)
    800025ce:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025d0:	0000e517          	auipc	a0,0xe
    800025d4:	c6850513          	addi	a0,a0,-920 # 80010238 <csr_vm_map+0x78f8>
    800025d8:	ffffe097          	auipc	ra,0xffffe
    800025dc:	fb2080e7          	jalr	-78(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025e0:	00016497          	auipc	s1,0x16
    800025e4:	59848493          	addi	s1,s1,1432 # 80018b78 <proc+0x158>
    800025e8:	0001c917          	auipc	s2,0x1c
    800025ec:	19090913          	addi	s2,s2,400 # 8001e778 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025f0:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025f2:	00006997          	auipc	s3,0x6
    800025f6:	c9698993          	addi	s3,s3,-874 # 80008288 <digits+0x248>
    printf("%d %s %s", p->pid, state, p->name);
    800025fa:	00006a97          	auipc	s5,0x6
    800025fe:	c96a8a93          	addi	s5,s5,-874 # 80008290 <digits+0x250>
    printf("\n");
    80002602:	0000ea17          	auipc	s4,0xe
    80002606:	c36a0a13          	addi	s4,s4,-970 # 80010238 <csr_vm_map+0x78f8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000260a:	00006b97          	auipc	s7,0x6
    8000260e:	cc6b8b93          	addi	s7,s7,-826 # 800082d0 <states.0>
    80002612:	a00d                	j	80002634 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002614:	ed86a583          	lw	a1,-296(a3)
    80002618:	8556                	mv	a0,s5
    8000261a:	ffffe097          	auipc	ra,0xffffe
    8000261e:	f70080e7          	jalr	-144(ra) # 8000058a <printf>
    printf("\n");
    80002622:	8552                	mv	a0,s4
    80002624:	ffffe097          	auipc	ra,0xffffe
    80002628:	f66080e7          	jalr	-154(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000262c:	17048493          	addi	s1,s1,368
    80002630:	03248263          	beq	s1,s2,80002654 <procdump+0x9a>
    if(p->state == UNUSED)
    80002634:	86a6                	mv	a3,s1
    80002636:	ec04a783          	lw	a5,-320(s1)
    8000263a:	dbed                	beqz	a5,8000262c <procdump+0x72>
      state = "???";
    8000263c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000263e:	fcfb6be3          	bltu	s6,a5,80002614 <procdump+0x5a>
    80002642:	02079713          	slli	a4,a5,0x20
    80002646:	01d75793          	srli	a5,a4,0x1d
    8000264a:	97de                	add	a5,a5,s7
    8000264c:	6390                	ld	a2,0(a5)
    8000264e:	f279                	bnez	a2,80002614 <procdump+0x5a>
      state = "???";
    80002650:	864e                	mv	a2,s3
    80002652:	b7c9                	j	80002614 <procdump+0x5a>
  }
}
    80002654:	60a6                	ld	ra,72(sp)
    80002656:	6406                	ld	s0,64(sp)
    80002658:	74e2                	ld	s1,56(sp)
    8000265a:	7942                	ld	s2,48(sp)
    8000265c:	79a2                	ld	s3,40(sp)
    8000265e:	7a02                	ld	s4,32(sp)
    80002660:	6ae2                	ld	s5,24(sp)
    80002662:	6b42                	ld	s6,16(sp)
    80002664:	6ba2                	ld	s7,8(sp)
    80002666:	6161                	addi	sp,sp,80
    80002668:	8082                	ret

000000008000266a <swtch>:
    8000266a:	00153023          	sd	ra,0(a0)
    8000266e:	00253423          	sd	sp,8(a0)
    80002672:	e900                	sd	s0,16(a0)
    80002674:	ed04                	sd	s1,24(a0)
    80002676:	03253023          	sd	s2,32(a0)
    8000267a:	03353423          	sd	s3,40(a0)
    8000267e:	03453823          	sd	s4,48(a0)
    80002682:	03553c23          	sd	s5,56(a0)
    80002686:	05653023          	sd	s6,64(a0)
    8000268a:	05753423          	sd	s7,72(a0)
    8000268e:	05853823          	sd	s8,80(a0)
    80002692:	05953c23          	sd	s9,88(a0)
    80002696:	07a53023          	sd	s10,96(a0)
    8000269a:	07b53423          	sd	s11,104(a0)
    8000269e:	0005b083          	ld	ra,0(a1)
    800026a2:	0085b103          	ld	sp,8(a1)
    800026a6:	6980                	ld	s0,16(a1)
    800026a8:	6d84                	ld	s1,24(a1)
    800026aa:	0205b903          	ld	s2,32(a1)
    800026ae:	0285b983          	ld	s3,40(a1)
    800026b2:	0305ba03          	ld	s4,48(a1)
    800026b6:	0385ba83          	ld	s5,56(a1)
    800026ba:	0405bb03          	ld	s6,64(a1)
    800026be:	0485bb83          	ld	s7,72(a1)
    800026c2:	0505bc03          	ld	s8,80(a1)
    800026c6:	0585bc83          	ld	s9,88(a1)
    800026ca:	0605bd03          	ld	s10,96(a1)
    800026ce:	0685bd83          	ld	s11,104(a1)
    800026d2:	8082                	ret

00000000800026d4 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026d4:	1141                	addi	sp,sp,-16
    800026d6:	e406                	sd	ra,8(sp)
    800026d8:	e022                	sd	s0,0(sp)
    800026da:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026dc:	00006597          	auipc	a1,0x6
    800026e0:	c2458593          	addi	a1,a1,-988 # 80008300 <states.0+0x30>
    800026e4:	0001c517          	auipc	a0,0x1c
    800026e8:	f3c50513          	addi	a0,a0,-196 # 8001e620 <tickslock>
    800026ec:	ffffe097          	auipc	ra,0xffffe
    800026f0:	4cc080e7          	jalr	1228(ra) # 80000bb8 <initlock>
}
    800026f4:	60a2                	ld	ra,8(sp)
    800026f6:	6402                	ld	s0,0(sp)
    800026f8:	0141                	addi	sp,sp,16
    800026fa:	8082                	ret

00000000800026fc <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026fc:	1141                	addi	sp,sp,-16
    800026fe:	e422                	sd	s0,8(sp)
    80002700:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002702:	00003797          	auipc	a5,0x3
    80002706:	50e78793          	addi	a5,a5,1294 # 80005c10 <kernelvec>
    8000270a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000270e:	6422                	ld	s0,8(sp)
    80002710:	0141                	addi	sp,sp,16
    80002712:	8082                	ret

0000000080002714 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002714:	1141                	addi	sp,sp,-16
    80002716:	e406                	sd	ra,8(sp)
    80002718:	e022                	sd	s0,0(sp)
    8000271a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000271c:	fffff097          	auipc	ra,0xfffff
    80002720:	308080e7          	jalr	776(ra) # 80001a24 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002724:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002728:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000272a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000272e:	00005697          	auipc	a3,0x5
    80002732:	8d268693          	addi	a3,a3,-1838 # 80007000 <_trampoline>
    80002736:	00005717          	auipc	a4,0x5
    8000273a:	8ca70713          	addi	a4,a4,-1846 # 80007000 <_trampoline>
    8000273e:	8f15                	sub	a4,a4,a3
    80002740:	040007b7          	lui	a5,0x4000
    80002744:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002746:	07b2                	slli	a5,a5,0xc
    80002748:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000274a:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000274e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002750:	18002673          	csrr	a2,satp
    80002754:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002756:	6d30                	ld	a2,88(a0)
    80002758:	6138                	ld	a4,64(a0)
    8000275a:	6585                	lui	a1,0x1
    8000275c:	972e                	add	a4,a4,a1
    8000275e:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002760:	6d38                	ld	a4,88(a0)
    80002762:	00000617          	auipc	a2,0x0
    80002766:	13460613          	addi	a2,a2,308 # 80002896 <usertrap>
    8000276a:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000276c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000276e:	8612                	mv	a2,tp
    80002770:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002772:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002776:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000277a:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000277e:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002782:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002784:	6f18                	ld	a4,24(a4)
    80002786:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000278a:	6928                	ld	a0,80(a0)
    8000278c:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000278e:	00005717          	auipc	a4,0x5
    80002792:	90e70713          	addi	a4,a4,-1778 # 8000709c <userret>
    80002796:	8f15                	sub	a4,a4,a3
    80002798:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    8000279a:	577d                	li	a4,-1
    8000279c:	177e                	slli	a4,a4,0x3f
    8000279e:	8d59                	or	a0,a0,a4
    800027a0:	9782                	jalr	a5
}
    800027a2:	60a2                	ld	ra,8(sp)
    800027a4:	6402                	ld	s0,0(sp)
    800027a6:	0141                	addi	sp,sp,16
    800027a8:	8082                	ret

00000000800027aa <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027aa:	1101                	addi	sp,sp,-32
    800027ac:	ec06                	sd	ra,24(sp)
    800027ae:	e822                	sd	s0,16(sp)
    800027b0:	e426                	sd	s1,8(sp)
    800027b2:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027b4:	0001c497          	auipc	s1,0x1c
    800027b8:	e6c48493          	addi	s1,s1,-404 # 8001e620 <tickslock>
    800027bc:	8526                	mv	a0,s1
    800027be:	ffffe097          	auipc	ra,0xffffe
    800027c2:	48a080e7          	jalr	1162(ra) # 80000c48 <acquire>
  ticks++;
    800027c6:	0000e517          	auipc	a0,0xe
    800027ca:	baa50513          	addi	a0,a0,-1110 # 80010370 <ticks>
    800027ce:	411c                	lw	a5,0(a0)
    800027d0:	2785                	addiw	a5,a5,1
    800027d2:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027d4:	00000097          	auipc	ra,0x0
    800027d8:	996080e7          	jalr	-1642(ra) # 8000216a <wakeup>
  release(&tickslock);
    800027dc:	8526                	mv	a0,s1
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	51e080e7          	jalr	1310(ra) # 80000cfc <release>
}
    800027e6:	60e2                	ld	ra,24(sp)
    800027e8:	6442                	ld	s0,16(sp)
    800027ea:	64a2                	ld	s1,8(sp)
    800027ec:	6105                	addi	sp,sp,32
    800027ee:	8082                	ret

00000000800027f0 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027f0:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027f4:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    800027f6:	0807df63          	bgez	a5,80002894 <devintr+0xa4>
{
    800027fa:	1101                	addi	sp,sp,-32
    800027fc:	ec06                	sd	ra,24(sp)
    800027fe:	e822                	sd	s0,16(sp)
    80002800:	e426                	sd	s1,8(sp)
    80002802:	1000                	addi	s0,sp,32
     (scause & 0xff) == 9){
    80002804:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    80002808:	46a5                	li	a3,9
    8000280a:	00d70d63          	beq	a4,a3,80002824 <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    8000280e:	577d                	li	a4,-1
    80002810:	177e                	slli	a4,a4,0x3f
    80002812:	0705                	addi	a4,a4,1
    return 0;
    80002814:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002816:	04e78e63          	beq	a5,a4,80002872 <devintr+0x82>
  }
}
    8000281a:	60e2                	ld	ra,24(sp)
    8000281c:	6442                	ld	s0,16(sp)
    8000281e:	64a2                	ld	s1,8(sp)
    80002820:	6105                	addi	sp,sp,32
    80002822:	8082                	ret
    int irq = plic_claim();
    80002824:	00003097          	auipc	ra,0x3
    80002828:	4f4080e7          	jalr	1268(ra) # 80005d18 <plic_claim>
    8000282c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000282e:	47a9                	li	a5,10
    80002830:	02f50763          	beq	a0,a5,8000285e <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    80002834:	4785                	li	a5,1
    80002836:	02f50963          	beq	a0,a5,80002868 <devintr+0x78>
    return 1;
    8000283a:	4505                	li	a0,1
    } else if(irq){
    8000283c:	dcf9                	beqz	s1,8000281a <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    8000283e:	85a6                	mv	a1,s1
    80002840:	00006517          	auipc	a0,0x6
    80002844:	ac850513          	addi	a0,a0,-1336 # 80008308 <states.0+0x38>
    80002848:	ffffe097          	auipc	ra,0xffffe
    8000284c:	d42080e7          	jalr	-702(ra) # 8000058a <printf>
      plic_complete(irq);
    80002850:	8526                	mv	a0,s1
    80002852:	00003097          	auipc	ra,0x3
    80002856:	4ea080e7          	jalr	1258(ra) # 80005d3c <plic_complete>
    return 1;
    8000285a:	4505                	li	a0,1
    8000285c:	bf7d                	j	8000281a <devintr+0x2a>
      uartintr();
    8000285e:	ffffe097          	auipc	ra,0xffffe
    80002862:	1ac080e7          	jalr	428(ra) # 80000a0a <uartintr>
    if(irq)
    80002866:	b7ed                	j	80002850 <devintr+0x60>
      virtio_disk_intr();
    80002868:	00004097          	auipc	ra,0x4
    8000286c:	b4c080e7          	jalr	-1204(ra) # 800063b4 <virtio_disk_intr>
    if(irq)
    80002870:	b7c5                	j	80002850 <devintr+0x60>
    if(cpuid() == 0){
    80002872:	fffff097          	auipc	ra,0xfffff
    80002876:	186080e7          	jalr	390(ra) # 800019f8 <cpuid>
    8000287a:	c901                	beqz	a0,8000288a <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000287c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002880:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002882:	14479073          	csrw	sip,a5
    return 2;
    80002886:	4509                	li	a0,2
    80002888:	bf49                	j	8000281a <devintr+0x2a>
      clockintr();
    8000288a:	00000097          	auipc	ra,0x0
    8000288e:	f20080e7          	jalr	-224(ra) # 800027aa <clockintr>
    80002892:	b7ed                	j	8000287c <devintr+0x8c>
}
    80002894:	8082                	ret

0000000080002896 <usertrap>:
{
    80002896:	1101                	addi	sp,sp,-32
    80002898:	ec06                	sd	ra,24(sp)
    8000289a:	e822                	sd	s0,16(sp)
    8000289c:	e426                	sd	s1,8(sp)
    8000289e:	e04a                	sd	s2,0(sp)
    800028a0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028a2:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028a6:	1007f793          	andi	a5,a5,256
    800028aa:	eba9                	bnez	a5,800028fc <usertrap+0x66>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028ac:	00003797          	auipc	a5,0x3
    800028b0:	36478793          	addi	a5,a5,868 # 80005c10 <kernelvec>
    800028b4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028b8:	fffff097          	auipc	ra,0xfffff
    800028bc:	16c080e7          	jalr	364(ra) # 80001a24 <myproc>
    800028c0:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028c2:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028c4:	14102773          	csrr	a4,sepc
    800028c8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028ca:	14202773          	csrr	a4,scause
  if(r_scause() == 8) {
    800028ce:	47a1                	li	a5,8
    800028d0:	02f70e63          	beq	a4,a5,8000290c <usertrap+0x76>
  } else if((which_dev = devintr()) != 0) {
    800028d4:	00000097          	auipc	ra,0x0
    800028d8:	f1c080e7          	jalr	-228(ra) # 800027f0 <devintr>
    800028dc:	892a                	mv	s2,a0
    800028de:	e979                	bnez	a0,800029b4 <usertrap+0x11e>
  } else if(p->proc_te_vm) { 
    800028e0:	1684a783          	lw	a5,360(s1)
    800028e4:	cbd9                	beqz	a5,8000297a <usertrap+0xe4>
    trap_and_emulate();
    800028e6:	00004097          	auipc	ra,0x4
    800028ea:	000080e7          	jalr	ra # 800068e6 <trap_and_emulate>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028f2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028f6:	10079073          	csrw	sstatus,a5
}
    800028fa:	a81d                	j	80002930 <usertrap+0x9a>
    panic("usertrap: not from user mode");
    800028fc:	00006517          	auipc	a0,0x6
    80002900:	a2c50513          	addi	a0,a0,-1492 # 80008328 <states.0+0x58>
    80002904:	ffffe097          	auipc	ra,0xffffe
    80002908:	c3c080e7          	jalr	-964(ra) # 80000540 <panic>
    if(killed(p))
    8000290c:	00000097          	auipc	ra,0x0
    80002910:	aa2080e7          	jalr	-1374(ra) # 800023ae <killed>
    80002914:	ed15                	bnez	a0,80002950 <usertrap+0xba>
    if(p->proc_te_vm) {
    80002916:	1684a783          	lw	a5,360(s1)
    8000291a:	c3a9                	beqz	a5,8000295c <usertrap+0xc6>
      trap_and_emulate_ecall();
    8000291c:	00004097          	auipc	ra,0x4
    80002920:	ed6080e7          	jalr	-298(ra) # 800067f2 <trap_and_emulate_ecall>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002924:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002928:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000292c:	10079073          	csrw	sstatus,a5
  if(killed(p))
    80002930:	8526                	mv	a0,s1
    80002932:	00000097          	auipc	ra,0x0
    80002936:	a7c080e7          	jalr	-1412(ra) # 800023ae <killed>
    8000293a:	e541                	bnez	a0,800029c2 <usertrap+0x12c>
  usertrapret();
    8000293c:	00000097          	auipc	ra,0x0
    80002940:	dd8080e7          	jalr	-552(ra) # 80002714 <usertrapret>
}
    80002944:	60e2                	ld	ra,24(sp)
    80002946:	6442                	ld	s0,16(sp)
    80002948:	64a2                	ld	s1,8(sp)
    8000294a:	6902                	ld	s2,0(sp)
    8000294c:	6105                	addi	sp,sp,32
    8000294e:	8082                	ret
      exit(-1);
    80002950:	557d                	li	a0,-1
    80002952:	00000097          	auipc	ra,0x0
    80002956:	8e8080e7          	jalr	-1816(ra) # 8000223a <exit>
    8000295a:	bf75                	j	80002916 <usertrap+0x80>
      p->trapframe->epc += 4;
    8000295c:	6cb8                	ld	a4,88(s1)
    8000295e:	6f1c                	ld	a5,24(a4)
    80002960:	0791                	addi	a5,a5,4
    80002962:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002964:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002968:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000296c:	10079073          	csrw	sstatus,a5
      syscall();
    80002970:	00000097          	auipc	ra,0x0
    80002974:	2b8080e7          	jalr	696(ra) # 80002c28 <syscall>
    80002978:	bf65                	j	80002930 <usertrap+0x9a>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000297a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000297e:	5890                	lw	a2,48(s1)
    80002980:	00006517          	auipc	a0,0x6
    80002984:	9c850513          	addi	a0,a0,-1592 # 80008348 <states.0+0x78>
    80002988:	ffffe097          	auipc	ra,0xffffe
    8000298c:	c02080e7          	jalr	-1022(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002990:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002994:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002998:	00006517          	auipc	a0,0x6
    8000299c:	9e050513          	addi	a0,a0,-1568 # 80008378 <states.0+0xa8>
    800029a0:	ffffe097          	auipc	ra,0xffffe
    800029a4:	bea080e7          	jalr	-1046(ra) # 8000058a <printf>
    setkilled(p);
    800029a8:	8526                	mv	a0,s1
    800029aa:	00000097          	auipc	ra,0x0
    800029ae:	9d8080e7          	jalr	-1576(ra) # 80002382 <setkilled>
    800029b2:	bfbd                	j	80002930 <usertrap+0x9a>
  if(killed(p))
    800029b4:	8526                	mv	a0,s1
    800029b6:	00000097          	auipc	ra,0x0
    800029ba:	9f8080e7          	jalr	-1544(ra) # 800023ae <killed>
    800029be:	c901                	beqz	a0,800029ce <usertrap+0x138>
    800029c0:	a011                	j	800029c4 <usertrap+0x12e>
    800029c2:	4901                	li	s2,0
    exit(-1);
    800029c4:	557d                	li	a0,-1
    800029c6:	00000097          	auipc	ra,0x0
    800029ca:	874080e7          	jalr	-1932(ra) # 8000223a <exit>
  if(which_dev == 2)
    800029ce:	4789                	li	a5,2
    800029d0:	f6f916e3          	bne	s2,a5,8000293c <usertrap+0xa6>
    yield();
    800029d4:	fffff097          	auipc	ra,0xfffff
    800029d8:	6f6080e7          	jalr	1782(ra) # 800020ca <yield>
    800029dc:	b785                	j	8000293c <usertrap+0xa6>

00000000800029de <kerneltrap>:
{
    800029de:	7179                	addi	sp,sp,-48
    800029e0:	f406                	sd	ra,40(sp)
    800029e2:	f022                	sd	s0,32(sp)
    800029e4:	ec26                	sd	s1,24(sp)
    800029e6:	e84a                	sd	s2,16(sp)
    800029e8:	e44e                	sd	s3,8(sp)
    800029ea:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029ec:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029f0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029f4:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029f8:	1004f793          	andi	a5,s1,256
    800029fc:	cb85                	beqz	a5,80002a2c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029fe:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a02:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a04:	ef85                	bnez	a5,80002a3c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a06:	00000097          	auipc	ra,0x0
    80002a0a:	dea080e7          	jalr	-534(ra) # 800027f0 <devintr>
    80002a0e:	cd1d                	beqz	a0,80002a4c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a10:	4789                	li	a5,2
    80002a12:	06f50a63          	beq	a0,a5,80002a86 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a16:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a1a:	10049073          	csrw	sstatus,s1
}
    80002a1e:	70a2                	ld	ra,40(sp)
    80002a20:	7402                	ld	s0,32(sp)
    80002a22:	64e2                	ld	s1,24(sp)
    80002a24:	6942                	ld	s2,16(sp)
    80002a26:	69a2                	ld	s3,8(sp)
    80002a28:	6145                	addi	sp,sp,48
    80002a2a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a2c:	00006517          	auipc	a0,0x6
    80002a30:	96c50513          	addi	a0,a0,-1684 # 80008398 <states.0+0xc8>
    80002a34:	ffffe097          	auipc	ra,0xffffe
    80002a38:	b0c080e7          	jalr	-1268(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a3c:	00006517          	auipc	a0,0x6
    80002a40:	98450513          	addi	a0,a0,-1660 # 800083c0 <states.0+0xf0>
    80002a44:	ffffe097          	auipc	ra,0xffffe
    80002a48:	afc080e7          	jalr	-1284(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002a4c:	85ce                	mv	a1,s3
    80002a4e:	00006517          	auipc	a0,0x6
    80002a52:	99250513          	addi	a0,a0,-1646 # 800083e0 <states.0+0x110>
    80002a56:	ffffe097          	auipc	ra,0xffffe
    80002a5a:	b34080e7          	jalr	-1228(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a5e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a62:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a66:	00006517          	auipc	a0,0x6
    80002a6a:	98a50513          	addi	a0,a0,-1654 # 800083f0 <states.0+0x120>
    80002a6e:	ffffe097          	auipc	ra,0xffffe
    80002a72:	b1c080e7          	jalr	-1252(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002a76:	00006517          	auipc	a0,0x6
    80002a7a:	99250513          	addi	a0,a0,-1646 # 80008408 <states.0+0x138>
    80002a7e:	ffffe097          	auipc	ra,0xffffe
    80002a82:	ac2080e7          	jalr	-1342(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a86:	fffff097          	auipc	ra,0xfffff
    80002a8a:	f9e080e7          	jalr	-98(ra) # 80001a24 <myproc>
    80002a8e:	d541                	beqz	a0,80002a16 <kerneltrap+0x38>
    80002a90:	fffff097          	auipc	ra,0xfffff
    80002a94:	f94080e7          	jalr	-108(ra) # 80001a24 <myproc>
    80002a98:	4d18                	lw	a4,24(a0)
    80002a9a:	4791                	li	a5,4
    80002a9c:	f6f71de3          	bne	a4,a5,80002a16 <kerneltrap+0x38>
    yield();
    80002aa0:	fffff097          	auipc	ra,0xfffff
    80002aa4:	62a080e7          	jalr	1578(ra) # 800020ca <yield>
    80002aa8:	b7bd                	j	80002a16 <kerneltrap+0x38>

0000000080002aaa <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002aaa:	1101                	addi	sp,sp,-32
    80002aac:	ec06                	sd	ra,24(sp)
    80002aae:	e822                	sd	s0,16(sp)
    80002ab0:	e426                	sd	s1,8(sp)
    80002ab2:	1000                	addi	s0,sp,32
    80002ab4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ab6:	fffff097          	auipc	ra,0xfffff
    80002aba:	f6e080e7          	jalr	-146(ra) # 80001a24 <myproc>
  switch (n) {
    80002abe:	4795                	li	a5,5
    80002ac0:	0497e163          	bltu	a5,s1,80002b02 <argraw+0x58>
    80002ac4:	048a                	slli	s1,s1,0x2
    80002ac6:	00006717          	auipc	a4,0x6
    80002aca:	97a70713          	addi	a4,a4,-1670 # 80008440 <states.0+0x170>
    80002ace:	94ba                	add	s1,s1,a4
    80002ad0:	409c                	lw	a5,0(s1)
    80002ad2:	97ba                	add	a5,a5,a4
    80002ad4:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ad6:	6d3c                	ld	a5,88(a0)
    80002ad8:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ada:	60e2                	ld	ra,24(sp)
    80002adc:	6442                	ld	s0,16(sp)
    80002ade:	64a2                	ld	s1,8(sp)
    80002ae0:	6105                	addi	sp,sp,32
    80002ae2:	8082                	ret
    return p->trapframe->a1;
    80002ae4:	6d3c                	ld	a5,88(a0)
    80002ae6:	7fa8                	ld	a0,120(a5)
    80002ae8:	bfcd                	j	80002ada <argraw+0x30>
    return p->trapframe->a2;
    80002aea:	6d3c                	ld	a5,88(a0)
    80002aec:	63c8                	ld	a0,128(a5)
    80002aee:	b7f5                	j	80002ada <argraw+0x30>
    return p->trapframe->a3;
    80002af0:	6d3c                	ld	a5,88(a0)
    80002af2:	67c8                	ld	a0,136(a5)
    80002af4:	b7dd                	j	80002ada <argraw+0x30>
    return p->trapframe->a4;
    80002af6:	6d3c                	ld	a5,88(a0)
    80002af8:	6bc8                	ld	a0,144(a5)
    80002afa:	b7c5                	j	80002ada <argraw+0x30>
    return p->trapframe->a5;
    80002afc:	6d3c                	ld	a5,88(a0)
    80002afe:	6fc8                	ld	a0,152(a5)
    80002b00:	bfe9                	j	80002ada <argraw+0x30>
  panic("argraw");
    80002b02:	00006517          	auipc	a0,0x6
    80002b06:	91650513          	addi	a0,a0,-1770 # 80008418 <states.0+0x148>
    80002b0a:	ffffe097          	auipc	ra,0xffffe
    80002b0e:	a36080e7          	jalr	-1482(ra) # 80000540 <panic>

0000000080002b12 <fetchaddr>:
{
    80002b12:	1101                	addi	sp,sp,-32
    80002b14:	ec06                	sd	ra,24(sp)
    80002b16:	e822                	sd	s0,16(sp)
    80002b18:	e426                	sd	s1,8(sp)
    80002b1a:	e04a                	sd	s2,0(sp)
    80002b1c:	1000                	addi	s0,sp,32
    80002b1e:	84aa                	mv	s1,a0
    80002b20:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b22:	fffff097          	auipc	ra,0xfffff
    80002b26:	f02080e7          	jalr	-254(ra) # 80001a24 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002b2a:	653c                	ld	a5,72(a0)
    80002b2c:	02f4f863          	bgeu	s1,a5,80002b5c <fetchaddr+0x4a>
    80002b30:	00848713          	addi	a4,s1,8
    80002b34:	02e7e663          	bltu	a5,a4,80002b60 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b38:	46a1                	li	a3,8
    80002b3a:	8626                	mv	a2,s1
    80002b3c:	85ca                	mv	a1,s2
    80002b3e:	6928                	ld	a0,80(a0)
    80002b40:	fffff097          	auipc	ra,0xfffff
    80002b44:	c30080e7          	jalr	-976(ra) # 80001770 <copyin>
    80002b48:	00a03533          	snez	a0,a0
    80002b4c:	40a00533          	neg	a0,a0
}
    80002b50:	60e2                	ld	ra,24(sp)
    80002b52:	6442                	ld	s0,16(sp)
    80002b54:	64a2                	ld	s1,8(sp)
    80002b56:	6902                	ld	s2,0(sp)
    80002b58:	6105                	addi	sp,sp,32
    80002b5a:	8082                	ret
    return -1;
    80002b5c:	557d                	li	a0,-1
    80002b5e:	bfcd                	j	80002b50 <fetchaddr+0x3e>
    80002b60:	557d                	li	a0,-1
    80002b62:	b7fd                	j	80002b50 <fetchaddr+0x3e>

0000000080002b64 <fetchstr>:
{
    80002b64:	7179                	addi	sp,sp,-48
    80002b66:	f406                	sd	ra,40(sp)
    80002b68:	f022                	sd	s0,32(sp)
    80002b6a:	ec26                	sd	s1,24(sp)
    80002b6c:	e84a                	sd	s2,16(sp)
    80002b6e:	e44e                	sd	s3,8(sp)
    80002b70:	1800                	addi	s0,sp,48
    80002b72:	892a                	mv	s2,a0
    80002b74:	84ae                	mv	s1,a1
    80002b76:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b78:	fffff097          	auipc	ra,0xfffff
    80002b7c:	eac080e7          	jalr	-340(ra) # 80001a24 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b80:	86ce                	mv	a3,s3
    80002b82:	864a                	mv	a2,s2
    80002b84:	85a6                	mv	a1,s1
    80002b86:	6928                	ld	a0,80(a0)
    80002b88:	fffff097          	auipc	ra,0xfffff
    80002b8c:	c76080e7          	jalr	-906(ra) # 800017fe <copyinstr>
    80002b90:	00054e63          	bltz	a0,80002bac <fetchstr+0x48>
  return strlen(buf);
    80002b94:	8526                	mv	a0,s1
    80002b96:	ffffe097          	auipc	ra,0xffffe
    80002b9a:	328080e7          	jalr	808(ra) # 80000ebe <strlen>
}
    80002b9e:	70a2                	ld	ra,40(sp)
    80002ba0:	7402                	ld	s0,32(sp)
    80002ba2:	64e2                	ld	s1,24(sp)
    80002ba4:	6942                	ld	s2,16(sp)
    80002ba6:	69a2                	ld	s3,8(sp)
    80002ba8:	6145                	addi	sp,sp,48
    80002baa:	8082                	ret
    return -1;
    80002bac:	557d                	li	a0,-1
    80002bae:	bfc5                	j	80002b9e <fetchstr+0x3a>

0000000080002bb0 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002bb0:	1101                	addi	sp,sp,-32
    80002bb2:	ec06                	sd	ra,24(sp)
    80002bb4:	e822                	sd	s0,16(sp)
    80002bb6:	e426                	sd	s1,8(sp)
    80002bb8:	1000                	addi	s0,sp,32
    80002bba:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bbc:	00000097          	auipc	ra,0x0
    80002bc0:	eee080e7          	jalr	-274(ra) # 80002aaa <argraw>
    80002bc4:	c088                	sw	a0,0(s1)
}
    80002bc6:	60e2                	ld	ra,24(sp)
    80002bc8:	6442                	ld	s0,16(sp)
    80002bca:	64a2                	ld	s1,8(sp)
    80002bcc:	6105                	addi	sp,sp,32
    80002bce:	8082                	ret

0000000080002bd0 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002bd0:	1101                	addi	sp,sp,-32
    80002bd2:	ec06                	sd	ra,24(sp)
    80002bd4:	e822                	sd	s0,16(sp)
    80002bd6:	e426                	sd	s1,8(sp)
    80002bd8:	1000                	addi	s0,sp,32
    80002bda:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bdc:	00000097          	auipc	ra,0x0
    80002be0:	ece080e7          	jalr	-306(ra) # 80002aaa <argraw>
    80002be4:	e088                	sd	a0,0(s1)
}
    80002be6:	60e2                	ld	ra,24(sp)
    80002be8:	6442                	ld	s0,16(sp)
    80002bea:	64a2                	ld	s1,8(sp)
    80002bec:	6105                	addi	sp,sp,32
    80002bee:	8082                	ret

0000000080002bf0 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bf0:	7179                	addi	sp,sp,-48
    80002bf2:	f406                	sd	ra,40(sp)
    80002bf4:	f022                	sd	s0,32(sp)
    80002bf6:	ec26                	sd	s1,24(sp)
    80002bf8:	e84a                	sd	s2,16(sp)
    80002bfa:	1800                	addi	s0,sp,48
    80002bfc:	84ae                	mv	s1,a1
    80002bfe:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002c00:	fd840593          	addi	a1,s0,-40
    80002c04:	00000097          	auipc	ra,0x0
    80002c08:	fcc080e7          	jalr	-52(ra) # 80002bd0 <argaddr>
  return fetchstr(addr, buf, max);
    80002c0c:	864a                	mv	a2,s2
    80002c0e:	85a6                	mv	a1,s1
    80002c10:	fd843503          	ld	a0,-40(s0)
    80002c14:	00000097          	auipc	ra,0x0
    80002c18:	f50080e7          	jalr	-176(ra) # 80002b64 <fetchstr>
}
    80002c1c:	70a2                	ld	ra,40(sp)
    80002c1e:	7402                	ld	s0,32(sp)
    80002c20:	64e2                	ld	s1,24(sp)
    80002c22:	6942                	ld	s2,16(sp)
    80002c24:	6145                	addi	sp,sp,48
    80002c26:	8082                	ret

0000000080002c28 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002c28:	1101                	addi	sp,sp,-32
    80002c2a:	ec06                	sd	ra,24(sp)
    80002c2c:	e822                	sd	s0,16(sp)
    80002c2e:	e426                	sd	s1,8(sp)
    80002c30:	e04a                	sd	s2,0(sp)
    80002c32:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c34:	fffff097          	auipc	ra,0xfffff
    80002c38:	df0080e7          	jalr	-528(ra) # 80001a24 <myproc>
    80002c3c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c3e:	05853903          	ld	s2,88(a0)
    80002c42:	0a893783          	ld	a5,168(s2)
    80002c46:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c4a:	37fd                	addiw	a5,a5,-1
    80002c4c:	4751                	li	a4,20
    80002c4e:	00f76f63          	bltu	a4,a5,80002c6c <syscall+0x44>
    80002c52:	00369713          	slli	a4,a3,0x3
    80002c56:	00006797          	auipc	a5,0x6
    80002c5a:	80278793          	addi	a5,a5,-2046 # 80008458 <syscalls>
    80002c5e:	97ba                	add	a5,a5,a4
    80002c60:	639c                	ld	a5,0(a5)
    80002c62:	c789                	beqz	a5,80002c6c <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002c64:	9782                	jalr	a5
    80002c66:	06a93823          	sd	a0,112(s2)
    80002c6a:	a839                	j	80002c88 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c6c:	15848613          	addi	a2,s1,344
    80002c70:	588c                	lw	a1,48(s1)
    80002c72:	00005517          	auipc	a0,0x5
    80002c76:	7ae50513          	addi	a0,a0,1966 # 80008420 <states.0+0x150>
    80002c7a:	ffffe097          	auipc	ra,0xffffe
    80002c7e:	910080e7          	jalr	-1776(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c82:	6cbc                	ld	a5,88(s1)
    80002c84:	577d                	li	a4,-1
    80002c86:	fbb8                	sd	a4,112(a5)
  }
}
    80002c88:	60e2                	ld	ra,24(sp)
    80002c8a:	6442                	ld	s0,16(sp)
    80002c8c:	64a2                	ld	s1,8(sp)
    80002c8e:	6902                	ld	s2,0(sp)
    80002c90:	6105                	addi	sp,sp,32
    80002c92:	8082                	ret

0000000080002c94 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c94:	1101                	addi	sp,sp,-32
    80002c96:	ec06                	sd	ra,24(sp)
    80002c98:	e822                	sd	s0,16(sp)
    80002c9a:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002c9c:	fec40593          	addi	a1,s0,-20
    80002ca0:	4501                	li	a0,0
    80002ca2:	00000097          	auipc	ra,0x0
    80002ca6:	f0e080e7          	jalr	-242(ra) # 80002bb0 <argint>
  exit(n);
    80002caa:	fec42503          	lw	a0,-20(s0)
    80002cae:	fffff097          	auipc	ra,0xfffff
    80002cb2:	58c080e7          	jalr	1420(ra) # 8000223a <exit>
  return 0;  // not reached
}
    80002cb6:	4501                	li	a0,0
    80002cb8:	60e2                	ld	ra,24(sp)
    80002cba:	6442                	ld	s0,16(sp)
    80002cbc:	6105                	addi	sp,sp,32
    80002cbe:	8082                	ret

0000000080002cc0 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cc0:	1141                	addi	sp,sp,-16
    80002cc2:	e406                	sd	ra,8(sp)
    80002cc4:	e022                	sd	s0,0(sp)
    80002cc6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cc8:	fffff097          	auipc	ra,0xfffff
    80002ccc:	d5c080e7          	jalr	-676(ra) # 80001a24 <myproc>
}
    80002cd0:	5908                	lw	a0,48(a0)
    80002cd2:	60a2                	ld	ra,8(sp)
    80002cd4:	6402                	ld	s0,0(sp)
    80002cd6:	0141                	addi	sp,sp,16
    80002cd8:	8082                	ret

0000000080002cda <sys_fork>:

uint64
sys_fork(void)
{
    80002cda:	1141                	addi	sp,sp,-16
    80002cdc:	e406                	sd	ra,8(sp)
    80002cde:	e022                	sd	s0,0(sp)
    80002ce0:	0800                	addi	s0,sp,16
  return fork();
    80002ce2:	fffff097          	auipc	ra,0xfffff
    80002ce6:	132080e7          	jalr	306(ra) # 80001e14 <fork>
}
    80002cea:	60a2                	ld	ra,8(sp)
    80002cec:	6402                	ld	s0,0(sp)
    80002cee:	0141                	addi	sp,sp,16
    80002cf0:	8082                	ret

0000000080002cf2 <sys_wait>:

uint64
sys_wait(void)
{
    80002cf2:	1101                	addi	sp,sp,-32
    80002cf4:	ec06                	sd	ra,24(sp)
    80002cf6:	e822                	sd	s0,16(sp)
    80002cf8:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002cfa:	fe840593          	addi	a1,s0,-24
    80002cfe:	4501                	li	a0,0
    80002d00:	00000097          	auipc	ra,0x0
    80002d04:	ed0080e7          	jalr	-304(ra) # 80002bd0 <argaddr>
  return wait(p);
    80002d08:	fe843503          	ld	a0,-24(s0)
    80002d0c:	fffff097          	auipc	ra,0xfffff
    80002d10:	6d4080e7          	jalr	1748(ra) # 800023e0 <wait>
}
    80002d14:	60e2                	ld	ra,24(sp)
    80002d16:	6442                	ld	s0,16(sp)
    80002d18:	6105                	addi	sp,sp,32
    80002d1a:	8082                	ret

0000000080002d1c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d1c:	7179                	addi	sp,sp,-48
    80002d1e:	f406                	sd	ra,40(sp)
    80002d20:	f022                	sd	s0,32(sp)
    80002d22:	ec26                	sd	s1,24(sp)
    80002d24:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002d26:	fdc40593          	addi	a1,s0,-36
    80002d2a:	4501                	li	a0,0
    80002d2c:	00000097          	auipc	ra,0x0
    80002d30:	e84080e7          	jalr	-380(ra) # 80002bb0 <argint>
  addr = myproc()->sz;
    80002d34:	fffff097          	auipc	ra,0xfffff
    80002d38:	cf0080e7          	jalr	-784(ra) # 80001a24 <myproc>
    80002d3c:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002d3e:	fdc42503          	lw	a0,-36(s0)
    80002d42:	fffff097          	auipc	ra,0xfffff
    80002d46:	076080e7          	jalr	118(ra) # 80001db8 <growproc>
    80002d4a:	00054863          	bltz	a0,80002d5a <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002d4e:	8526                	mv	a0,s1
    80002d50:	70a2                	ld	ra,40(sp)
    80002d52:	7402                	ld	s0,32(sp)
    80002d54:	64e2                	ld	s1,24(sp)
    80002d56:	6145                	addi	sp,sp,48
    80002d58:	8082                	ret
    return -1;
    80002d5a:	54fd                	li	s1,-1
    80002d5c:	bfcd                	j	80002d4e <sys_sbrk+0x32>

0000000080002d5e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d5e:	7139                	addi	sp,sp,-64
    80002d60:	fc06                	sd	ra,56(sp)
    80002d62:	f822                	sd	s0,48(sp)
    80002d64:	f426                	sd	s1,40(sp)
    80002d66:	f04a                	sd	s2,32(sp)
    80002d68:	ec4e                	sd	s3,24(sp)
    80002d6a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002d6c:	fcc40593          	addi	a1,s0,-52
    80002d70:	4501                	li	a0,0
    80002d72:	00000097          	auipc	ra,0x0
    80002d76:	e3e080e7          	jalr	-450(ra) # 80002bb0 <argint>
  acquire(&tickslock);
    80002d7a:	0001c517          	auipc	a0,0x1c
    80002d7e:	8a650513          	addi	a0,a0,-1882 # 8001e620 <tickslock>
    80002d82:	ffffe097          	auipc	ra,0xffffe
    80002d86:	ec6080e7          	jalr	-314(ra) # 80000c48 <acquire>
  ticks0 = ticks;
    80002d8a:	0000d917          	auipc	s2,0xd
    80002d8e:	5e692903          	lw	s2,1510(s2) # 80010370 <ticks>
  while(ticks - ticks0 < n){
    80002d92:	fcc42783          	lw	a5,-52(s0)
    80002d96:	cf9d                	beqz	a5,80002dd4 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d98:	0001c997          	auipc	s3,0x1c
    80002d9c:	88898993          	addi	s3,s3,-1912 # 8001e620 <tickslock>
    80002da0:	0000d497          	auipc	s1,0xd
    80002da4:	5d048493          	addi	s1,s1,1488 # 80010370 <ticks>
    if(killed(myproc())){
    80002da8:	fffff097          	auipc	ra,0xfffff
    80002dac:	c7c080e7          	jalr	-900(ra) # 80001a24 <myproc>
    80002db0:	fffff097          	auipc	ra,0xfffff
    80002db4:	5fe080e7          	jalr	1534(ra) # 800023ae <killed>
    80002db8:	ed15                	bnez	a0,80002df4 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002dba:	85ce                	mv	a1,s3
    80002dbc:	8526                	mv	a0,s1
    80002dbe:	fffff097          	auipc	ra,0xfffff
    80002dc2:	348080e7          	jalr	840(ra) # 80002106 <sleep>
  while(ticks - ticks0 < n){
    80002dc6:	409c                	lw	a5,0(s1)
    80002dc8:	412787bb          	subw	a5,a5,s2
    80002dcc:	fcc42703          	lw	a4,-52(s0)
    80002dd0:	fce7ece3          	bltu	a5,a4,80002da8 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002dd4:	0001c517          	auipc	a0,0x1c
    80002dd8:	84c50513          	addi	a0,a0,-1972 # 8001e620 <tickslock>
    80002ddc:	ffffe097          	auipc	ra,0xffffe
    80002de0:	f20080e7          	jalr	-224(ra) # 80000cfc <release>
  return 0;
    80002de4:	4501                	li	a0,0
}
    80002de6:	70e2                	ld	ra,56(sp)
    80002de8:	7442                	ld	s0,48(sp)
    80002dea:	74a2                	ld	s1,40(sp)
    80002dec:	7902                	ld	s2,32(sp)
    80002dee:	69e2                	ld	s3,24(sp)
    80002df0:	6121                	addi	sp,sp,64
    80002df2:	8082                	ret
      release(&tickslock);
    80002df4:	0001c517          	auipc	a0,0x1c
    80002df8:	82c50513          	addi	a0,a0,-2004 # 8001e620 <tickslock>
    80002dfc:	ffffe097          	auipc	ra,0xffffe
    80002e00:	f00080e7          	jalr	-256(ra) # 80000cfc <release>
      return -1;
    80002e04:	557d                	li	a0,-1
    80002e06:	b7c5                	j	80002de6 <sys_sleep+0x88>

0000000080002e08 <sys_kill>:

uint64
sys_kill(void)
{
    80002e08:	1101                	addi	sp,sp,-32
    80002e0a:	ec06                	sd	ra,24(sp)
    80002e0c:	e822                	sd	s0,16(sp)
    80002e0e:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002e10:	fec40593          	addi	a1,s0,-20
    80002e14:	4501                	li	a0,0
    80002e16:	00000097          	auipc	ra,0x0
    80002e1a:	d9a080e7          	jalr	-614(ra) # 80002bb0 <argint>
  return kill(pid);
    80002e1e:	fec42503          	lw	a0,-20(s0)
    80002e22:	fffff097          	auipc	ra,0xfffff
    80002e26:	4ee080e7          	jalr	1262(ra) # 80002310 <kill>
}
    80002e2a:	60e2                	ld	ra,24(sp)
    80002e2c:	6442                	ld	s0,16(sp)
    80002e2e:	6105                	addi	sp,sp,32
    80002e30:	8082                	ret

0000000080002e32 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e32:	1101                	addi	sp,sp,-32
    80002e34:	ec06                	sd	ra,24(sp)
    80002e36:	e822                	sd	s0,16(sp)
    80002e38:	e426                	sd	s1,8(sp)
    80002e3a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e3c:	0001b517          	auipc	a0,0x1b
    80002e40:	7e450513          	addi	a0,a0,2020 # 8001e620 <tickslock>
    80002e44:	ffffe097          	auipc	ra,0xffffe
    80002e48:	e04080e7          	jalr	-508(ra) # 80000c48 <acquire>
  xticks = ticks;
    80002e4c:	0000d497          	auipc	s1,0xd
    80002e50:	5244a483          	lw	s1,1316(s1) # 80010370 <ticks>
  release(&tickslock);
    80002e54:	0001b517          	auipc	a0,0x1b
    80002e58:	7cc50513          	addi	a0,a0,1996 # 8001e620 <tickslock>
    80002e5c:	ffffe097          	auipc	ra,0xffffe
    80002e60:	ea0080e7          	jalr	-352(ra) # 80000cfc <release>
  return xticks;
}
    80002e64:	02049513          	slli	a0,s1,0x20
    80002e68:	9101                	srli	a0,a0,0x20
    80002e6a:	60e2                	ld	ra,24(sp)
    80002e6c:	6442                	ld	s0,16(sp)
    80002e6e:	64a2                	ld	s1,8(sp)
    80002e70:	6105                	addi	sp,sp,32
    80002e72:	8082                	ret

0000000080002e74 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e74:	7179                	addi	sp,sp,-48
    80002e76:	f406                	sd	ra,40(sp)
    80002e78:	f022                	sd	s0,32(sp)
    80002e7a:	ec26                	sd	s1,24(sp)
    80002e7c:	e84a                	sd	s2,16(sp)
    80002e7e:	e44e                	sd	s3,8(sp)
    80002e80:	e052                	sd	s4,0(sp)
    80002e82:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e84:	00005597          	auipc	a1,0x5
    80002e88:	68458593          	addi	a1,a1,1668 # 80008508 <syscalls+0xb0>
    80002e8c:	0001b517          	auipc	a0,0x1b
    80002e90:	7ac50513          	addi	a0,a0,1964 # 8001e638 <bcache>
    80002e94:	ffffe097          	auipc	ra,0xffffe
    80002e98:	d24080e7          	jalr	-732(ra) # 80000bb8 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e9c:	00023797          	auipc	a5,0x23
    80002ea0:	79c78793          	addi	a5,a5,1948 # 80026638 <bcache+0x8000>
    80002ea4:	00024717          	auipc	a4,0x24
    80002ea8:	9fc70713          	addi	a4,a4,-1540 # 800268a0 <bcache+0x8268>
    80002eac:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002eb0:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002eb4:	0001b497          	auipc	s1,0x1b
    80002eb8:	79c48493          	addi	s1,s1,1948 # 8001e650 <bcache+0x18>
    b->next = bcache.head.next;
    80002ebc:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ebe:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ec0:	00005a17          	auipc	s4,0x5
    80002ec4:	650a0a13          	addi	s4,s4,1616 # 80008510 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002ec8:	2b893783          	ld	a5,696(s2)
    80002ecc:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002ece:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002ed2:	85d2                	mv	a1,s4
    80002ed4:	01048513          	addi	a0,s1,16
    80002ed8:	00001097          	auipc	ra,0x1
    80002edc:	496080e7          	jalr	1174(ra) # 8000436e <initsleeplock>
    bcache.head.next->prev = b;
    80002ee0:	2b893783          	ld	a5,696(s2)
    80002ee4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002ee6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002eea:	45848493          	addi	s1,s1,1112
    80002eee:	fd349de3          	bne	s1,s3,80002ec8 <binit+0x54>
  }
}
    80002ef2:	70a2                	ld	ra,40(sp)
    80002ef4:	7402                	ld	s0,32(sp)
    80002ef6:	64e2                	ld	s1,24(sp)
    80002ef8:	6942                	ld	s2,16(sp)
    80002efa:	69a2                	ld	s3,8(sp)
    80002efc:	6a02                	ld	s4,0(sp)
    80002efe:	6145                	addi	sp,sp,48
    80002f00:	8082                	ret

0000000080002f02 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f02:	7179                	addi	sp,sp,-48
    80002f04:	f406                	sd	ra,40(sp)
    80002f06:	f022                	sd	s0,32(sp)
    80002f08:	ec26                	sd	s1,24(sp)
    80002f0a:	e84a                	sd	s2,16(sp)
    80002f0c:	e44e                	sd	s3,8(sp)
    80002f0e:	1800                	addi	s0,sp,48
    80002f10:	892a                	mv	s2,a0
    80002f12:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f14:	0001b517          	auipc	a0,0x1b
    80002f18:	72450513          	addi	a0,a0,1828 # 8001e638 <bcache>
    80002f1c:	ffffe097          	auipc	ra,0xffffe
    80002f20:	d2c080e7          	jalr	-724(ra) # 80000c48 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f24:	00024497          	auipc	s1,0x24
    80002f28:	9cc4b483          	ld	s1,-1588(s1) # 800268f0 <bcache+0x82b8>
    80002f2c:	00024797          	auipc	a5,0x24
    80002f30:	97478793          	addi	a5,a5,-1676 # 800268a0 <bcache+0x8268>
    80002f34:	02f48f63          	beq	s1,a5,80002f72 <bread+0x70>
    80002f38:	873e                	mv	a4,a5
    80002f3a:	a021                	j	80002f42 <bread+0x40>
    80002f3c:	68a4                	ld	s1,80(s1)
    80002f3e:	02e48a63          	beq	s1,a4,80002f72 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f42:	449c                	lw	a5,8(s1)
    80002f44:	ff279ce3          	bne	a5,s2,80002f3c <bread+0x3a>
    80002f48:	44dc                	lw	a5,12(s1)
    80002f4a:	ff3799e3          	bne	a5,s3,80002f3c <bread+0x3a>
      b->refcnt++;
    80002f4e:	40bc                	lw	a5,64(s1)
    80002f50:	2785                	addiw	a5,a5,1
    80002f52:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f54:	0001b517          	auipc	a0,0x1b
    80002f58:	6e450513          	addi	a0,a0,1764 # 8001e638 <bcache>
    80002f5c:	ffffe097          	auipc	ra,0xffffe
    80002f60:	da0080e7          	jalr	-608(ra) # 80000cfc <release>
      acquiresleep(&b->lock);
    80002f64:	01048513          	addi	a0,s1,16
    80002f68:	00001097          	auipc	ra,0x1
    80002f6c:	440080e7          	jalr	1088(ra) # 800043a8 <acquiresleep>
      return b;
    80002f70:	a8b9                	j	80002fce <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f72:	00024497          	auipc	s1,0x24
    80002f76:	9764b483          	ld	s1,-1674(s1) # 800268e8 <bcache+0x82b0>
    80002f7a:	00024797          	auipc	a5,0x24
    80002f7e:	92678793          	addi	a5,a5,-1754 # 800268a0 <bcache+0x8268>
    80002f82:	00f48863          	beq	s1,a5,80002f92 <bread+0x90>
    80002f86:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f88:	40bc                	lw	a5,64(s1)
    80002f8a:	cf81                	beqz	a5,80002fa2 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f8c:	64a4                	ld	s1,72(s1)
    80002f8e:	fee49de3          	bne	s1,a4,80002f88 <bread+0x86>
  panic("bget: no buffers");
    80002f92:	00005517          	auipc	a0,0x5
    80002f96:	58650513          	addi	a0,a0,1414 # 80008518 <syscalls+0xc0>
    80002f9a:	ffffd097          	auipc	ra,0xffffd
    80002f9e:	5a6080e7          	jalr	1446(ra) # 80000540 <panic>
      b->dev = dev;
    80002fa2:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002fa6:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002faa:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fae:	4785                	li	a5,1
    80002fb0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fb2:	0001b517          	auipc	a0,0x1b
    80002fb6:	68650513          	addi	a0,a0,1670 # 8001e638 <bcache>
    80002fba:	ffffe097          	auipc	ra,0xffffe
    80002fbe:	d42080e7          	jalr	-702(ra) # 80000cfc <release>
      acquiresleep(&b->lock);
    80002fc2:	01048513          	addi	a0,s1,16
    80002fc6:	00001097          	auipc	ra,0x1
    80002fca:	3e2080e7          	jalr	994(ra) # 800043a8 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002fce:	409c                	lw	a5,0(s1)
    80002fd0:	cb89                	beqz	a5,80002fe2 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002fd2:	8526                	mv	a0,s1
    80002fd4:	70a2                	ld	ra,40(sp)
    80002fd6:	7402                	ld	s0,32(sp)
    80002fd8:	64e2                	ld	s1,24(sp)
    80002fda:	6942                	ld	s2,16(sp)
    80002fdc:	69a2                	ld	s3,8(sp)
    80002fde:	6145                	addi	sp,sp,48
    80002fe0:	8082                	ret
    virtio_disk_rw(b, 0);
    80002fe2:	4581                	li	a1,0
    80002fe4:	8526                	mv	a0,s1
    80002fe6:	00003097          	auipc	ra,0x3
    80002fea:	19e080e7          	jalr	414(ra) # 80006184 <virtio_disk_rw>
    b->valid = 1;
    80002fee:	4785                	li	a5,1
    80002ff0:	c09c                	sw	a5,0(s1)
  return b;
    80002ff2:	b7c5                	j	80002fd2 <bread+0xd0>

0000000080002ff4 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002ff4:	1101                	addi	sp,sp,-32
    80002ff6:	ec06                	sd	ra,24(sp)
    80002ff8:	e822                	sd	s0,16(sp)
    80002ffa:	e426                	sd	s1,8(sp)
    80002ffc:	1000                	addi	s0,sp,32
    80002ffe:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003000:	0541                	addi	a0,a0,16
    80003002:	00001097          	auipc	ra,0x1
    80003006:	440080e7          	jalr	1088(ra) # 80004442 <holdingsleep>
    8000300a:	cd01                	beqz	a0,80003022 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000300c:	4585                	li	a1,1
    8000300e:	8526                	mv	a0,s1
    80003010:	00003097          	auipc	ra,0x3
    80003014:	174080e7          	jalr	372(ra) # 80006184 <virtio_disk_rw>
}
    80003018:	60e2                	ld	ra,24(sp)
    8000301a:	6442                	ld	s0,16(sp)
    8000301c:	64a2                	ld	s1,8(sp)
    8000301e:	6105                	addi	sp,sp,32
    80003020:	8082                	ret
    panic("bwrite");
    80003022:	00005517          	auipc	a0,0x5
    80003026:	50e50513          	addi	a0,a0,1294 # 80008530 <syscalls+0xd8>
    8000302a:	ffffd097          	auipc	ra,0xffffd
    8000302e:	516080e7          	jalr	1302(ra) # 80000540 <panic>

0000000080003032 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003032:	1101                	addi	sp,sp,-32
    80003034:	ec06                	sd	ra,24(sp)
    80003036:	e822                	sd	s0,16(sp)
    80003038:	e426                	sd	s1,8(sp)
    8000303a:	e04a                	sd	s2,0(sp)
    8000303c:	1000                	addi	s0,sp,32
    8000303e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003040:	01050913          	addi	s2,a0,16
    80003044:	854a                	mv	a0,s2
    80003046:	00001097          	auipc	ra,0x1
    8000304a:	3fc080e7          	jalr	1020(ra) # 80004442 <holdingsleep>
    8000304e:	c925                	beqz	a0,800030be <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    80003050:	854a                	mv	a0,s2
    80003052:	00001097          	auipc	ra,0x1
    80003056:	3ac080e7          	jalr	940(ra) # 800043fe <releasesleep>

  acquire(&bcache.lock);
    8000305a:	0001b517          	auipc	a0,0x1b
    8000305e:	5de50513          	addi	a0,a0,1502 # 8001e638 <bcache>
    80003062:	ffffe097          	auipc	ra,0xffffe
    80003066:	be6080e7          	jalr	-1050(ra) # 80000c48 <acquire>
  b->refcnt--;
    8000306a:	40bc                	lw	a5,64(s1)
    8000306c:	37fd                	addiw	a5,a5,-1
    8000306e:	0007871b          	sext.w	a4,a5
    80003072:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003074:	e71d                	bnez	a4,800030a2 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003076:	68b8                	ld	a4,80(s1)
    80003078:	64bc                	ld	a5,72(s1)
    8000307a:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    8000307c:	68b8                	ld	a4,80(s1)
    8000307e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003080:	00023797          	auipc	a5,0x23
    80003084:	5b878793          	addi	a5,a5,1464 # 80026638 <bcache+0x8000>
    80003088:	2b87b703          	ld	a4,696(a5)
    8000308c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000308e:	00024717          	auipc	a4,0x24
    80003092:	81270713          	addi	a4,a4,-2030 # 800268a0 <bcache+0x8268>
    80003096:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003098:	2b87b703          	ld	a4,696(a5)
    8000309c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000309e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030a2:	0001b517          	auipc	a0,0x1b
    800030a6:	59650513          	addi	a0,a0,1430 # 8001e638 <bcache>
    800030aa:	ffffe097          	auipc	ra,0xffffe
    800030ae:	c52080e7          	jalr	-942(ra) # 80000cfc <release>
}
    800030b2:	60e2                	ld	ra,24(sp)
    800030b4:	6442                	ld	s0,16(sp)
    800030b6:	64a2                	ld	s1,8(sp)
    800030b8:	6902                	ld	s2,0(sp)
    800030ba:	6105                	addi	sp,sp,32
    800030bc:	8082                	ret
    panic("brelse");
    800030be:	00005517          	auipc	a0,0x5
    800030c2:	47a50513          	addi	a0,a0,1146 # 80008538 <syscalls+0xe0>
    800030c6:	ffffd097          	auipc	ra,0xffffd
    800030ca:	47a080e7          	jalr	1146(ra) # 80000540 <panic>

00000000800030ce <bpin>:

void
bpin(struct buf *b) {
    800030ce:	1101                	addi	sp,sp,-32
    800030d0:	ec06                	sd	ra,24(sp)
    800030d2:	e822                	sd	s0,16(sp)
    800030d4:	e426                	sd	s1,8(sp)
    800030d6:	1000                	addi	s0,sp,32
    800030d8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030da:	0001b517          	auipc	a0,0x1b
    800030de:	55e50513          	addi	a0,a0,1374 # 8001e638 <bcache>
    800030e2:	ffffe097          	auipc	ra,0xffffe
    800030e6:	b66080e7          	jalr	-1178(ra) # 80000c48 <acquire>
  b->refcnt++;
    800030ea:	40bc                	lw	a5,64(s1)
    800030ec:	2785                	addiw	a5,a5,1
    800030ee:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030f0:	0001b517          	auipc	a0,0x1b
    800030f4:	54850513          	addi	a0,a0,1352 # 8001e638 <bcache>
    800030f8:	ffffe097          	auipc	ra,0xffffe
    800030fc:	c04080e7          	jalr	-1020(ra) # 80000cfc <release>
}
    80003100:	60e2                	ld	ra,24(sp)
    80003102:	6442                	ld	s0,16(sp)
    80003104:	64a2                	ld	s1,8(sp)
    80003106:	6105                	addi	sp,sp,32
    80003108:	8082                	ret

000000008000310a <bunpin>:

void
bunpin(struct buf *b) {
    8000310a:	1101                	addi	sp,sp,-32
    8000310c:	ec06                	sd	ra,24(sp)
    8000310e:	e822                	sd	s0,16(sp)
    80003110:	e426                	sd	s1,8(sp)
    80003112:	1000                	addi	s0,sp,32
    80003114:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003116:	0001b517          	auipc	a0,0x1b
    8000311a:	52250513          	addi	a0,a0,1314 # 8001e638 <bcache>
    8000311e:	ffffe097          	auipc	ra,0xffffe
    80003122:	b2a080e7          	jalr	-1238(ra) # 80000c48 <acquire>
  b->refcnt--;
    80003126:	40bc                	lw	a5,64(s1)
    80003128:	37fd                	addiw	a5,a5,-1
    8000312a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000312c:	0001b517          	auipc	a0,0x1b
    80003130:	50c50513          	addi	a0,a0,1292 # 8001e638 <bcache>
    80003134:	ffffe097          	auipc	ra,0xffffe
    80003138:	bc8080e7          	jalr	-1080(ra) # 80000cfc <release>
}
    8000313c:	60e2                	ld	ra,24(sp)
    8000313e:	6442                	ld	s0,16(sp)
    80003140:	64a2                	ld	s1,8(sp)
    80003142:	6105                	addi	sp,sp,32
    80003144:	8082                	ret

0000000080003146 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003146:	1101                	addi	sp,sp,-32
    80003148:	ec06                	sd	ra,24(sp)
    8000314a:	e822                	sd	s0,16(sp)
    8000314c:	e426                	sd	s1,8(sp)
    8000314e:	e04a                	sd	s2,0(sp)
    80003150:	1000                	addi	s0,sp,32
    80003152:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003154:	00d5d59b          	srliw	a1,a1,0xd
    80003158:	00024797          	auipc	a5,0x24
    8000315c:	bbc7a783          	lw	a5,-1092(a5) # 80026d14 <sb+0x1c>
    80003160:	9dbd                	addw	a1,a1,a5
    80003162:	00000097          	auipc	ra,0x0
    80003166:	da0080e7          	jalr	-608(ra) # 80002f02 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000316a:	0074f713          	andi	a4,s1,7
    8000316e:	4785                	li	a5,1
    80003170:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003174:	14ce                	slli	s1,s1,0x33
    80003176:	90d9                	srli	s1,s1,0x36
    80003178:	00950733          	add	a4,a0,s1
    8000317c:	05874703          	lbu	a4,88(a4)
    80003180:	00e7f6b3          	and	a3,a5,a4
    80003184:	c69d                	beqz	a3,800031b2 <bfree+0x6c>
    80003186:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003188:	94aa                	add	s1,s1,a0
    8000318a:	fff7c793          	not	a5,a5
    8000318e:	8f7d                	and	a4,a4,a5
    80003190:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003194:	00001097          	auipc	ra,0x1
    80003198:	0f6080e7          	jalr	246(ra) # 8000428a <log_write>
  brelse(bp);
    8000319c:	854a                	mv	a0,s2
    8000319e:	00000097          	auipc	ra,0x0
    800031a2:	e94080e7          	jalr	-364(ra) # 80003032 <brelse>
}
    800031a6:	60e2                	ld	ra,24(sp)
    800031a8:	6442                	ld	s0,16(sp)
    800031aa:	64a2                	ld	s1,8(sp)
    800031ac:	6902                	ld	s2,0(sp)
    800031ae:	6105                	addi	sp,sp,32
    800031b0:	8082                	ret
    panic("freeing free block");
    800031b2:	00005517          	auipc	a0,0x5
    800031b6:	38e50513          	addi	a0,a0,910 # 80008540 <syscalls+0xe8>
    800031ba:	ffffd097          	auipc	ra,0xffffd
    800031be:	386080e7          	jalr	902(ra) # 80000540 <panic>

00000000800031c2 <balloc>:
{
    800031c2:	711d                	addi	sp,sp,-96
    800031c4:	ec86                	sd	ra,88(sp)
    800031c6:	e8a2                	sd	s0,80(sp)
    800031c8:	e4a6                	sd	s1,72(sp)
    800031ca:	e0ca                	sd	s2,64(sp)
    800031cc:	fc4e                	sd	s3,56(sp)
    800031ce:	f852                	sd	s4,48(sp)
    800031d0:	f456                	sd	s5,40(sp)
    800031d2:	f05a                	sd	s6,32(sp)
    800031d4:	ec5e                	sd	s7,24(sp)
    800031d6:	e862                	sd	s8,16(sp)
    800031d8:	e466                	sd	s9,8(sp)
    800031da:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800031dc:	00024797          	auipc	a5,0x24
    800031e0:	b207a783          	lw	a5,-1248(a5) # 80026cfc <sb+0x4>
    800031e4:	cff5                	beqz	a5,800032e0 <balloc+0x11e>
    800031e6:	8baa                	mv	s7,a0
    800031e8:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800031ea:	00024b17          	auipc	s6,0x24
    800031ee:	b0eb0b13          	addi	s6,s6,-1266 # 80026cf8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031f2:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800031f4:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031f6:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800031f8:	6c89                	lui	s9,0x2
    800031fa:	a061                	j	80003282 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800031fc:	97ca                	add	a5,a5,s2
    800031fe:	8e55                	or	a2,a2,a3
    80003200:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003204:	854a                	mv	a0,s2
    80003206:	00001097          	auipc	ra,0x1
    8000320a:	084080e7          	jalr	132(ra) # 8000428a <log_write>
        brelse(bp);
    8000320e:	854a                	mv	a0,s2
    80003210:	00000097          	auipc	ra,0x0
    80003214:	e22080e7          	jalr	-478(ra) # 80003032 <brelse>
  bp = bread(dev, bno);
    80003218:	85a6                	mv	a1,s1
    8000321a:	855e                	mv	a0,s7
    8000321c:	00000097          	auipc	ra,0x0
    80003220:	ce6080e7          	jalr	-794(ra) # 80002f02 <bread>
    80003224:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003226:	40000613          	li	a2,1024
    8000322a:	4581                	li	a1,0
    8000322c:	05850513          	addi	a0,a0,88
    80003230:	ffffe097          	auipc	ra,0xffffe
    80003234:	b14080e7          	jalr	-1260(ra) # 80000d44 <memset>
  log_write(bp);
    80003238:	854a                	mv	a0,s2
    8000323a:	00001097          	auipc	ra,0x1
    8000323e:	050080e7          	jalr	80(ra) # 8000428a <log_write>
  brelse(bp);
    80003242:	854a                	mv	a0,s2
    80003244:	00000097          	auipc	ra,0x0
    80003248:	dee080e7          	jalr	-530(ra) # 80003032 <brelse>
}
    8000324c:	8526                	mv	a0,s1
    8000324e:	60e6                	ld	ra,88(sp)
    80003250:	6446                	ld	s0,80(sp)
    80003252:	64a6                	ld	s1,72(sp)
    80003254:	6906                	ld	s2,64(sp)
    80003256:	79e2                	ld	s3,56(sp)
    80003258:	7a42                	ld	s4,48(sp)
    8000325a:	7aa2                	ld	s5,40(sp)
    8000325c:	7b02                	ld	s6,32(sp)
    8000325e:	6be2                	ld	s7,24(sp)
    80003260:	6c42                	ld	s8,16(sp)
    80003262:	6ca2                	ld	s9,8(sp)
    80003264:	6125                	addi	sp,sp,96
    80003266:	8082                	ret
    brelse(bp);
    80003268:	854a                	mv	a0,s2
    8000326a:	00000097          	auipc	ra,0x0
    8000326e:	dc8080e7          	jalr	-568(ra) # 80003032 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003272:	015c87bb          	addw	a5,s9,s5
    80003276:	00078a9b          	sext.w	s5,a5
    8000327a:	004b2703          	lw	a4,4(s6)
    8000327e:	06eaf163          	bgeu	s5,a4,800032e0 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003282:	41fad79b          	sraiw	a5,s5,0x1f
    80003286:	0137d79b          	srliw	a5,a5,0x13
    8000328a:	015787bb          	addw	a5,a5,s5
    8000328e:	40d7d79b          	sraiw	a5,a5,0xd
    80003292:	01cb2583          	lw	a1,28(s6)
    80003296:	9dbd                	addw	a1,a1,a5
    80003298:	855e                	mv	a0,s7
    8000329a:	00000097          	auipc	ra,0x0
    8000329e:	c68080e7          	jalr	-920(ra) # 80002f02 <bread>
    800032a2:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032a4:	004b2503          	lw	a0,4(s6)
    800032a8:	000a849b          	sext.w	s1,s5
    800032ac:	8762                	mv	a4,s8
    800032ae:	faa4fde3          	bgeu	s1,a0,80003268 <balloc+0xa6>
      m = 1 << (bi % 8);
    800032b2:	00777693          	andi	a3,a4,7
    800032b6:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032ba:	41f7579b          	sraiw	a5,a4,0x1f
    800032be:	01d7d79b          	srliw	a5,a5,0x1d
    800032c2:	9fb9                	addw	a5,a5,a4
    800032c4:	4037d79b          	sraiw	a5,a5,0x3
    800032c8:	00f90633          	add	a2,s2,a5
    800032cc:	05864603          	lbu	a2,88(a2)
    800032d0:	00c6f5b3          	and	a1,a3,a2
    800032d4:	d585                	beqz	a1,800031fc <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032d6:	2705                	addiw	a4,a4,1
    800032d8:	2485                	addiw	s1,s1,1
    800032da:	fd471ae3          	bne	a4,s4,800032ae <balloc+0xec>
    800032de:	b769                	j	80003268 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800032e0:	00005517          	auipc	a0,0x5
    800032e4:	27850513          	addi	a0,a0,632 # 80008558 <syscalls+0x100>
    800032e8:	ffffd097          	auipc	ra,0xffffd
    800032ec:	2a2080e7          	jalr	674(ra) # 8000058a <printf>
  return 0;
    800032f0:	4481                	li	s1,0
    800032f2:	bfa9                	j	8000324c <balloc+0x8a>

00000000800032f4 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800032f4:	7179                	addi	sp,sp,-48
    800032f6:	f406                	sd	ra,40(sp)
    800032f8:	f022                	sd	s0,32(sp)
    800032fa:	ec26                	sd	s1,24(sp)
    800032fc:	e84a                	sd	s2,16(sp)
    800032fe:	e44e                	sd	s3,8(sp)
    80003300:	e052                	sd	s4,0(sp)
    80003302:	1800                	addi	s0,sp,48
    80003304:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003306:	47ad                	li	a5,11
    80003308:	02b7e863          	bltu	a5,a1,80003338 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    8000330c:	02059793          	slli	a5,a1,0x20
    80003310:	01e7d593          	srli	a1,a5,0x1e
    80003314:	00b504b3          	add	s1,a0,a1
    80003318:	0504a903          	lw	s2,80(s1)
    8000331c:	06091e63          	bnez	s2,80003398 <bmap+0xa4>
      addr = balloc(ip->dev);
    80003320:	4108                	lw	a0,0(a0)
    80003322:	00000097          	auipc	ra,0x0
    80003326:	ea0080e7          	jalr	-352(ra) # 800031c2 <balloc>
    8000332a:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000332e:	06090563          	beqz	s2,80003398 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003332:	0524a823          	sw	s2,80(s1)
    80003336:	a08d                	j	80003398 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003338:	ff45849b          	addiw	s1,a1,-12
    8000333c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003340:	0ff00793          	li	a5,255
    80003344:	08e7e563          	bltu	a5,a4,800033ce <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003348:	08052903          	lw	s2,128(a0)
    8000334c:	00091d63          	bnez	s2,80003366 <bmap+0x72>
      addr = balloc(ip->dev);
    80003350:	4108                	lw	a0,0(a0)
    80003352:	00000097          	auipc	ra,0x0
    80003356:	e70080e7          	jalr	-400(ra) # 800031c2 <balloc>
    8000335a:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000335e:	02090d63          	beqz	s2,80003398 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003362:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003366:	85ca                	mv	a1,s2
    80003368:	0009a503          	lw	a0,0(s3)
    8000336c:	00000097          	auipc	ra,0x0
    80003370:	b96080e7          	jalr	-1130(ra) # 80002f02 <bread>
    80003374:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003376:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000337a:	02049713          	slli	a4,s1,0x20
    8000337e:	01e75593          	srli	a1,a4,0x1e
    80003382:	00b784b3          	add	s1,a5,a1
    80003386:	0004a903          	lw	s2,0(s1)
    8000338a:	02090063          	beqz	s2,800033aa <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000338e:	8552                	mv	a0,s4
    80003390:	00000097          	auipc	ra,0x0
    80003394:	ca2080e7          	jalr	-862(ra) # 80003032 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003398:	854a                	mv	a0,s2
    8000339a:	70a2                	ld	ra,40(sp)
    8000339c:	7402                	ld	s0,32(sp)
    8000339e:	64e2                	ld	s1,24(sp)
    800033a0:	6942                	ld	s2,16(sp)
    800033a2:	69a2                	ld	s3,8(sp)
    800033a4:	6a02                	ld	s4,0(sp)
    800033a6:	6145                	addi	sp,sp,48
    800033a8:	8082                	ret
      addr = balloc(ip->dev);
    800033aa:	0009a503          	lw	a0,0(s3)
    800033ae:	00000097          	auipc	ra,0x0
    800033b2:	e14080e7          	jalr	-492(ra) # 800031c2 <balloc>
    800033b6:	0005091b          	sext.w	s2,a0
      if(addr){
    800033ba:	fc090ae3          	beqz	s2,8000338e <bmap+0x9a>
        a[bn] = addr;
    800033be:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800033c2:	8552                	mv	a0,s4
    800033c4:	00001097          	auipc	ra,0x1
    800033c8:	ec6080e7          	jalr	-314(ra) # 8000428a <log_write>
    800033cc:	b7c9                	j	8000338e <bmap+0x9a>
  panic("bmap: out of range");
    800033ce:	00005517          	auipc	a0,0x5
    800033d2:	1a250513          	addi	a0,a0,418 # 80008570 <syscalls+0x118>
    800033d6:	ffffd097          	auipc	ra,0xffffd
    800033da:	16a080e7          	jalr	362(ra) # 80000540 <panic>

00000000800033de <iget>:
{
    800033de:	7179                	addi	sp,sp,-48
    800033e0:	f406                	sd	ra,40(sp)
    800033e2:	f022                	sd	s0,32(sp)
    800033e4:	ec26                	sd	s1,24(sp)
    800033e6:	e84a                	sd	s2,16(sp)
    800033e8:	e44e                	sd	s3,8(sp)
    800033ea:	e052                	sd	s4,0(sp)
    800033ec:	1800                	addi	s0,sp,48
    800033ee:	89aa                	mv	s3,a0
    800033f0:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800033f2:	00024517          	auipc	a0,0x24
    800033f6:	92650513          	addi	a0,a0,-1754 # 80026d18 <itable>
    800033fa:	ffffe097          	auipc	ra,0xffffe
    800033fe:	84e080e7          	jalr	-1970(ra) # 80000c48 <acquire>
  empty = 0;
    80003402:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003404:	00024497          	auipc	s1,0x24
    80003408:	92c48493          	addi	s1,s1,-1748 # 80026d30 <itable+0x18>
    8000340c:	00025697          	auipc	a3,0x25
    80003410:	3b468693          	addi	a3,a3,948 # 800287c0 <log>
    80003414:	a039                	j	80003422 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003416:	02090b63          	beqz	s2,8000344c <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000341a:	08848493          	addi	s1,s1,136
    8000341e:	02d48a63          	beq	s1,a3,80003452 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003422:	449c                	lw	a5,8(s1)
    80003424:	fef059e3          	blez	a5,80003416 <iget+0x38>
    80003428:	4098                	lw	a4,0(s1)
    8000342a:	ff3716e3          	bne	a4,s3,80003416 <iget+0x38>
    8000342e:	40d8                	lw	a4,4(s1)
    80003430:	ff4713e3          	bne	a4,s4,80003416 <iget+0x38>
      ip->ref++;
    80003434:	2785                	addiw	a5,a5,1
    80003436:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003438:	00024517          	auipc	a0,0x24
    8000343c:	8e050513          	addi	a0,a0,-1824 # 80026d18 <itable>
    80003440:	ffffe097          	auipc	ra,0xffffe
    80003444:	8bc080e7          	jalr	-1860(ra) # 80000cfc <release>
      return ip;
    80003448:	8926                	mv	s2,s1
    8000344a:	a03d                	j	80003478 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000344c:	f7f9                	bnez	a5,8000341a <iget+0x3c>
    8000344e:	8926                	mv	s2,s1
    80003450:	b7e9                	j	8000341a <iget+0x3c>
  if(empty == 0)
    80003452:	02090c63          	beqz	s2,8000348a <iget+0xac>
  ip->dev = dev;
    80003456:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000345a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000345e:	4785                	li	a5,1
    80003460:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003464:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003468:	00024517          	auipc	a0,0x24
    8000346c:	8b050513          	addi	a0,a0,-1872 # 80026d18 <itable>
    80003470:	ffffe097          	auipc	ra,0xffffe
    80003474:	88c080e7          	jalr	-1908(ra) # 80000cfc <release>
}
    80003478:	854a                	mv	a0,s2
    8000347a:	70a2                	ld	ra,40(sp)
    8000347c:	7402                	ld	s0,32(sp)
    8000347e:	64e2                	ld	s1,24(sp)
    80003480:	6942                	ld	s2,16(sp)
    80003482:	69a2                	ld	s3,8(sp)
    80003484:	6a02                	ld	s4,0(sp)
    80003486:	6145                	addi	sp,sp,48
    80003488:	8082                	ret
    panic("iget: no inodes");
    8000348a:	00005517          	auipc	a0,0x5
    8000348e:	0fe50513          	addi	a0,a0,254 # 80008588 <syscalls+0x130>
    80003492:	ffffd097          	auipc	ra,0xffffd
    80003496:	0ae080e7          	jalr	174(ra) # 80000540 <panic>

000000008000349a <fsinit>:
fsinit(int dev) {
    8000349a:	7179                	addi	sp,sp,-48
    8000349c:	f406                	sd	ra,40(sp)
    8000349e:	f022                	sd	s0,32(sp)
    800034a0:	ec26                	sd	s1,24(sp)
    800034a2:	e84a                	sd	s2,16(sp)
    800034a4:	e44e                	sd	s3,8(sp)
    800034a6:	1800                	addi	s0,sp,48
    800034a8:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034aa:	4585                	li	a1,1
    800034ac:	00000097          	auipc	ra,0x0
    800034b0:	a56080e7          	jalr	-1450(ra) # 80002f02 <bread>
    800034b4:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034b6:	00024997          	auipc	s3,0x24
    800034ba:	84298993          	addi	s3,s3,-1982 # 80026cf8 <sb>
    800034be:	02000613          	li	a2,32
    800034c2:	05850593          	addi	a1,a0,88
    800034c6:	854e                	mv	a0,s3
    800034c8:	ffffe097          	auipc	ra,0xffffe
    800034cc:	8d8080e7          	jalr	-1832(ra) # 80000da0 <memmove>
  brelse(bp);
    800034d0:	8526                	mv	a0,s1
    800034d2:	00000097          	auipc	ra,0x0
    800034d6:	b60080e7          	jalr	-1184(ra) # 80003032 <brelse>
  if(sb.magic != FSMAGIC)
    800034da:	0009a703          	lw	a4,0(s3)
    800034de:	102037b7          	lui	a5,0x10203
    800034e2:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800034e6:	02f71263          	bne	a4,a5,8000350a <fsinit+0x70>
  initlog(dev, &sb);
    800034ea:	00024597          	auipc	a1,0x24
    800034ee:	80e58593          	addi	a1,a1,-2034 # 80026cf8 <sb>
    800034f2:	854a                	mv	a0,s2
    800034f4:	00001097          	auipc	ra,0x1
    800034f8:	b2c080e7          	jalr	-1236(ra) # 80004020 <initlog>
}
    800034fc:	70a2                	ld	ra,40(sp)
    800034fe:	7402                	ld	s0,32(sp)
    80003500:	64e2                	ld	s1,24(sp)
    80003502:	6942                	ld	s2,16(sp)
    80003504:	69a2                	ld	s3,8(sp)
    80003506:	6145                	addi	sp,sp,48
    80003508:	8082                	ret
    panic("invalid file system");
    8000350a:	00005517          	auipc	a0,0x5
    8000350e:	08e50513          	addi	a0,a0,142 # 80008598 <syscalls+0x140>
    80003512:	ffffd097          	auipc	ra,0xffffd
    80003516:	02e080e7          	jalr	46(ra) # 80000540 <panic>

000000008000351a <iinit>:
{
    8000351a:	7179                	addi	sp,sp,-48
    8000351c:	f406                	sd	ra,40(sp)
    8000351e:	f022                	sd	s0,32(sp)
    80003520:	ec26                	sd	s1,24(sp)
    80003522:	e84a                	sd	s2,16(sp)
    80003524:	e44e                	sd	s3,8(sp)
    80003526:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003528:	00005597          	auipc	a1,0x5
    8000352c:	08858593          	addi	a1,a1,136 # 800085b0 <syscalls+0x158>
    80003530:	00023517          	auipc	a0,0x23
    80003534:	7e850513          	addi	a0,a0,2024 # 80026d18 <itable>
    80003538:	ffffd097          	auipc	ra,0xffffd
    8000353c:	680080e7          	jalr	1664(ra) # 80000bb8 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003540:	00024497          	auipc	s1,0x24
    80003544:	80048493          	addi	s1,s1,-2048 # 80026d40 <itable+0x28>
    80003548:	00025997          	auipc	s3,0x25
    8000354c:	28898993          	addi	s3,s3,648 # 800287d0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003550:	00005917          	auipc	s2,0x5
    80003554:	06890913          	addi	s2,s2,104 # 800085b8 <syscalls+0x160>
    80003558:	85ca                	mv	a1,s2
    8000355a:	8526                	mv	a0,s1
    8000355c:	00001097          	auipc	ra,0x1
    80003560:	e12080e7          	jalr	-494(ra) # 8000436e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003564:	08848493          	addi	s1,s1,136
    80003568:	ff3498e3          	bne	s1,s3,80003558 <iinit+0x3e>
}
    8000356c:	70a2                	ld	ra,40(sp)
    8000356e:	7402                	ld	s0,32(sp)
    80003570:	64e2                	ld	s1,24(sp)
    80003572:	6942                	ld	s2,16(sp)
    80003574:	69a2                	ld	s3,8(sp)
    80003576:	6145                	addi	sp,sp,48
    80003578:	8082                	ret

000000008000357a <ialloc>:
{
    8000357a:	7139                	addi	sp,sp,-64
    8000357c:	fc06                	sd	ra,56(sp)
    8000357e:	f822                	sd	s0,48(sp)
    80003580:	f426                	sd	s1,40(sp)
    80003582:	f04a                	sd	s2,32(sp)
    80003584:	ec4e                	sd	s3,24(sp)
    80003586:	e852                	sd	s4,16(sp)
    80003588:	e456                	sd	s5,8(sp)
    8000358a:	e05a                	sd	s6,0(sp)
    8000358c:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    8000358e:	00023717          	auipc	a4,0x23
    80003592:	77672703          	lw	a4,1910(a4) # 80026d04 <sb+0xc>
    80003596:	4785                	li	a5,1
    80003598:	04e7f863          	bgeu	a5,a4,800035e8 <ialloc+0x6e>
    8000359c:	8aaa                	mv	s5,a0
    8000359e:	8b2e                	mv	s6,a1
    800035a0:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035a2:	00023a17          	auipc	s4,0x23
    800035a6:	756a0a13          	addi	s4,s4,1878 # 80026cf8 <sb>
    800035aa:	00495593          	srli	a1,s2,0x4
    800035ae:	018a2783          	lw	a5,24(s4)
    800035b2:	9dbd                	addw	a1,a1,a5
    800035b4:	8556                	mv	a0,s5
    800035b6:	00000097          	auipc	ra,0x0
    800035ba:	94c080e7          	jalr	-1716(ra) # 80002f02 <bread>
    800035be:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035c0:	05850993          	addi	s3,a0,88
    800035c4:	00f97793          	andi	a5,s2,15
    800035c8:	079a                	slli	a5,a5,0x6
    800035ca:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035cc:	00099783          	lh	a5,0(s3)
    800035d0:	cf9d                	beqz	a5,8000360e <ialloc+0x94>
    brelse(bp);
    800035d2:	00000097          	auipc	ra,0x0
    800035d6:	a60080e7          	jalr	-1440(ra) # 80003032 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800035da:	0905                	addi	s2,s2,1
    800035dc:	00ca2703          	lw	a4,12(s4)
    800035e0:	0009079b          	sext.w	a5,s2
    800035e4:	fce7e3e3          	bltu	a5,a4,800035aa <ialloc+0x30>
  printf("ialloc: no inodes\n");
    800035e8:	00005517          	auipc	a0,0x5
    800035ec:	fd850513          	addi	a0,a0,-40 # 800085c0 <syscalls+0x168>
    800035f0:	ffffd097          	auipc	ra,0xffffd
    800035f4:	f9a080e7          	jalr	-102(ra) # 8000058a <printf>
  return 0;
    800035f8:	4501                	li	a0,0
}
    800035fa:	70e2                	ld	ra,56(sp)
    800035fc:	7442                	ld	s0,48(sp)
    800035fe:	74a2                	ld	s1,40(sp)
    80003600:	7902                	ld	s2,32(sp)
    80003602:	69e2                	ld	s3,24(sp)
    80003604:	6a42                	ld	s4,16(sp)
    80003606:	6aa2                	ld	s5,8(sp)
    80003608:	6b02                	ld	s6,0(sp)
    8000360a:	6121                	addi	sp,sp,64
    8000360c:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000360e:	04000613          	li	a2,64
    80003612:	4581                	li	a1,0
    80003614:	854e                	mv	a0,s3
    80003616:	ffffd097          	auipc	ra,0xffffd
    8000361a:	72e080e7          	jalr	1838(ra) # 80000d44 <memset>
      dip->type = type;
    8000361e:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003622:	8526                	mv	a0,s1
    80003624:	00001097          	auipc	ra,0x1
    80003628:	c66080e7          	jalr	-922(ra) # 8000428a <log_write>
      brelse(bp);
    8000362c:	8526                	mv	a0,s1
    8000362e:	00000097          	auipc	ra,0x0
    80003632:	a04080e7          	jalr	-1532(ra) # 80003032 <brelse>
      return iget(dev, inum);
    80003636:	0009059b          	sext.w	a1,s2
    8000363a:	8556                	mv	a0,s5
    8000363c:	00000097          	auipc	ra,0x0
    80003640:	da2080e7          	jalr	-606(ra) # 800033de <iget>
    80003644:	bf5d                	j	800035fa <ialloc+0x80>

0000000080003646 <iupdate>:
{
    80003646:	1101                	addi	sp,sp,-32
    80003648:	ec06                	sd	ra,24(sp)
    8000364a:	e822                	sd	s0,16(sp)
    8000364c:	e426                	sd	s1,8(sp)
    8000364e:	e04a                	sd	s2,0(sp)
    80003650:	1000                	addi	s0,sp,32
    80003652:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003654:	415c                	lw	a5,4(a0)
    80003656:	0047d79b          	srliw	a5,a5,0x4
    8000365a:	00023597          	auipc	a1,0x23
    8000365e:	6b65a583          	lw	a1,1718(a1) # 80026d10 <sb+0x18>
    80003662:	9dbd                	addw	a1,a1,a5
    80003664:	4108                	lw	a0,0(a0)
    80003666:	00000097          	auipc	ra,0x0
    8000366a:	89c080e7          	jalr	-1892(ra) # 80002f02 <bread>
    8000366e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003670:	05850793          	addi	a5,a0,88
    80003674:	40d8                	lw	a4,4(s1)
    80003676:	8b3d                	andi	a4,a4,15
    80003678:	071a                	slli	a4,a4,0x6
    8000367a:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    8000367c:	04449703          	lh	a4,68(s1)
    80003680:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003684:	04649703          	lh	a4,70(s1)
    80003688:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    8000368c:	04849703          	lh	a4,72(s1)
    80003690:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003694:	04a49703          	lh	a4,74(s1)
    80003698:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    8000369c:	44f8                	lw	a4,76(s1)
    8000369e:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036a0:	03400613          	li	a2,52
    800036a4:	05048593          	addi	a1,s1,80
    800036a8:	00c78513          	addi	a0,a5,12
    800036ac:	ffffd097          	auipc	ra,0xffffd
    800036b0:	6f4080e7          	jalr	1780(ra) # 80000da0 <memmove>
  log_write(bp);
    800036b4:	854a                	mv	a0,s2
    800036b6:	00001097          	auipc	ra,0x1
    800036ba:	bd4080e7          	jalr	-1068(ra) # 8000428a <log_write>
  brelse(bp);
    800036be:	854a                	mv	a0,s2
    800036c0:	00000097          	auipc	ra,0x0
    800036c4:	972080e7          	jalr	-1678(ra) # 80003032 <brelse>
}
    800036c8:	60e2                	ld	ra,24(sp)
    800036ca:	6442                	ld	s0,16(sp)
    800036cc:	64a2                	ld	s1,8(sp)
    800036ce:	6902                	ld	s2,0(sp)
    800036d0:	6105                	addi	sp,sp,32
    800036d2:	8082                	ret

00000000800036d4 <idup>:
{
    800036d4:	1101                	addi	sp,sp,-32
    800036d6:	ec06                	sd	ra,24(sp)
    800036d8:	e822                	sd	s0,16(sp)
    800036da:	e426                	sd	s1,8(sp)
    800036dc:	1000                	addi	s0,sp,32
    800036de:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800036e0:	00023517          	auipc	a0,0x23
    800036e4:	63850513          	addi	a0,a0,1592 # 80026d18 <itable>
    800036e8:	ffffd097          	auipc	ra,0xffffd
    800036ec:	560080e7          	jalr	1376(ra) # 80000c48 <acquire>
  ip->ref++;
    800036f0:	449c                	lw	a5,8(s1)
    800036f2:	2785                	addiw	a5,a5,1
    800036f4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800036f6:	00023517          	auipc	a0,0x23
    800036fa:	62250513          	addi	a0,a0,1570 # 80026d18 <itable>
    800036fe:	ffffd097          	auipc	ra,0xffffd
    80003702:	5fe080e7          	jalr	1534(ra) # 80000cfc <release>
}
    80003706:	8526                	mv	a0,s1
    80003708:	60e2                	ld	ra,24(sp)
    8000370a:	6442                	ld	s0,16(sp)
    8000370c:	64a2                	ld	s1,8(sp)
    8000370e:	6105                	addi	sp,sp,32
    80003710:	8082                	ret

0000000080003712 <ilock>:
{
    80003712:	1101                	addi	sp,sp,-32
    80003714:	ec06                	sd	ra,24(sp)
    80003716:	e822                	sd	s0,16(sp)
    80003718:	e426                	sd	s1,8(sp)
    8000371a:	e04a                	sd	s2,0(sp)
    8000371c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000371e:	c115                	beqz	a0,80003742 <ilock+0x30>
    80003720:	84aa                	mv	s1,a0
    80003722:	451c                	lw	a5,8(a0)
    80003724:	00f05f63          	blez	a5,80003742 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003728:	0541                	addi	a0,a0,16
    8000372a:	00001097          	auipc	ra,0x1
    8000372e:	c7e080e7          	jalr	-898(ra) # 800043a8 <acquiresleep>
  if(ip->valid == 0){
    80003732:	40bc                	lw	a5,64(s1)
    80003734:	cf99                	beqz	a5,80003752 <ilock+0x40>
}
    80003736:	60e2                	ld	ra,24(sp)
    80003738:	6442                	ld	s0,16(sp)
    8000373a:	64a2                	ld	s1,8(sp)
    8000373c:	6902                	ld	s2,0(sp)
    8000373e:	6105                	addi	sp,sp,32
    80003740:	8082                	ret
    panic("ilock");
    80003742:	00005517          	auipc	a0,0x5
    80003746:	e9650513          	addi	a0,a0,-362 # 800085d8 <syscalls+0x180>
    8000374a:	ffffd097          	auipc	ra,0xffffd
    8000374e:	df6080e7          	jalr	-522(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003752:	40dc                	lw	a5,4(s1)
    80003754:	0047d79b          	srliw	a5,a5,0x4
    80003758:	00023597          	auipc	a1,0x23
    8000375c:	5b85a583          	lw	a1,1464(a1) # 80026d10 <sb+0x18>
    80003760:	9dbd                	addw	a1,a1,a5
    80003762:	4088                	lw	a0,0(s1)
    80003764:	fffff097          	auipc	ra,0xfffff
    80003768:	79e080e7          	jalr	1950(ra) # 80002f02 <bread>
    8000376c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000376e:	05850593          	addi	a1,a0,88
    80003772:	40dc                	lw	a5,4(s1)
    80003774:	8bbd                	andi	a5,a5,15
    80003776:	079a                	slli	a5,a5,0x6
    80003778:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000377a:	00059783          	lh	a5,0(a1)
    8000377e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003782:	00259783          	lh	a5,2(a1)
    80003786:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000378a:	00459783          	lh	a5,4(a1)
    8000378e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003792:	00659783          	lh	a5,6(a1)
    80003796:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000379a:	459c                	lw	a5,8(a1)
    8000379c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000379e:	03400613          	li	a2,52
    800037a2:	05b1                	addi	a1,a1,12
    800037a4:	05048513          	addi	a0,s1,80
    800037a8:	ffffd097          	auipc	ra,0xffffd
    800037ac:	5f8080e7          	jalr	1528(ra) # 80000da0 <memmove>
    brelse(bp);
    800037b0:	854a                	mv	a0,s2
    800037b2:	00000097          	auipc	ra,0x0
    800037b6:	880080e7          	jalr	-1920(ra) # 80003032 <brelse>
    ip->valid = 1;
    800037ba:	4785                	li	a5,1
    800037bc:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037be:	04449783          	lh	a5,68(s1)
    800037c2:	fbb5                	bnez	a5,80003736 <ilock+0x24>
      panic("ilock: no type");
    800037c4:	00005517          	auipc	a0,0x5
    800037c8:	e1c50513          	addi	a0,a0,-484 # 800085e0 <syscalls+0x188>
    800037cc:	ffffd097          	auipc	ra,0xffffd
    800037d0:	d74080e7          	jalr	-652(ra) # 80000540 <panic>

00000000800037d4 <iunlock>:
{
    800037d4:	1101                	addi	sp,sp,-32
    800037d6:	ec06                	sd	ra,24(sp)
    800037d8:	e822                	sd	s0,16(sp)
    800037da:	e426                	sd	s1,8(sp)
    800037dc:	e04a                	sd	s2,0(sp)
    800037de:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800037e0:	c905                	beqz	a0,80003810 <iunlock+0x3c>
    800037e2:	84aa                	mv	s1,a0
    800037e4:	01050913          	addi	s2,a0,16
    800037e8:	854a                	mv	a0,s2
    800037ea:	00001097          	auipc	ra,0x1
    800037ee:	c58080e7          	jalr	-936(ra) # 80004442 <holdingsleep>
    800037f2:	cd19                	beqz	a0,80003810 <iunlock+0x3c>
    800037f4:	449c                	lw	a5,8(s1)
    800037f6:	00f05d63          	blez	a5,80003810 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800037fa:	854a                	mv	a0,s2
    800037fc:	00001097          	auipc	ra,0x1
    80003800:	c02080e7          	jalr	-1022(ra) # 800043fe <releasesleep>
}
    80003804:	60e2                	ld	ra,24(sp)
    80003806:	6442                	ld	s0,16(sp)
    80003808:	64a2                	ld	s1,8(sp)
    8000380a:	6902                	ld	s2,0(sp)
    8000380c:	6105                	addi	sp,sp,32
    8000380e:	8082                	ret
    panic("iunlock");
    80003810:	00005517          	auipc	a0,0x5
    80003814:	de050513          	addi	a0,a0,-544 # 800085f0 <syscalls+0x198>
    80003818:	ffffd097          	auipc	ra,0xffffd
    8000381c:	d28080e7          	jalr	-728(ra) # 80000540 <panic>

0000000080003820 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003820:	7179                	addi	sp,sp,-48
    80003822:	f406                	sd	ra,40(sp)
    80003824:	f022                	sd	s0,32(sp)
    80003826:	ec26                	sd	s1,24(sp)
    80003828:	e84a                	sd	s2,16(sp)
    8000382a:	e44e                	sd	s3,8(sp)
    8000382c:	e052                	sd	s4,0(sp)
    8000382e:	1800                	addi	s0,sp,48
    80003830:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003832:	05050493          	addi	s1,a0,80
    80003836:	08050913          	addi	s2,a0,128
    8000383a:	a021                	j	80003842 <itrunc+0x22>
    8000383c:	0491                	addi	s1,s1,4
    8000383e:	01248d63          	beq	s1,s2,80003858 <itrunc+0x38>
    if(ip->addrs[i]){
    80003842:	408c                	lw	a1,0(s1)
    80003844:	dde5                	beqz	a1,8000383c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003846:	0009a503          	lw	a0,0(s3)
    8000384a:	00000097          	auipc	ra,0x0
    8000384e:	8fc080e7          	jalr	-1796(ra) # 80003146 <bfree>
      ip->addrs[i] = 0;
    80003852:	0004a023          	sw	zero,0(s1)
    80003856:	b7dd                	j	8000383c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003858:	0809a583          	lw	a1,128(s3)
    8000385c:	e185                	bnez	a1,8000387c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000385e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003862:	854e                	mv	a0,s3
    80003864:	00000097          	auipc	ra,0x0
    80003868:	de2080e7          	jalr	-542(ra) # 80003646 <iupdate>
}
    8000386c:	70a2                	ld	ra,40(sp)
    8000386e:	7402                	ld	s0,32(sp)
    80003870:	64e2                	ld	s1,24(sp)
    80003872:	6942                	ld	s2,16(sp)
    80003874:	69a2                	ld	s3,8(sp)
    80003876:	6a02                	ld	s4,0(sp)
    80003878:	6145                	addi	sp,sp,48
    8000387a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000387c:	0009a503          	lw	a0,0(s3)
    80003880:	fffff097          	auipc	ra,0xfffff
    80003884:	682080e7          	jalr	1666(ra) # 80002f02 <bread>
    80003888:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000388a:	05850493          	addi	s1,a0,88
    8000388e:	45850913          	addi	s2,a0,1112
    80003892:	a021                	j	8000389a <itrunc+0x7a>
    80003894:	0491                	addi	s1,s1,4
    80003896:	01248b63          	beq	s1,s2,800038ac <itrunc+0x8c>
      if(a[j])
    8000389a:	408c                	lw	a1,0(s1)
    8000389c:	dde5                	beqz	a1,80003894 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    8000389e:	0009a503          	lw	a0,0(s3)
    800038a2:	00000097          	auipc	ra,0x0
    800038a6:	8a4080e7          	jalr	-1884(ra) # 80003146 <bfree>
    800038aa:	b7ed                	j	80003894 <itrunc+0x74>
    brelse(bp);
    800038ac:	8552                	mv	a0,s4
    800038ae:	fffff097          	auipc	ra,0xfffff
    800038b2:	784080e7          	jalr	1924(ra) # 80003032 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038b6:	0809a583          	lw	a1,128(s3)
    800038ba:	0009a503          	lw	a0,0(s3)
    800038be:	00000097          	auipc	ra,0x0
    800038c2:	888080e7          	jalr	-1912(ra) # 80003146 <bfree>
    ip->addrs[NDIRECT] = 0;
    800038c6:	0809a023          	sw	zero,128(s3)
    800038ca:	bf51                	j	8000385e <itrunc+0x3e>

00000000800038cc <iput>:
{
    800038cc:	1101                	addi	sp,sp,-32
    800038ce:	ec06                	sd	ra,24(sp)
    800038d0:	e822                	sd	s0,16(sp)
    800038d2:	e426                	sd	s1,8(sp)
    800038d4:	e04a                	sd	s2,0(sp)
    800038d6:	1000                	addi	s0,sp,32
    800038d8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038da:	00023517          	auipc	a0,0x23
    800038de:	43e50513          	addi	a0,a0,1086 # 80026d18 <itable>
    800038e2:	ffffd097          	auipc	ra,0xffffd
    800038e6:	366080e7          	jalr	870(ra) # 80000c48 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038ea:	4498                	lw	a4,8(s1)
    800038ec:	4785                	li	a5,1
    800038ee:	02f70363          	beq	a4,a5,80003914 <iput+0x48>
  ip->ref--;
    800038f2:	449c                	lw	a5,8(s1)
    800038f4:	37fd                	addiw	a5,a5,-1
    800038f6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038f8:	00023517          	auipc	a0,0x23
    800038fc:	42050513          	addi	a0,a0,1056 # 80026d18 <itable>
    80003900:	ffffd097          	auipc	ra,0xffffd
    80003904:	3fc080e7          	jalr	1020(ra) # 80000cfc <release>
}
    80003908:	60e2                	ld	ra,24(sp)
    8000390a:	6442                	ld	s0,16(sp)
    8000390c:	64a2                	ld	s1,8(sp)
    8000390e:	6902                	ld	s2,0(sp)
    80003910:	6105                	addi	sp,sp,32
    80003912:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003914:	40bc                	lw	a5,64(s1)
    80003916:	dff1                	beqz	a5,800038f2 <iput+0x26>
    80003918:	04a49783          	lh	a5,74(s1)
    8000391c:	fbf9                	bnez	a5,800038f2 <iput+0x26>
    acquiresleep(&ip->lock);
    8000391e:	01048913          	addi	s2,s1,16
    80003922:	854a                	mv	a0,s2
    80003924:	00001097          	auipc	ra,0x1
    80003928:	a84080e7          	jalr	-1404(ra) # 800043a8 <acquiresleep>
    release(&itable.lock);
    8000392c:	00023517          	auipc	a0,0x23
    80003930:	3ec50513          	addi	a0,a0,1004 # 80026d18 <itable>
    80003934:	ffffd097          	auipc	ra,0xffffd
    80003938:	3c8080e7          	jalr	968(ra) # 80000cfc <release>
    itrunc(ip);
    8000393c:	8526                	mv	a0,s1
    8000393e:	00000097          	auipc	ra,0x0
    80003942:	ee2080e7          	jalr	-286(ra) # 80003820 <itrunc>
    ip->type = 0;
    80003946:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000394a:	8526                	mv	a0,s1
    8000394c:	00000097          	auipc	ra,0x0
    80003950:	cfa080e7          	jalr	-774(ra) # 80003646 <iupdate>
    ip->valid = 0;
    80003954:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003958:	854a                	mv	a0,s2
    8000395a:	00001097          	auipc	ra,0x1
    8000395e:	aa4080e7          	jalr	-1372(ra) # 800043fe <releasesleep>
    acquire(&itable.lock);
    80003962:	00023517          	auipc	a0,0x23
    80003966:	3b650513          	addi	a0,a0,950 # 80026d18 <itable>
    8000396a:	ffffd097          	auipc	ra,0xffffd
    8000396e:	2de080e7          	jalr	734(ra) # 80000c48 <acquire>
    80003972:	b741                	j	800038f2 <iput+0x26>

0000000080003974 <iunlockput>:
{
    80003974:	1101                	addi	sp,sp,-32
    80003976:	ec06                	sd	ra,24(sp)
    80003978:	e822                	sd	s0,16(sp)
    8000397a:	e426                	sd	s1,8(sp)
    8000397c:	1000                	addi	s0,sp,32
    8000397e:	84aa                	mv	s1,a0
  iunlock(ip);
    80003980:	00000097          	auipc	ra,0x0
    80003984:	e54080e7          	jalr	-428(ra) # 800037d4 <iunlock>
  iput(ip);
    80003988:	8526                	mv	a0,s1
    8000398a:	00000097          	auipc	ra,0x0
    8000398e:	f42080e7          	jalr	-190(ra) # 800038cc <iput>
}
    80003992:	60e2                	ld	ra,24(sp)
    80003994:	6442                	ld	s0,16(sp)
    80003996:	64a2                	ld	s1,8(sp)
    80003998:	6105                	addi	sp,sp,32
    8000399a:	8082                	ret

000000008000399c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000399c:	1141                	addi	sp,sp,-16
    8000399e:	e422                	sd	s0,8(sp)
    800039a0:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039a2:	411c                	lw	a5,0(a0)
    800039a4:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039a6:	415c                	lw	a5,4(a0)
    800039a8:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039aa:	04451783          	lh	a5,68(a0)
    800039ae:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039b2:	04a51783          	lh	a5,74(a0)
    800039b6:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039ba:	04c56783          	lwu	a5,76(a0)
    800039be:	e99c                	sd	a5,16(a1)
}
    800039c0:	6422                	ld	s0,8(sp)
    800039c2:	0141                	addi	sp,sp,16
    800039c4:	8082                	ret

00000000800039c6 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039c6:	457c                	lw	a5,76(a0)
    800039c8:	0ed7e963          	bltu	a5,a3,80003aba <readi+0xf4>
{
    800039cc:	7159                	addi	sp,sp,-112
    800039ce:	f486                	sd	ra,104(sp)
    800039d0:	f0a2                	sd	s0,96(sp)
    800039d2:	eca6                	sd	s1,88(sp)
    800039d4:	e8ca                	sd	s2,80(sp)
    800039d6:	e4ce                	sd	s3,72(sp)
    800039d8:	e0d2                	sd	s4,64(sp)
    800039da:	fc56                	sd	s5,56(sp)
    800039dc:	f85a                	sd	s6,48(sp)
    800039de:	f45e                	sd	s7,40(sp)
    800039e0:	f062                	sd	s8,32(sp)
    800039e2:	ec66                	sd	s9,24(sp)
    800039e4:	e86a                	sd	s10,16(sp)
    800039e6:	e46e                	sd	s11,8(sp)
    800039e8:	1880                	addi	s0,sp,112
    800039ea:	8b2a                	mv	s6,a0
    800039ec:	8bae                	mv	s7,a1
    800039ee:	8a32                	mv	s4,a2
    800039f0:	84b6                	mv	s1,a3
    800039f2:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    800039f4:	9f35                	addw	a4,a4,a3
    return 0;
    800039f6:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800039f8:	0ad76063          	bltu	a4,a3,80003a98 <readi+0xd2>
  if(off + n > ip->size)
    800039fc:	00e7f463          	bgeu	a5,a4,80003a04 <readi+0x3e>
    n = ip->size - off;
    80003a00:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a04:	0a0a8963          	beqz	s5,80003ab6 <readi+0xf0>
    80003a08:	4981                	li	s3,0
#if 0
    // Adil: Remove later
    printf("ip->dev; %d\n", ip->dev);
#endif

    m = min(n - tot, BSIZE - off%BSIZE);
    80003a0a:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a0e:	5c7d                	li	s8,-1
    80003a10:	a82d                	j	80003a4a <readi+0x84>
    80003a12:	020d1d93          	slli	s11,s10,0x20
    80003a16:	020ddd93          	srli	s11,s11,0x20
    80003a1a:	05890613          	addi	a2,s2,88
    80003a1e:	86ee                	mv	a3,s11
    80003a20:	963a                	add	a2,a2,a4
    80003a22:	85d2                	mv	a1,s4
    80003a24:	855e                	mv	a0,s7
    80003a26:	fffff097          	auipc	ra,0xfffff
    80003a2a:	ae8080e7          	jalr	-1304(ra) # 8000250e <either_copyout>
    80003a2e:	05850d63          	beq	a0,s8,80003a88 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a32:	854a                	mv	a0,s2
    80003a34:	fffff097          	auipc	ra,0xfffff
    80003a38:	5fe080e7          	jalr	1534(ra) # 80003032 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a3c:	013d09bb          	addw	s3,s10,s3
    80003a40:	009d04bb          	addw	s1,s10,s1
    80003a44:	9a6e                	add	s4,s4,s11
    80003a46:	0559f763          	bgeu	s3,s5,80003a94 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003a4a:	00a4d59b          	srliw	a1,s1,0xa
    80003a4e:	855a                	mv	a0,s6
    80003a50:	00000097          	auipc	ra,0x0
    80003a54:	8a4080e7          	jalr	-1884(ra) # 800032f4 <bmap>
    80003a58:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003a5c:	cd85                	beqz	a1,80003a94 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003a5e:	000b2503          	lw	a0,0(s6)
    80003a62:	fffff097          	auipc	ra,0xfffff
    80003a66:	4a0080e7          	jalr	1184(ra) # 80002f02 <bread>
    80003a6a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a6c:	3ff4f713          	andi	a4,s1,1023
    80003a70:	40ec87bb          	subw	a5,s9,a4
    80003a74:	413a86bb          	subw	a3,s5,s3
    80003a78:	8d3e                	mv	s10,a5
    80003a7a:	2781                	sext.w	a5,a5
    80003a7c:	0006861b          	sext.w	a2,a3
    80003a80:	f8f679e3          	bgeu	a2,a5,80003a12 <readi+0x4c>
    80003a84:	8d36                	mv	s10,a3
    80003a86:	b771                	j	80003a12 <readi+0x4c>
      brelse(bp);
    80003a88:	854a                	mv	a0,s2
    80003a8a:	fffff097          	auipc	ra,0xfffff
    80003a8e:	5a8080e7          	jalr	1448(ra) # 80003032 <brelse>
      tot = -1;
    80003a92:	59fd                	li	s3,-1
  }
  return tot;
    80003a94:	0009851b          	sext.w	a0,s3
}
    80003a98:	70a6                	ld	ra,104(sp)
    80003a9a:	7406                	ld	s0,96(sp)
    80003a9c:	64e6                	ld	s1,88(sp)
    80003a9e:	6946                	ld	s2,80(sp)
    80003aa0:	69a6                	ld	s3,72(sp)
    80003aa2:	6a06                	ld	s4,64(sp)
    80003aa4:	7ae2                	ld	s5,56(sp)
    80003aa6:	7b42                	ld	s6,48(sp)
    80003aa8:	7ba2                	ld	s7,40(sp)
    80003aaa:	7c02                	ld	s8,32(sp)
    80003aac:	6ce2                	ld	s9,24(sp)
    80003aae:	6d42                	ld	s10,16(sp)
    80003ab0:	6da2                	ld	s11,8(sp)
    80003ab2:	6165                	addi	sp,sp,112
    80003ab4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ab6:	89d6                	mv	s3,s5
    80003ab8:	bff1                	j	80003a94 <readi+0xce>
    return 0;
    80003aba:	4501                	li	a0,0
}
    80003abc:	8082                	ret

0000000080003abe <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003abe:	457c                	lw	a5,76(a0)
    80003ac0:	10d7e863          	bltu	a5,a3,80003bd0 <writei+0x112>
{
    80003ac4:	7159                	addi	sp,sp,-112
    80003ac6:	f486                	sd	ra,104(sp)
    80003ac8:	f0a2                	sd	s0,96(sp)
    80003aca:	eca6                	sd	s1,88(sp)
    80003acc:	e8ca                	sd	s2,80(sp)
    80003ace:	e4ce                	sd	s3,72(sp)
    80003ad0:	e0d2                	sd	s4,64(sp)
    80003ad2:	fc56                	sd	s5,56(sp)
    80003ad4:	f85a                	sd	s6,48(sp)
    80003ad6:	f45e                	sd	s7,40(sp)
    80003ad8:	f062                	sd	s8,32(sp)
    80003ada:	ec66                	sd	s9,24(sp)
    80003adc:	e86a                	sd	s10,16(sp)
    80003ade:	e46e                	sd	s11,8(sp)
    80003ae0:	1880                	addi	s0,sp,112
    80003ae2:	8aaa                	mv	s5,a0
    80003ae4:	8bae                	mv	s7,a1
    80003ae6:	8a32                	mv	s4,a2
    80003ae8:	8936                	mv	s2,a3
    80003aea:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003aec:	00e687bb          	addw	a5,a3,a4
    80003af0:	0ed7e263          	bltu	a5,a3,80003bd4 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003af4:	00043737          	lui	a4,0x43
    80003af8:	0ef76063          	bltu	a4,a5,80003bd8 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003afc:	0c0b0863          	beqz	s6,80003bcc <writei+0x10e>
    80003b00:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b02:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b06:	5c7d                	li	s8,-1
    80003b08:	a091                	j	80003b4c <writei+0x8e>
    80003b0a:	020d1d93          	slli	s11,s10,0x20
    80003b0e:	020ddd93          	srli	s11,s11,0x20
    80003b12:	05848513          	addi	a0,s1,88
    80003b16:	86ee                	mv	a3,s11
    80003b18:	8652                	mv	a2,s4
    80003b1a:	85de                	mv	a1,s7
    80003b1c:	953a                	add	a0,a0,a4
    80003b1e:	fffff097          	auipc	ra,0xfffff
    80003b22:	a46080e7          	jalr	-1466(ra) # 80002564 <either_copyin>
    80003b26:	07850263          	beq	a0,s8,80003b8a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b2a:	8526                	mv	a0,s1
    80003b2c:	00000097          	auipc	ra,0x0
    80003b30:	75e080e7          	jalr	1886(ra) # 8000428a <log_write>
    brelse(bp);
    80003b34:	8526                	mv	a0,s1
    80003b36:	fffff097          	auipc	ra,0xfffff
    80003b3a:	4fc080e7          	jalr	1276(ra) # 80003032 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b3e:	013d09bb          	addw	s3,s10,s3
    80003b42:	012d093b          	addw	s2,s10,s2
    80003b46:	9a6e                	add	s4,s4,s11
    80003b48:	0569f663          	bgeu	s3,s6,80003b94 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003b4c:	00a9559b          	srliw	a1,s2,0xa
    80003b50:	8556                	mv	a0,s5
    80003b52:	fffff097          	auipc	ra,0xfffff
    80003b56:	7a2080e7          	jalr	1954(ra) # 800032f4 <bmap>
    80003b5a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b5e:	c99d                	beqz	a1,80003b94 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003b60:	000aa503          	lw	a0,0(s5)
    80003b64:	fffff097          	auipc	ra,0xfffff
    80003b68:	39e080e7          	jalr	926(ra) # 80002f02 <bread>
    80003b6c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b6e:	3ff97713          	andi	a4,s2,1023
    80003b72:	40ec87bb          	subw	a5,s9,a4
    80003b76:	413b06bb          	subw	a3,s6,s3
    80003b7a:	8d3e                	mv	s10,a5
    80003b7c:	2781                	sext.w	a5,a5
    80003b7e:	0006861b          	sext.w	a2,a3
    80003b82:	f8f674e3          	bgeu	a2,a5,80003b0a <writei+0x4c>
    80003b86:	8d36                	mv	s10,a3
    80003b88:	b749                	j	80003b0a <writei+0x4c>
      brelse(bp);
    80003b8a:	8526                	mv	a0,s1
    80003b8c:	fffff097          	auipc	ra,0xfffff
    80003b90:	4a6080e7          	jalr	1190(ra) # 80003032 <brelse>
  }

  if(off > ip->size)
    80003b94:	04caa783          	lw	a5,76(s5)
    80003b98:	0127f463          	bgeu	a5,s2,80003ba0 <writei+0xe2>
    ip->size = off;
    80003b9c:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ba0:	8556                	mv	a0,s5
    80003ba2:	00000097          	auipc	ra,0x0
    80003ba6:	aa4080e7          	jalr	-1372(ra) # 80003646 <iupdate>

  return tot;
    80003baa:	0009851b          	sext.w	a0,s3
}
    80003bae:	70a6                	ld	ra,104(sp)
    80003bb0:	7406                	ld	s0,96(sp)
    80003bb2:	64e6                	ld	s1,88(sp)
    80003bb4:	6946                	ld	s2,80(sp)
    80003bb6:	69a6                	ld	s3,72(sp)
    80003bb8:	6a06                	ld	s4,64(sp)
    80003bba:	7ae2                	ld	s5,56(sp)
    80003bbc:	7b42                	ld	s6,48(sp)
    80003bbe:	7ba2                	ld	s7,40(sp)
    80003bc0:	7c02                	ld	s8,32(sp)
    80003bc2:	6ce2                	ld	s9,24(sp)
    80003bc4:	6d42                	ld	s10,16(sp)
    80003bc6:	6da2                	ld	s11,8(sp)
    80003bc8:	6165                	addi	sp,sp,112
    80003bca:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bcc:	89da                	mv	s3,s6
    80003bce:	bfc9                	j	80003ba0 <writei+0xe2>
    return -1;
    80003bd0:	557d                	li	a0,-1
}
    80003bd2:	8082                	ret
    return -1;
    80003bd4:	557d                	li	a0,-1
    80003bd6:	bfe1                	j	80003bae <writei+0xf0>
    return -1;
    80003bd8:	557d                	li	a0,-1
    80003bda:	bfd1                	j	80003bae <writei+0xf0>

0000000080003bdc <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003bdc:	1141                	addi	sp,sp,-16
    80003bde:	e406                	sd	ra,8(sp)
    80003be0:	e022                	sd	s0,0(sp)
    80003be2:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003be4:	4639                	li	a2,14
    80003be6:	ffffd097          	auipc	ra,0xffffd
    80003bea:	22e080e7          	jalr	558(ra) # 80000e14 <strncmp>
}
    80003bee:	60a2                	ld	ra,8(sp)
    80003bf0:	6402                	ld	s0,0(sp)
    80003bf2:	0141                	addi	sp,sp,16
    80003bf4:	8082                	ret

0000000080003bf6 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003bf6:	7139                	addi	sp,sp,-64
    80003bf8:	fc06                	sd	ra,56(sp)
    80003bfa:	f822                	sd	s0,48(sp)
    80003bfc:	f426                	sd	s1,40(sp)
    80003bfe:	f04a                	sd	s2,32(sp)
    80003c00:	ec4e                	sd	s3,24(sp)
    80003c02:	e852                	sd	s4,16(sp)
    80003c04:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c06:	04451703          	lh	a4,68(a0)
    80003c0a:	4785                	li	a5,1
    80003c0c:	00f71a63          	bne	a4,a5,80003c20 <dirlookup+0x2a>
    80003c10:	892a                	mv	s2,a0
    80003c12:	89ae                	mv	s3,a1
    80003c14:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c16:	457c                	lw	a5,76(a0)
    80003c18:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c1a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c1c:	e79d                	bnez	a5,80003c4a <dirlookup+0x54>
    80003c1e:	a8a5                	j	80003c96 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c20:	00005517          	auipc	a0,0x5
    80003c24:	9d850513          	addi	a0,a0,-1576 # 800085f8 <syscalls+0x1a0>
    80003c28:	ffffd097          	auipc	ra,0xffffd
    80003c2c:	918080e7          	jalr	-1768(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003c30:	00005517          	auipc	a0,0x5
    80003c34:	9e050513          	addi	a0,a0,-1568 # 80008610 <syscalls+0x1b8>
    80003c38:	ffffd097          	auipc	ra,0xffffd
    80003c3c:	908080e7          	jalr	-1784(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c40:	24c1                	addiw	s1,s1,16
    80003c42:	04c92783          	lw	a5,76(s2)
    80003c46:	04f4f763          	bgeu	s1,a5,80003c94 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c4a:	4741                	li	a4,16
    80003c4c:	86a6                	mv	a3,s1
    80003c4e:	fc040613          	addi	a2,s0,-64
    80003c52:	4581                	li	a1,0
    80003c54:	854a                	mv	a0,s2
    80003c56:	00000097          	auipc	ra,0x0
    80003c5a:	d70080e7          	jalr	-656(ra) # 800039c6 <readi>
    80003c5e:	47c1                	li	a5,16
    80003c60:	fcf518e3          	bne	a0,a5,80003c30 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c64:	fc045783          	lhu	a5,-64(s0)
    80003c68:	dfe1                	beqz	a5,80003c40 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c6a:	fc240593          	addi	a1,s0,-62
    80003c6e:	854e                	mv	a0,s3
    80003c70:	00000097          	auipc	ra,0x0
    80003c74:	f6c080e7          	jalr	-148(ra) # 80003bdc <namecmp>
    80003c78:	f561                	bnez	a0,80003c40 <dirlookup+0x4a>
      if(poff)
    80003c7a:	000a0463          	beqz	s4,80003c82 <dirlookup+0x8c>
        *poff = off;
    80003c7e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c82:	fc045583          	lhu	a1,-64(s0)
    80003c86:	00092503          	lw	a0,0(s2)
    80003c8a:	fffff097          	auipc	ra,0xfffff
    80003c8e:	754080e7          	jalr	1876(ra) # 800033de <iget>
    80003c92:	a011                	j	80003c96 <dirlookup+0xa0>
  return 0;
    80003c94:	4501                	li	a0,0
}
    80003c96:	70e2                	ld	ra,56(sp)
    80003c98:	7442                	ld	s0,48(sp)
    80003c9a:	74a2                	ld	s1,40(sp)
    80003c9c:	7902                	ld	s2,32(sp)
    80003c9e:	69e2                	ld	s3,24(sp)
    80003ca0:	6a42                	ld	s4,16(sp)
    80003ca2:	6121                	addi	sp,sp,64
    80003ca4:	8082                	ret

0000000080003ca6 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ca6:	711d                	addi	sp,sp,-96
    80003ca8:	ec86                	sd	ra,88(sp)
    80003caa:	e8a2                	sd	s0,80(sp)
    80003cac:	e4a6                	sd	s1,72(sp)
    80003cae:	e0ca                	sd	s2,64(sp)
    80003cb0:	fc4e                	sd	s3,56(sp)
    80003cb2:	f852                	sd	s4,48(sp)
    80003cb4:	f456                	sd	s5,40(sp)
    80003cb6:	f05a                	sd	s6,32(sp)
    80003cb8:	ec5e                	sd	s7,24(sp)
    80003cba:	e862                	sd	s8,16(sp)
    80003cbc:	e466                	sd	s9,8(sp)
    80003cbe:	1080                	addi	s0,sp,96
    80003cc0:	84aa                	mv	s1,a0
    80003cc2:	8b2e                	mv	s6,a1
    80003cc4:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003cc6:	00054703          	lbu	a4,0(a0)
    80003cca:	02f00793          	li	a5,47
    80003cce:	02f70263          	beq	a4,a5,80003cf2 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003cd2:	ffffe097          	auipc	ra,0xffffe
    80003cd6:	d52080e7          	jalr	-686(ra) # 80001a24 <myproc>
    80003cda:	15053503          	ld	a0,336(a0)
    80003cde:	00000097          	auipc	ra,0x0
    80003ce2:	9f6080e7          	jalr	-1546(ra) # 800036d4 <idup>
    80003ce6:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003ce8:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003cec:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003cee:	4b85                	li	s7,1
    80003cf0:	a875                	j	80003dac <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80003cf2:	4585                	li	a1,1
    80003cf4:	4505                	li	a0,1
    80003cf6:	fffff097          	auipc	ra,0xfffff
    80003cfa:	6e8080e7          	jalr	1768(ra) # 800033de <iget>
    80003cfe:	8a2a                	mv	s4,a0
    80003d00:	b7e5                	j	80003ce8 <namex+0x42>
      iunlockput(ip);
    80003d02:	8552                	mv	a0,s4
    80003d04:	00000097          	auipc	ra,0x0
    80003d08:	c70080e7          	jalr	-912(ra) # 80003974 <iunlockput>
      return 0;
    80003d0c:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d0e:	8552                	mv	a0,s4
    80003d10:	60e6                	ld	ra,88(sp)
    80003d12:	6446                	ld	s0,80(sp)
    80003d14:	64a6                	ld	s1,72(sp)
    80003d16:	6906                	ld	s2,64(sp)
    80003d18:	79e2                	ld	s3,56(sp)
    80003d1a:	7a42                	ld	s4,48(sp)
    80003d1c:	7aa2                	ld	s5,40(sp)
    80003d1e:	7b02                	ld	s6,32(sp)
    80003d20:	6be2                	ld	s7,24(sp)
    80003d22:	6c42                	ld	s8,16(sp)
    80003d24:	6ca2                	ld	s9,8(sp)
    80003d26:	6125                	addi	sp,sp,96
    80003d28:	8082                	ret
      iunlock(ip);
    80003d2a:	8552                	mv	a0,s4
    80003d2c:	00000097          	auipc	ra,0x0
    80003d30:	aa8080e7          	jalr	-1368(ra) # 800037d4 <iunlock>
      return ip;
    80003d34:	bfe9                	j	80003d0e <namex+0x68>
      iunlockput(ip);
    80003d36:	8552                	mv	a0,s4
    80003d38:	00000097          	auipc	ra,0x0
    80003d3c:	c3c080e7          	jalr	-964(ra) # 80003974 <iunlockput>
      return 0;
    80003d40:	8a4e                	mv	s4,s3
    80003d42:	b7f1                	j	80003d0e <namex+0x68>
  len = path - s;
    80003d44:	40998633          	sub	a2,s3,s1
    80003d48:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003d4c:	099c5863          	bge	s8,s9,80003ddc <namex+0x136>
    memmove(name, s, DIRSIZ);
    80003d50:	4639                	li	a2,14
    80003d52:	85a6                	mv	a1,s1
    80003d54:	8556                	mv	a0,s5
    80003d56:	ffffd097          	auipc	ra,0xffffd
    80003d5a:	04a080e7          	jalr	74(ra) # 80000da0 <memmove>
    80003d5e:	84ce                	mv	s1,s3
  while(*path == '/')
    80003d60:	0004c783          	lbu	a5,0(s1)
    80003d64:	01279763          	bne	a5,s2,80003d72 <namex+0xcc>
    path++;
    80003d68:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d6a:	0004c783          	lbu	a5,0(s1)
    80003d6e:	ff278de3          	beq	a5,s2,80003d68 <namex+0xc2>
    ilock(ip);
    80003d72:	8552                	mv	a0,s4
    80003d74:	00000097          	auipc	ra,0x0
    80003d78:	99e080e7          	jalr	-1634(ra) # 80003712 <ilock>
    if(ip->type != T_DIR){
    80003d7c:	044a1783          	lh	a5,68(s4)
    80003d80:	f97791e3          	bne	a5,s7,80003d02 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80003d84:	000b0563          	beqz	s6,80003d8e <namex+0xe8>
    80003d88:	0004c783          	lbu	a5,0(s1)
    80003d8c:	dfd9                	beqz	a5,80003d2a <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d8e:	4601                	li	a2,0
    80003d90:	85d6                	mv	a1,s5
    80003d92:	8552                	mv	a0,s4
    80003d94:	00000097          	auipc	ra,0x0
    80003d98:	e62080e7          	jalr	-414(ra) # 80003bf6 <dirlookup>
    80003d9c:	89aa                	mv	s3,a0
    80003d9e:	dd41                	beqz	a0,80003d36 <namex+0x90>
    iunlockput(ip);
    80003da0:	8552                	mv	a0,s4
    80003da2:	00000097          	auipc	ra,0x0
    80003da6:	bd2080e7          	jalr	-1070(ra) # 80003974 <iunlockput>
    ip = next;
    80003daa:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003dac:	0004c783          	lbu	a5,0(s1)
    80003db0:	01279763          	bne	a5,s2,80003dbe <namex+0x118>
    path++;
    80003db4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003db6:	0004c783          	lbu	a5,0(s1)
    80003dba:	ff278de3          	beq	a5,s2,80003db4 <namex+0x10e>
  if(*path == 0)
    80003dbe:	cb9d                	beqz	a5,80003df4 <namex+0x14e>
  while(*path != '/' && *path != 0)
    80003dc0:	0004c783          	lbu	a5,0(s1)
    80003dc4:	89a6                	mv	s3,s1
  len = path - s;
    80003dc6:	4c81                	li	s9,0
    80003dc8:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003dca:	01278963          	beq	a5,s2,80003ddc <namex+0x136>
    80003dce:	dbbd                	beqz	a5,80003d44 <namex+0x9e>
    path++;
    80003dd0:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003dd2:	0009c783          	lbu	a5,0(s3)
    80003dd6:	ff279ce3          	bne	a5,s2,80003dce <namex+0x128>
    80003dda:	b7ad                	j	80003d44 <namex+0x9e>
    memmove(name, s, len);
    80003ddc:	2601                	sext.w	a2,a2
    80003dde:	85a6                	mv	a1,s1
    80003de0:	8556                	mv	a0,s5
    80003de2:	ffffd097          	auipc	ra,0xffffd
    80003de6:	fbe080e7          	jalr	-66(ra) # 80000da0 <memmove>
    name[len] = 0;
    80003dea:	9cd6                	add	s9,s9,s5
    80003dec:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003df0:	84ce                	mv	s1,s3
    80003df2:	b7bd                	j	80003d60 <namex+0xba>
  if(nameiparent){
    80003df4:	f00b0de3          	beqz	s6,80003d0e <namex+0x68>
    iput(ip);
    80003df8:	8552                	mv	a0,s4
    80003dfa:	00000097          	auipc	ra,0x0
    80003dfe:	ad2080e7          	jalr	-1326(ra) # 800038cc <iput>
    return 0;
    80003e02:	4a01                	li	s4,0
    80003e04:	b729                	j	80003d0e <namex+0x68>

0000000080003e06 <dirlink>:
{
    80003e06:	7139                	addi	sp,sp,-64
    80003e08:	fc06                	sd	ra,56(sp)
    80003e0a:	f822                	sd	s0,48(sp)
    80003e0c:	f426                	sd	s1,40(sp)
    80003e0e:	f04a                	sd	s2,32(sp)
    80003e10:	ec4e                	sd	s3,24(sp)
    80003e12:	e852                	sd	s4,16(sp)
    80003e14:	0080                	addi	s0,sp,64
    80003e16:	892a                	mv	s2,a0
    80003e18:	8a2e                	mv	s4,a1
    80003e1a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e1c:	4601                	li	a2,0
    80003e1e:	00000097          	auipc	ra,0x0
    80003e22:	dd8080e7          	jalr	-552(ra) # 80003bf6 <dirlookup>
    80003e26:	e93d                	bnez	a0,80003e9c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e28:	04c92483          	lw	s1,76(s2)
    80003e2c:	c49d                	beqz	s1,80003e5a <dirlink+0x54>
    80003e2e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e30:	4741                	li	a4,16
    80003e32:	86a6                	mv	a3,s1
    80003e34:	fc040613          	addi	a2,s0,-64
    80003e38:	4581                	li	a1,0
    80003e3a:	854a                	mv	a0,s2
    80003e3c:	00000097          	auipc	ra,0x0
    80003e40:	b8a080e7          	jalr	-1142(ra) # 800039c6 <readi>
    80003e44:	47c1                	li	a5,16
    80003e46:	06f51163          	bne	a0,a5,80003ea8 <dirlink+0xa2>
    if(de.inum == 0)
    80003e4a:	fc045783          	lhu	a5,-64(s0)
    80003e4e:	c791                	beqz	a5,80003e5a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e50:	24c1                	addiw	s1,s1,16
    80003e52:	04c92783          	lw	a5,76(s2)
    80003e56:	fcf4ede3          	bltu	s1,a5,80003e30 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e5a:	4639                	li	a2,14
    80003e5c:	85d2                	mv	a1,s4
    80003e5e:	fc240513          	addi	a0,s0,-62
    80003e62:	ffffd097          	auipc	ra,0xffffd
    80003e66:	fee080e7          	jalr	-18(ra) # 80000e50 <strncpy>
  de.inum = inum;
    80003e6a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e6e:	4741                	li	a4,16
    80003e70:	86a6                	mv	a3,s1
    80003e72:	fc040613          	addi	a2,s0,-64
    80003e76:	4581                	li	a1,0
    80003e78:	854a                	mv	a0,s2
    80003e7a:	00000097          	auipc	ra,0x0
    80003e7e:	c44080e7          	jalr	-956(ra) # 80003abe <writei>
    80003e82:	1541                	addi	a0,a0,-16
    80003e84:	00a03533          	snez	a0,a0
    80003e88:	40a00533          	neg	a0,a0
}
    80003e8c:	70e2                	ld	ra,56(sp)
    80003e8e:	7442                	ld	s0,48(sp)
    80003e90:	74a2                	ld	s1,40(sp)
    80003e92:	7902                	ld	s2,32(sp)
    80003e94:	69e2                	ld	s3,24(sp)
    80003e96:	6a42                	ld	s4,16(sp)
    80003e98:	6121                	addi	sp,sp,64
    80003e9a:	8082                	ret
    iput(ip);
    80003e9c:	00000097          	auipc	ra,0x0
    80003ea0:	a30080e7          	jalr	-1488(ra) # 800038cc <iput>
    return -1;
    80003ea4:	557d                	li	a0,-1
    80003ea6:	b7dd                	j	80003e8c <dirlink+0x86>
      panic("dirlink read");
    80003ea8:	00004517          	auipc	a0,0x4
    80003eac:	77850513          	addi	a0,a0,1912 # 80008620 <syscalls+0x1c8>
    80003eb0:	ffffc097          	auipc	ra,0xffffc
    80003eb4:	690080e7          	jalr	1680(ra) # 80000540 <panic>

0000000080003eb8 <namei>:

struct inode*
namei(char *path)
{
    80003eb8:	1101                	addi	sp,sp,-32
    80003eba:	ec06                	sd	ra,24(sp)
    80003ebc:	e822                	sd	s0,16(sp)
    80003ebe:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ec0:	fe040613          	addi	a2,s0,-32
    80003ec4:	4581                	li	a1,0
    80003ec6:	00000097          	auipc	ra,0x0
    80003eca:	de0080e7          	jalr	-544(ra) # 80003ca6 <namex>
}
    80003ece:	60e2                	ld	ra,24(sp)
    80003ed0:	6442                	ld	s0,16(sp)
    80003ed2:	6105                	addi	sp,sp,32
    80003ed4:	8082                	ret

0000000080003ed6 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003ed6:	1141                	addi	sp,sp,-16
    80003ed8:	e406                	sd	ra,8(sp)
    80003eda:	e022                	sd	s0,0(sp)
    80003edc:	0800                	addi	s0,sp,16
    80003ede:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003ee0:	4585                	li	a1,1
    80003ee2:	00000097          	auipc	ra,0x0
    80003ee6:	dc4080e7          	jalr	-572(ra) # 80003ca6 <namex>
}
    80003eea:	60a2                	ld	ra,8(sp)
    80003eec:	6402                	ld	s0,0(sp)
    80003eee:	0141                	addi	sp,sp,16
    80003ef0:	8082                	ret

0000000080003ef2 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003ef2:	1101                	addi	sp,sp,-32
    80003ef4:	ec06                	sd	ra,24(sp)
    80003ef6:	e822                	sd	s0,16(sp)
    80003ef8:	e426                	sd	s1,8(sp)
    80003efa:	e04a                	sd	s2,0(sp)
    80003efc:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003efe:	00025917          	auipc	s2,0x25
    80003f02:	8c290913          	addi	s2,s2,-1854 # 800287c0 <log>
    80003f06:	01892583          	lw	a1,24(s2)
    80003f0a:	02892503          	lw	a0,40(s2)
    80003f0e:	fffff097          	auipc	ra,0xfffff
    80003f12:	ff4080e7          	jalr	-12(ra) # 80002f02 <bread>
    80003f16:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f18:	02c92603          	lw	a2,44(s2)
    80003f1c:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f1e:	00c05f63          	blez	a2,80003f3c <write_head+0x4a>
    80003f22:	00025717          	auipc	a4,0x25
    80003f26:	8ce70713          	addi	a4,a4,-1842 # 800287f0 <log+0x30>
    80003f2a:	87aa                	mv	a5,a0
    80003f2c:	060a                	slli	a2,a2,0x2
    80003f2e:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80003f30:	4314                	lw	a3,0(a4)
    80003f32:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80003f34:	0711                	addi	a4,a4,4
    80003f36:	0791                	addi	a5,a5,4
    80003f38:	fec79ce3          	bne	a5,a2,80003f30 <write_head+0x3e>
  }
  bwrite(buf);
    80003f3c:	8526                	mv	a0,s1
    80003f3e:	fffff097          	auipc	ra,0xfffff
    80003f42:	0b6080e7          	jalr	182(ra) # 80002ff4 <bwrite>
  brelse(buf);
    80003f46:	8526                	mv	a0,s1
    80003f48:	fffff097          	auipc	ra,0xfffff
    80003f4c:	0ea080e7          	jalr	234(ra) # 80003032 <brelse>
}
    80003f50:	60e2                	ld	ra,24(sp)
    80003f52:	6442                	ld	s0,16(sp)
    80003f54:	64a2                	ld	s1,8(sp)
    80003f56:	6902                	ld	s2,0(sp)
    80003f58:	6105                	addi	sp,sp,32
    80003f5a:	8082                	ret

0000000080003f5c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f5c:	00025797          	auipc	a5,0x25
    80003f60:	8907a783          	lw	a5,-1904(a5) # 800287ec <log+0x2c>
    80003f64:	0af05d63          	blez	a5,8000401e <install_trans+0xc2>
{
    80003f68:	7139                	addi	sp,sp,-64
    80003f6a:	fc06                	sd	ra,56(sp)
    80003f6c:	f822                	sd	s0,48(sp)
    80003f6e:	f426                	sd	s1,40(sp)
    80003f70:	f04a                	sd	s2,32(sp)
    80003f72:	ec4e                	sd	s3,24(sp)
    80003f74:	e852                	sd	s4,16(sp)
    80003f76:	e456                	sd	s5,8(sp)
    80003f78:	e05a                	sd	s6,0(sp)
    80003f7a:	0080                	addi	s0,sp,64
    80003f7c:	8b2a                	mv	s6,a0
    80003f7e:	00025a97          	auipc	s5,0x25
    80003f82:	872a8a93          	addi	s5,s5,-1934 # 800287f0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f86:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f88:	00025997          	auipc	s3,0x25
    80003f8c:	83898993          	addi	s3,s3,-1992 # 800287c0 <log>
    80003f90:	a00d                	j	80003fb2 <install_trans+0x56>
    brelse(lbuf);
    80003f92:	854a                	mv	a0,s2
    80003f94:	fffff097          	auipc	ra,0xfffff
    80003f98:	09e080e7          	jalr	158(ra) # 80003032 <brelse>
    brelse(dbuf);
    80003f9c:	8526                	mv	a0,s1
    80003f9e:	fffff097          	auipc	ra,0xfffff
    80003fa2:	094080e7          	jalr	148(ra) # 80003032 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fa6:	2a05                	addiw	s4,s4,1
    80003fa8:	0a91                	addi	s5,s5,4
    80003faa:	02c9a783          	lw	a5,44(s3)
    80003fae:	04fa5e63          	bge	s4,a5,8000400a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fb2:	0189a583          	lw	a1,24(s3)
    80003fb6:	014585bb          	addw	a1,a1,s4
    80003fba:	2585                	addiw	a1,a1,1
    80003fbc:	0289a503          	lw	a0,40(s3)
    80003fc0:	fffff097          	auipc	ra,0xfffff
    80003fc4:	f42080e7          	jalr	-190(ra) # 80002f02 <bread>
    80003fc8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003fca:	000aa583          	lw	a1,0(s5)
    80003fce:	0289a503          	lw	a0,40(s3)
    80003fd2:	fffff097          	auipc	ra,0xfffff
    80003fd6:	f30080e7          	jalr	-208(ra) # 80002f02 <bread>
    80003fda:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003fdc:	40000613          	li	a2,1024
    80003fe0:	05890593          	addi	a1,s2,88
    80003fe4:	05850513          	addi	a0,a0,88
    80003fe8:	ffffd097          	auipc	ra,0xffffd
    80003fec:	db8080e7          	jalr	-584(ra) # 80000da0 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003ff0:	8526                	mv	a0,s1
    80003ff2:	fffff097          	auipc	ra,0xfffff
    80003ff6:	002080e7          	jalr	2(ra) # 80002ff4 <bwrite>
    if(recovering == 0)
    80003ffa:	f80b1ce3          	bnez	s6,80003f92 <install_trans+0x36>
      bunpin(dbuf);
    80003ffe:	8526                	mv	a0,s1
    80004000:	fffff097          	auipc	ra,0xfffff
    80004004:	10a080e7          	jalr	266(ra) # 8000310a <bunpin>
    80004008:	b769                	j	80003f92 <install_trans+0x36>
}
    8000400a:	70e2                	ld	ra,56(sp)
    8000400c:	7442                	ld	s0,48(sp)
    8000400e:	74a2                	ld	s1,40(sp)
    80004010:	7902                	ld	s2,32(sp)
    80004012:	69e2                	ld	s3,24(sp)
    80004014:	6a42                	ld	s4,16(sp)
    80004016:	6aa2                	ld	s5,8(sp)
    80004018:	6b02                	ld	s6,0(sp)
    8000401a:	6121                	addi	sp,sp,64
    8000401c:	8082                	ret
    8000401e:	8082                	ret

0000000080004020 <initlog>:
{
    80004020:	7179                	addi	sp,sp,-48
    80004022:	f406                	sd	ra,40(sp)
    80004024:	f022                	sd	s0,32(sp)
    80004026:	ec26                	sd	s1,24(sp)
    80004028:	e84a                	sd	s2,16(sp)
    8000402a:	e44e                	sd	s3,8(sp)
    8000402c:	1800                	addi	s0,sp,48
    8000402e:	892a                	mv	s2,a0
    80004030:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004032:	00024497          	auipc	s1,0x24
    80004036:	78e48493          	addi	s1,s1,1934 # 800287c0 <log>
    8000403a:	00004597          	auipc	a1,0x4
    8000403e:	5f658593          	addi	a1,a1,1526 # 80008630 <syscalls+0x1d8>
    80004042:	8526                	mv	a0,s1
    80004044:	ffffd097          	auipc	ra,0xffffd
    80004048:	b74080e7          	jalr	-1164(ra) # 80000bb8 <initlock>
  log.start = sb->logstart;
    8000404c:	0149a583          	lw	a1,20(s3)
    80004050:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004052:	0109a783          	lw	a5,16(s3)
    80004056:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004058:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000405c:	854a                	mv	a0,s2
    8000405e:	fffff097          	auipc	ra,0xfffff
    80004062:	ea4080e7          	jalr	-348(ra) # 80002f02 <bread>
  log.lh.n = lh->n;
    80004066:	4d30                	lw	a2,88(a0)
    80004068:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000406a:	00c05f63          	blez	a2,80004088 <initlog+0x68>
    8000406e:	87aa                	mv	a5,a0
    80004070:	00024717          	auipc	a4,0x24
    80004074:	78070713          	addi	a4,a4,1920 # 800287f0 <log+0x30>
    80004078:	060a                	slli	a2,a2,0x2
    8000407a:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    8000407c:	4ff4                	lw	a3,92(a5)
    8000407e:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004080:	0791                	addi	a5,a5,4
    80004082:	0711                	addi	a4,a4,4
    80004084:	fec79ce3          	bne	a5,a2,8000407c <initlog+0x5c>
  brelse(buf);
    80004088:	fffff097          	auipc	ra,0xfffff
    8000408c:	faa080e7          	jalr	-86(ra) # 80003032 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004090:	4505                	li	a0,1
    80004092:	00000097          	auipc	ra,0x0
    80004096:	eca080e7          	jalr	-310(ra) # 80003f5c <install_trans>
  log.lh.n = 0;
    8000409a:	00024797          	auipc	a5,0x24
    8000409e:	7407a923          	sw	zero,1874(a5) # 800287ec <log+0x2c>
  write_head(); // clear the log
    800040a2:	00000097          	auipc	ra,0x0
    800040a6:	e50080e7          	jalr	-432(ra) # 80003ef2 <write_head>
}
    800040aa:	70a2                	ld	ra,40(sp)
    800040ac:	7402                	ld	s0,32(sp)
    800040ae:	64e2                	ld	s1,24(sp)
    800040b0:	6942                	ld	s2,16(sp)
    800040b2:	69a2                	ld	s3,8(sp)
    800040b4:	6145                	addi	sp,sp,48
    800040b6:	8082                	ret

00000000800040b8 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040b8:	1101                	addi	sp,sp,-32
    800040ba:	ec06                	sd	ra,24(sp)
    800040bc:	e822                	sd	s0,16(sp)
    800040be:	e426                	sd	s1,8(sp)
    800040c0:	e04a                	sd	s2,0(sp)
    800040c2:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800040c4:	00024517          	auipc	a0,0x24
    800040c8:	6fc50513          	addi	a0,a0,1788 # 800287c0 <log>
    800040cc:	ffffd097          	auipc	ra,0xffffd
    800040d0:	b7c080e7          	jalr	-1156(ra) # 80000c48 <acquire>
  while(1){
    if(log.committing){
    800040d4:	00024497          	auipc	s1,0x24
    800040d8:	6ec48493          	addi	s1,s1,1772 # 800287c0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040dc:	4979                	li	s2,30
    800040de:	a039                	j	800040ec <begin_op+0x34>
      sleep(&log, &log.lock);
    800040e0:	85a6                	mv	a1,s1
    800040e2:	8526                	mv	a0,s1
    800040e4:	ffffe097          	auipc	ra,0xffffe
    800040e8:	022080e7          	jalr	34(ra) # 80002106 <sleep>
    if(log.committing){
    800040ec:	50dc                	lw	a5,36(s1)
    800040ee:	fbed                	bnez	a5,800040e0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040f0:	5098                	lw	a4,32(s1)
    800040f2:	2705                	addiw	a4,a4,1
    800040f4:	0027179b          	slliw	a5,a4,0x2
    800040f8:	9fb9                	addw	a5,a5,a4
    800040fa:	0017979b          	slliw	a5,a5,0x1
    800040fe:	54d4                	lw	a3,44(s1)
    80004100:	9fb5                	addw	a5,a5,a3
    80004102:	00f95963          	bge	s2,a5,80004114 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004106:	85a6                	mv	a1,s1
    80004108:	8526                	mv	a0,s1
    8000410a:	ffffe097          	auipc	ra,0xffffe
    8000410e:	ffc080e7          	jalr	-4(ra) # 80002106 <sleep>
    80004112:	bfe9                	j	800040ec <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004114:	00024517          	auipc	a0,0x24
    80004118:	6ac50513          	addi	a0,a0,1708 # 800287c0 <log>
    8000411c:	d118                	sw	a4,32(a0)
      release(&log.lock);
    8000411e:	ffffd097          	auipc	ra,0xffffd
    80004122:	bde080e7          	jalr	-1058(ra) # 80000cfc <release>
      break;
    }
  }
}
    80004126:	60e2                	ld	ra,24(sp)
    80004128:	6442                	ld	s0,16(sp)
    8000412a:	64a2                	ld	s1,8(sp)
    8000412c:	6902                	ld	s2,0(sp)
    8000412e:	6105                	addi	sp,sp,32
    80004130:	8082                	ret

0000000080004132 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004132:	7139                	addi	sp,sp,-64
    80004134:	fc06                	sd	ra,56(sp)
    80004136:	f822                	sd	s0,48(sp)
    80004138:	f426                	sd	s1,40(sp)
    8000413a:	f04a                	sd	s2,32(sp)
    8000413c:	ec4e                	sd	s3,24(sp)
    8000413e:	e852                	sd	s4,16(sp)
    80004140:	e456                	sd	s5,8(sp)
    80004142:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004144:	00024497          	auipc	s1,0x24
    80004148:	67c48493          	addi	s1,s1,1660 # 800287c0 <log>
    8000414c:	8526                	mv	a0,s1
    8000414e:	ffffd097          	auipc	ra,0xffffd
    80004152:	afa080e7          	jalr	-1286(ra) # 80000c48 <acquire>
  log.outstanding -= 1;
    80004156:	509c                	lw	a5,32(s1)
    80004158:	37fd                	addiw	a5,a5,-1
    8000415a:	0007891b          	sext.w	s2,a5
    8000415e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004160:	50dc                	lw	a5,36(s1)
    80004162:	e7b9                	bnez	a5,800041b0 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004164:	04091e63          	bnez	s2,800041c0 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004168:	00024497          	auipc	s1,0x24
    8000416c:	65848493          	addi	s1,s1,1624 # 800287c0 <log>
    80004170:	4785                	li	a5,1
    80004172:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004174:	8526                	mv	a0,s1
    80004176:	ffffd097          	auipc	ra,0xffffd
    8000417a:	b86080e7          	jalr	-1146(ra) # 80000cfc <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000417e:	54dc                	lw	a5,44(s1)
    80004180:	06f04763          	bgtz	a5,800041ee <end_op+0xbc>
    acquire(&log.lock);
    80004184:	00024497          	auipc	s1,0x24
    80004188:	63c48493          	addi	s1,s1,1596 # 800287c0 <log>
    8000418c:	8526                	mv	a0,s1
    8000418e:	ffffd097          	auipc	ra,0xffffd
    80004192:	aba080e7          	jalr	-1350(ra) # 80000c48 <acquire>
    log.committing = 0;
    80004196:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000419a:	8526                	mv	a0,s1
    8000419c:	ffffe097          	auipc	ra,0xffffe
    800041a0:	fce080e7          	jalr	-50(ra) # 8000216a <wakeup>
    release(&log.lock);
    800041a4:	8526                	mv	a0,s1
    800041a6:	ffffd097          	auipc	ra,0xffffd
    800041aa:	b56080e7          	jalr	-1194(ra) # 80000cfc <release>
}
    800041ae:	a03d                	j	800041dc <end_op+0xaa>
    panic("log.committing");
    800041b0:	00004517          	auipc	a0,0x4
    800041b4:	48850513          	addi	a0,a0,1160 # 80008638 <syscalls+0x1e0>
    800041b8:	ffffc097          	auipc	ra,0xffffc
    800041bc:	388080e7          	jalr	904(ra) # 80000540 <panic>
    wakeup(&log);
    800041c0:	00024497          	auipc	s1,0x24
    800041c4:	60048493          	addi	s1,s1,1536 # 800287c0 <log>
    800041c8:	8526                	mv	a0,s1
    800041ca:	ffffe097          	auipc	ra,0xffffe
    800041ce:	fa0080e7          	jalr	-96(ra) # 8000216a <wakeup>
  release(&log.lock);
    800041d2:	8526                	mv	a0,s1
    800041d4:	ffffd097          	auipc	ra,0xffffd
    800041d8:	b28080e7          	jalr	-1240(ra) # 80000cfc <release>
}
    800041dc:	70e2                	ld	ra,56(sp)
    800041de:	7442                	ld	s0,48(sp)
    800041e0:	74a2                	ld	s1,40(sp)
    800041e2:	7902                	ld	s2,32(sp)
    800041e4:	69e2                	ld	s3,24(sp)
    800041e6:	6a42                	ld	s4,16(sp)
    800041e8:	6aa2                	ld	s5,8(sp)
    800041ea:	6121                	addi	sp,sp,64
    800041ec:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800041ee:	00024a97          	auipc	s5,0x24
    800041f2:	602a8a93          	addi	s5,s5,1538 # 800287f0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800041f6:	00024a17          	auipc	s4,0x24
    800041fa:	5caa0a13          	addi	s4,s4,1482 # 800287c0 <log>
    800041fe:	018a2583          	lw	a1,24(s4)
    80004202:	012585bb          	addw	a1,a1,s2
    80004206:	2585                	addiw	a1,a1,1
    80004208:	028a2503          	lw	a0,40(s4)
    8000420c:	fffff097          	auipc	ra,0xfffff
    80004210:	cf6080e7          	jalr	-778(ra) # 80002f02 <bread>
    80004214:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004216:	000aa583          	lw	a1,0(s5)
    8000421a:	028a2503          	lw	a0,40(s4)
    8000421e:	fffff097          	auipc	ra,0xfffff
    80004222:	ce4080e7          	jalr	-796(ra) # 80002f02 <bread>
    80004226:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004228:	40000613          	li	a2,1024
    8000422c:	05850593          	addi	a1,a0,88
    80004230:	05848513          	addi	a0,s1,88
    80004234:	ffffd097          	auipc	ra,0xffffd
    80004238:	b6c080e7          	jalr	-1172(ra) # 80000da0 <memmove>
    bwrite(to);  // write the log
    8000423c:	8526                	mv	a0,s1
    8000423e:	fffff097          	auipc	ra,0xfffff
    80004242:	db6080e7          	jalr	-586(ra) # 80002ff4 <bwrite>
    brelse(from);
    80004246:	854e                	mv	a0,s3
    80004248:	fffff097          	auipc	ra,0xfffff
    8000424c:	dea080e7          	jalr	-534(ra) # 80003032 <brelse>
    brelse(to);
    80004250:	8526                	mv	a0,s1
    80004252:	fffff097          	auipc	ra,0xfffff
    80004256:	de0080e7          	jalr	-544(ra) # 80003032 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000425a:	2905                	addiw	s2,s2,1
    8000425c:	0a91                	addi	s5,s5,4
    8000425e:	02ca2783          	lw	a5,44(s4)
    80004262:	f8f94ee3          	blt	s2,a5,800041fe <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004266:	00000097          	auipc	ra,0x0
    8000426a:	c8c080e7          	jalr	-884(ra) # 80003ef2 <write_head>
    install_trans(0); // Now install writes to home locations
    8000426e:	4501                	li	a0,0
    80004270:	00000097          	auipc	ra,0x0
    80004274:	cec080e7          	jalr	-788(ra) # 80003f5c <install_trans>
    log.lh.n = 0;
    80004278:	00024797          	auipc	a5,0x24
    8000427c:	5607aa23          	sw	zero,1396(a5) # 800287ec <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004280:	00000097          	auipc	ra,0x0
    80004284:	c72080e7          	jalr	-910(ra) # 80003ef2 <write_head>
    80004288:	bdf5                	j	80004184 <end_op+0x52>

000000008000428a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000428a:	1101                	addi	sp,sp,-32
    8000428c:	ec06                	sd	ra,24(sp)
    8000428e:	e822                	sd	s0,16(sp)
    80004290:	e426                	sd	s1,8(sp)
    80004292:	e04a                	sd	s2,0(sp)
    80004294:	1000                	addi	s0,sp,32
    80004296:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004298:	00024917          	auipc	s2,0x24
    8000429c:	52890913          	addi	s2,s2,1320 # 800287c0 <log>
    800042a0:	854a                	mv	a0,s2
    800042a2:	ffffd097          	auipc	ra,0xffffd
    800042a6:	9a6080e7          	jalr	-1626(ra) # 80000c48 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042aa:	02c92603          	lw	a2,44(s2)
    800042ae:	47f5                	li	a5,29
    800042b0:	06c7c563          	blt	a5,a2,8000431a <log_write+0x90>
    800042b4:	00024797          	auipc	a5,0x24
    800042b8:	5287a783          	lw	a5,1320(a5) # 800287dc <log+0x1c>
    800042bc:	37fd                	addiw	a5,a5,-1
    800042be:	04f65e63          	bge	a2,a5,8000431a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042c2:	00024797          	auipc	a5,0x24
    800042c6:	51e7a783          	lw	a5,1310(a5) # 800287e0 <log+0x20>
    800042ca:	06f05063          	blez	a5,8000432a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800042ce:	4781                	li	a5,0
    800042d0:	06c05563          	blez	a2,8000433a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042d4:	44cc                	lw	a1,12(s1)
    800042d6:	00024717          	auipc	a4,0x24
    800042da:	51a70713          	addi	a4,a4,1306 # 800287f0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800042de:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042e0:	4314                	lw	a3,0(a4)
    800042e2:	04b68c63          	beq	a3,a1,8000433a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800042e6:	2785                	addiw	a5,a5,1
    800042e8:	0711                	addi	a4,a4,4
    800042ea:	fef61be3          	bne	a2,a5,800042e0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800042ee:	0621                	addi	a2,a2,8
    800042f0:	060a                	slli	a2,a2,0x2
    800042f2:	00024797          	auipc	a5,0x24
    800042f6:	4ce78793          	addi	a5,a5,1230 # 800287c0 <log>
    800042fa:	97b2                	add	a5,a5,a2
    800042fc:	44d8                	lw	a4,12(s1)
    800042fe:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004300:	8526                	mv	a0,s1
    80004302:	fffff097          	auipc	ra,0xfffff
    80004306:	dcc080e7          	jalr	-564(ra) # 800030ce <bpin>
    log.lh.n++;
    8000430a:	00024717          	auipc	a4,0x24
    8000430e:	4b670713          	addi	a4,a4,1206 # 800287c0 <log>
    80004312:	575c                	lw	a5,44(a4)
    80004314:	2785                	addiw	a5,a5,1
    80004316:	d75c                	sw	a5,44(a4)
    80004318:	a82d                	j	80004352 <log_write+0xc8>
    panic("too big a transaction");
    8000431a:	00004517          	auipc	a0,0x4
    8000431e:	32e50513          	addi	a0,a0,814 # 80008648 <syscalls+0x1f0>
    80004322:	ffffc097          	auipc	ra,0xffffc
    80004326:	21e080e7          	jalr	542(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    8000432a:	00004517          	auipc	a0,0x4
    8000432e:	33650513          	addi	a0,a0,822 # 80008660 <syscalls+0x208>
    80004332:	ffffc097          	auipc	ra,0xffffc
    80004336:	20e080e7          	jalr	526(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    8000433a:	00878693          	addi	a3,a5,8
    8000433e:	068a                	slli	a3,a3,0x2
    80004340:	00024717          	auipc	a4,0x24
    80004344:	48070713          	addi	a4,a4,1152 # 800287c0 <log>
    80004348:	9736                	add	a4,a4,a3
    8000434a:	44d4                	lw	a3,12(s1)
    8000434c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000434e:	faf609e3          	beq	a2,a5,80004300 <log_write+0x76>
  }
  release(&log.lock);
    80004352:	00024517          	auipc	a0,0x24
    80004356:	46e50513          	addi	a0,a0,1134 # 800287c0 <log>
    8000435a:	ffffd097          	auipc	ra,0xffffd
    8000435e:	9a2080e7          	jalr	-1630(ra) # 80000cfc <release>
}
    80004362:	60e2                	ld	ra,24(sp)
    80004364:	6442                	ld	s0,16(sp)
    80004366:	64a2                	ld	s1,8(sp)
    80004368:	6902                	ld	s2,0(sp)
    8000436a:	6105                	addi	sp,sp,32
    8000436c:	8082                	ret

000000008000436e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000436e:	1101                	addi	sp,sp,-32
    80004370:	ec06                	sd	ra,24(sp)
    80004372:	e822                	sd	s0,16(sp)
    80004374:	e426                	sd	s1,8(sp)
    80004376:	e04a                	sd	s2,0(sp)
    80004378:	1000                	addi	s0,sp,32
    8000437a:	84aa                	mv	s1,a0
    8000437c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000437e:	00004597          	auipc	a1,0x4
    80004382:	30258593          	addi	a1,a1,770 # 80008680 <syscalls+0x228>
    80004386:	0521                	addi	a0,a0,8
    80004388:	ffffd097          	auipc	ra,0xffffd
    8000438c:	830080e7          	jalr	-2000(ra) # 80000bb8 <initlock>
  lk->name = name;
    80004390:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004394:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004398:	0204a423          	sw	zero,40(s1)
}
    8000439c:	60e2                	ld	ra,24(sp)
    8000439e:	6442                	ld	s0,16(sp)
    800043a0:	64a2                	ld	s1,8(sp)
    800043a2:	6902                	ld	s2,0(sp)
    800043a4:	6105                	addi	sp,sp,32
    800043a6:	8082                	ret

00000000800043a8 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043a8:	1101                	addi	sp,sp,-32
    800043aa:	ec06                	sd	ra,24(sp)
    800043ac:	e822                	sd	s0,16(sp)
    800043ae:	e426                	sd	s1,8(sp)
    800043b0:	e04a                	sd	s2,0(sp)
    800043b2:	1000                	addi	s0,sp,32
    800043b4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043b6:	00850913          	addi	s2,a0,8
    800043ba:	854a                	mv	a0,s2
    800043bc:	ffffd097          	auipc	ra,0xffffd
    800043c0:	88c080e7          	jalr	-1908(ra) # 80000c48 <acquire>
  while (lk->locked) {
    800043c4:	409c                	lw	a5,0(s1)
    800043c6:	cb89                	beqz	a5,800043d8 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800043c8:	85ca                	mv	a1,s2
    800043ca:	8526                	mv	a0,s1
    800043cc:	ffffe097          	auipc	ra,0xffffe
    800043d0:	d3a080e7          	jalr	-710(ra) # 80002106 <sleep>
  while (lk->locked) {
    800043d4:	409c                	lw	a5,0(s1)
    800043d6:	fbed                	bnez	a5,800043c8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800043d8:	4785                	li	a5,1
    800043da:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800043dc:	ffffd097          	auipc	ra,0xffffd
    800043e0:	648080e7          	jalr	1608(ra) # 80001a24 <myproc>
    800043e4:	591c                	lw	a5,48(a0)
    800043e6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800043e8:	854a                	mv	a0,s2
    800043ea:	ffffd097          	auipc	ra,0xffffd
    800043ee:	912080e7          	jalr	-1774(ra) # 80000cfc <release>
}
    800043f2:	60e2                	ld	ra,24(sp)
    800043f4:	6442                	ld	s0,16(sp)
    800043f6:	64a2                	ld	s1,8(sp)
    800043f8:	6902                	ld	s2,0(sp)
    800043fa:	6105                	addi	sp,sp,32
    800043fc:	8082                	ret

00000000800043fe <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800043fe:	1101                	addi	sp,sp,-32
    80004400:	ec06                	sd	ra,24(sp)
    80004402:	e822                	sd	s0,16(sp)
    80004404:	e426                	sd	s1,8(sp)
    80004406:	e04a                	sd	s2,0(sp)
    80004408:	1000                	addi	s0,sp,32
    8000440a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000440c:	00850913          	addi	s2,a0,8
    80004410:	854a                	mv	a0,s2
    80004412:	ffffd097          	auipc	ra,0xffffd
    80004416:	836080e7          	jalr	-1994(ra) # 80000c48 <acquire>
  lk->locked = 0;
    8000441a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000441e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004422:	8526                	mv	a0,s1
    80004424:	ffffe097          	auipc	ra,0xffffe
    80004428:	d46080e7          	jalr	-698(ra) # 8000216a <wakeup>
  release(&lk->lk);
    8000442c:	854a                	mv	a0,s2
    8000442e:	ffffd097          	auipc	ra,0xffffd
    80004432:	8ce080e7          	jalr	-1842(ra) # 80000cfc <release>
}
    80004436:	60e2                	ld	ra,24(sp)
    80004438:	6442                	ld	s0,16(sp)
    8000443a:	64a2                	ld	s1,8(sp)
    8000443c:	6902                	ld	s2,0(sp)
    8000443e:	6105                	addi	sp,sp,32
    80004440:	8082                	ret

0000000080004442 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004442:	7179                	addi	sp,sp,-48
    80004444:	f406                	sd	ra,40(sp)
    80004446:	f022                	sd	s0,32(sp)
    80004448:	ec26                	sd	s1,24(sp)
    8000444a:	e84a                	sd	s2,16(sp)
    8000444c:	e44e                	sd	s3,8(sp)
    8000444e:	1800                	addi	s0,sp,48
    80004450:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004452:	00850913          	addi	s2,a0,8
    80004456:	854a                	mv	a0,s2
    80004458:	ffffc097          	auipc	ra,0xffffc
    8000445c:	7f0080e7          	jalr	2032(ra) # 80000c48 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004460:	409c                	lw	a5,0(s1)
    80004462:	ef99                	bnez	a5,80004480 <holdingsleep+0x3e>
    80004464:	4481                	li	s1,0
  release(&lk->lk);
    80004466:	854a                	mv	a0,s2
    80004468:	ffffd097          	auipc	ra,0xffffd
    8000446c:	894080e7          	jalr	-1900(ra) # 80000cfc <release>
  return r;
}
    80004470:	8526                	mv	a0,s1
    80004472:	70a2                	ld	ra,40(sp)
    80004474:	7402                	ld	s0,32(sp)
    80004476:	64e2                	ld	s1,24(sp)
    80004478:	6942                	ld	s2,16(sp)
    8000447a:	69a2                	ld	s3,8(sp)
    8000447c:	6145                	addi	sp,sp,48
    8000447e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004480:	0284a983          	lw	s3,40(s1)
    80004484:	ffffd097          	auipc	ra,0xffffd
    80004488:	5a0080e7          	jalr	1440(ra) # 80001a24 <myproc>
    8000448c:	5904                	lw	s1,48(a0)
    8000448e:	413484b3          	sub	s1,s1,s3
    80004492:	0014b493          	seqz	s1,s1
    80004496:	bfc1                	j	80004466 <holdingsleep+0x24>

0000000080004498 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004498:	1141                	addi	sp,sp,-16
    8000449a:	e406                	sd	ra,8(sp)
    8000449c:	e022                	sd	s0,0(sp)
    8000449e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044a0:	00004597          	auipc	a1,0x4
    800044a4:	1f058593          	addi	a1,a1,496 # 80008690 <syscalls+0x238>
    800044a8:	00024517          	auipc	a0,0x24
    800044ac:	46050513          	addi	a0,a0,1120 # 80028908 <ftable>
    800044b0:	ffffc097          	auipc	ra,0xffffc
    800044b4:	708080e7          	jalr	1800(ra) # 80000bb8 <initlock>
}
    800044b8:	60a2                	ld	ra,8(sp)
    800044ba:	6402                	ld	s0,0(sp)
    800044bc:	0141                	addi	sp,sp,16
    800044be:	8082                	ret

00000000800044c0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044c0:	1101                	addi	sp,sp,-32
    800044c2:	ec06                	sd	ra,24(sp)
    800044c4:	e822                	sd	s0,16(sp)
    800044c6:	e426                	sd	s1,8(sp)
    800044c8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800044ca:	00024517          	auipc	a0,0x24
    800044ce:	43e50513          	addi	a0,a0,1086 # 80028908 <ftable>
    800044d2:	ffffc097          	auipc	ra,0xffffc
    800044d6:	776080e7          	jalr	1910(ra) # 80000c48 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044da:	00024497          	auipc	s1,0x24
    800044de:	44648493          	addi	s1,s1,1094 # 80028920 <ftable+0x18>
    800044e2:	00025717          	auipc	a4,0x25
    800044e6:	3de70713          	addi	a4,a4,990 # 800298c0 <disk>
    if(f->ref == 0){
    800044ea:	40dc                	lw	a5,4(s1)
    800044ec:	cf99                	beqz	a5,8000450a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044ee:	02848493          	addi	s1,s1,40
    800044f2:	fee49ce3          	bne	s1,a4,800044ea <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800044f6:	00024517          	auipc	a0,0x24
    800044fa:	41250513          	addi	a0,a0,1042 # 80028908 <ftable>
    800044fe:	ffffc097          	auipc	ra,0xffffc
    80004502:	7fe080e7          	jalr	2046(ra) # 80000cfc <release>
  return 0;
    80004506:	4481                	li	s1,0
    80004508:	a819                	j	8000451e <filealloc+0x5e>
      f->ref = 1;
    8000450a:	4785                	li	a5,1
    8000450c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000450e:	00024517          	auipc	a0,0x24
    80004512:	3fa50513          	addi	a0,a0,1018 # 80028908 <ftable>
    80004516:	ffffc097          	auipc	ra,0xffffc
    8000451a:	7e6080e7          	jalr	2022(ra) # 80000cfc <release>
}
    8000451e:	8526                	mv	a0,s1
    80004520:	60e2                	ld	ra,24(sp)
    80004522:	6442                	ld	s0,16(sp)
    80004524:	64a2                	ld	s1,8(sp)
    80004526:	6105                	addi	sp,sp,32
    80004528:	8082                	ret

000000008000452a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000452a:	1101                	addi	sp,sp,-32
    8000452c:	ec06                	sd	ra,24(sp)
    8000452e:	e822                	sd	s0,16(sp)
    80004530:	e426                	sd	s1,8(sp)
    80004532:	1000                	addi	s0,sp,32
    80004534:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004536:	00024517          	auipc	a0,0x24
    8000453a:	3d250513          	addi	a0,a0,978 # 80028908 <ftable>
    8000453e:	ffffc097          	auipc	ra,0xffffc
    80004542:	70a080e7          	jalr	1802(ra) # 80000c48 <acquire>
  if(f->ref < 1)
    80004546:	40dc                	lw	a5,4(s1)
    80004548:	02f05263          	blez	a5,8000456c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000454c:	2785                	addiw	a5,a5,1
    8000454e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004550:	00024517          	auipc	a0,0x24
    80004554:	3b850513          	addi	a0,a0,952 # 80028908 <ftable>
    80004558:	ffffc097          	auipc	ra,0xffffc
    8000455c:	7a4080e7          	jalr	1956(ra) # 80000cfc <release>
  return f;
}
    80004560:	8526                	mv	a0,s1
    80004562:	60e2                	ld	ra,24(sp)
    80004564:	6442                	ld	s0,16(sp)
    80004566:	64a2                	ld	s1,8(sp)
    80004568:	6105                	addi	sp,sp,32
    8000456a:	8082                	ret
    panic("filedup");
    8000456c:	00004517          	auipc	a0,0x4
    80004570:	12c50513          	addi	a0,a0,300 # 80008698 <syscalls+0x240>
    80004574:	ffffc097          	auipc	ra,0xffffc
    80004578:	fcc080e7          	jalr	-52(ra) # 80000540 <panic>

000000008000457c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000457c:	7139                	addi	sp,sp,-64
    8000457e:	fc06                	sd	ra,56(sp)
    80004580:	f822                	sd	s0,48(sp)
    80004582:	f426                	sd	s1,40(sp)
    80004584:	f04a                	sd	s2,32(sp)
    80004586:	ec4e                	sd	s3,24(sp)
    80004588:	e852                	sd	s4,16(sp)
    8000458a:	e456                	sd	s5,8(sp)
    8000458c:	0080                	addi	s0,sp,64
    8000458e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004590:	00024517          	auipc	a0,0x24
    80004594:	37850513          	addi	a0,a0,888 # 80028908 <ftable>
    80004598:	ffffc097          	auipc	ra,0xffffc
    8000459c:	6b0080e7          	jalr	1712(ra) # 80000c48 <acquire>
  if(f->ref < 1)
    800045a0:	40dc                	lw	a5,4(s1)
    800045a2:	06f05163          	blez	a5,80004604 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045a6:	37fd                	addiw	a5,a5,-1
    800045a8:	0007871b          	sext.w	a4,a5
    800045ac:	c0dc                	sw	a5,4(s1)
    800045ae:	06e04363          	bgtz	a4,80004614 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045b2:	0004a903          	lw	s2,0(s1)
    800045b6:	0094ca83          	lbu	s5,9(s1)
    800045ba:	0104ba03          	ld	s4,16(s1)
    800045be:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045c2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045c6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800045ca:	00024517          	auipc	a0,0x24
    800045ce:	33e50513          	addi	a0,a0,830 # 80028908 <ftable>
    800045d2:	ffffc097          	auipc	ra,0xffffc
    800045d6:	72a080e7          	jalr	1834(ra) # 80000cfc <release>

  if(ff.type == FD_PIPE){
    800045da:	4785                	li	a5,1
    800045dc:	04f90d63          	beq	s2,a5,80004636 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800045e0:	3979                	addiw	s2,s2,-2
    800045e2:	4785                	li	a5,1
    800045e4:	0527e063          	bltu	a5,s2,80004624 <fileclose+0xa8>
    begin_op();
    800045e8:	00000097          	auipc	ra,0x0
    800045ec:	ad0080e7          	jalr	-1328(ra) # 800040b8 <begin_op>
    iput(ff.ip);
    800045f0:	854e                	mv	a0,s3
    800045f2:	fffff097          	auipc	ra,0xfffff
    800045f6:	2da080e7          	jalr	730(ra) # 800038cc <iput>
    end_op();
    800045fa:	00000097          	auipc	ra,0x0
    800045fe:	b38080e7          	jalr	-1224(ra) # 80004132 <end_op>
    80004602:	a00d                	j	80004624 <fileclose+0xa8>
    panic("fileclose");
    80004604:	00004517          	auipc	a0,0x4
    80004608:	09c50513          	addi	a0,a0,156 # 800086a0 <syscalls+0x248>
    8000460c:	ffffc097          	auipc	ra,0xffffc
    80004610:	f34080e7          	jalr	-204(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004614:	00024517          	auipc	a0,0x24
    80004618:	2f450513          	addi	a0,a0,756 # 80028908 <ftable>
    8000461c:	ffffc097          	auipc	ra,0xffffc
    80004620:	6e0080e7          	jalr	1760(ra) # 80000cfc <release>
  }
}
    80004624:	70e2                	ld	ra,56(sp)
    80004626:	7442                	ld	s0,48(sp)
    80004628:	74a2                	ld	s1,40(sp)
    8000462a:	7902                	ld	s2,32(sp)
    8000462c:	69e2                	ld	s3,24(sp)
    8000462e:	6a42                	ld	s4,16(sp)
    80004630:	6aa2                	ld	s5,8(sp)
    80004632:	6121                	addi	sp,sp,64
    80004634:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004636:	85d6                	mv	a1,s5
    80004638:	8552                	mv	a0,s4
    8000463a:	00000097          	auipc	ra,0x0
    8000463e:	348080e7          	jalr	840(ra) # 80004982 <pipeclose>
    80004642:	b7cd                	j	80004624 <fileclose+0xa8>

0000000080004644 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004644:	715d                	addi	sp,sp,-80
    80004646:	e486                	sd	ra,72(sp)
    80004648:	e0a2                	sd	s0,64(sp)
    8000464a:	fc26                	sd	s1,56(sp)
    8000464c:	f84a                	sd	s2,48(sp)
    8000464e:	f44e                	sd	s3,40(sp)
    80004650:	0880                	addi	s0,sp,80
    80004652:	84aa                	mv	s1,a0
    80004654:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004656:	ffffd097          	auipc	ra,0xffffd
    8000465a:	3ce080e7          	jalr	974(ra) # 80001a24 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000465e:	409c                	lw	a5,0(s1)
    80004660:	37f9                	addiw	a5,a5,-2
    80004662:	4705                	li	a4,1
    80004664:	04f76763          	bltu	a4,a5,800046b2 <filestat+0x6e>
    80004668:	892a                	mv	s2,a0
    ilock(f->ip);
    8000466a:	6c88                	ld	a0,24(s1)
    8000466c:	fffff097          	auipc	ra,0xfffff
    80004670:	0a6080e7          	jalr	166(ra) # 80003712 <ilock>
    stati(f->ip, &st);
    80004674:	fb840593          	addi	a1,s0,-72
    80004678:	6c88                	ld	a0,24(s1)
    8000467a:	fffff097          	auipc	ra,0xfffff
    8000467e:	322080e7          	jalr	802(ra) # 8000399c <stati>
    iunlock(f->ip);
    80004682:	6c88                	ld	a0,24(s1)
    80004684:	fffff097          	auipc	ra,0xfffff
    80004688:	150080e7          	jalr	336(ra) # 800037d4 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000468c:	46e1                	li	a3,24
    8000468e:	fb840613          	addi	a2,s0,-72
    80004692:	85ce                	mv	a1,s3
    80004694:	05093503          	ld	a0,80(s2)
    80004698:	ffffd097          	auipc	ra,0xffffd
    8000469c:	04c080e7          	jalr	76(ra) # 800016e4 <copyout>
    800046a0:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046a4:	60a6                	ld	ra,72(sp)
    800046a6:	6406                	ld	s0,64(sp)
    800046a8:	74e2                	ld	s1,56(sp)
    800046aa:	7942                	ld	s2,48(sp)
    800046ac:	79a2                	ld	s3,40(sp)
    800046ae:	6161                	addi	sp,sp,80
    800046b0:	8082                	ret
  return -1;
    800046b2:	557d                	li	a0,-1
    800046b4:	bfc5                	j	800046a4 <filestat+0x60>

00000000800046b6 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046b6:	7179                	addi	sp,sp,-48
    800046b8:	f406                	sd	ra,40(sp)
    800046ba:	f022                	sd	s0,32(sp)
    800046bc:	ec26                	sd	s1,24(sp)
    800046be:	e84a                	sd	s2,16(sp)
    800046c0:	e44e                	sd	s3,8(sp)
    800046c2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046c4:	00854783          	lbu	a5,8(a0)
    800046c8:	c3d5                	beqz	a5,8000476c <fileread+0xb6>
    800046ca:	84aa                	mv	s1,a0
    800046cc:	89ae                	mv	s3,a1
    800046ce:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800046d0:	411c                	lw	a5,0(a0)
    800046d2:	4705                	li	a4,1
    800046d4:	04e78963          	beq	a5,a4,80004726 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046d8:	470d                	li	a4,3
    800046da:	04e78d63          	beq	a5,a4,80004734 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800046de:	4709                	li	a4,2
    800046e0:	06e79e63          	bne	a5,a4,8000475c <fileread+0xa6>
    ilock(f->ip);
    800046e4:	6d08                	ld	a0,24(a0)
    800046e6:	fffff097          	auipc	ra,0xfffff
    800046ea:	02c080e7          	jalr	44(ra) # 80003712 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800046ee:	874a                	mv	a4,s2
    800046f0:	5094                	lw	a3,32(s1)
    800046f2:	864e                	mv	a2,s3
    800046f4:	4585                	li	a1,1
    800046f6:	6c88                	ld	a0,24(s1)
    800046f8:	fffff097          	auipc	ra,0xfffff
    800046fc:	2ce080e7          	jalr	718(ra) # 800039c6 <readi>
    80004700:	892a                	mv	s2,a0
    80004702:	00a05563          	blez	a0,8000470c <fileread+0x56>
      f->off += r;
    80004706:	509c                	lw	a5,32(s1)
    80004708:	9fa9                	addw	a5,a5,a0
    8000470a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000470c:	6c88                	ld	a0,24(s1)
    8000470e:	fffff097          	auipc	ra,0xfffff
    80004712:	0c6080e7          	jalr	198(ra) # 800037d4 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004716:	854a                	mv	a0,s2
    80004718:	70a2                	ld	ra,40(sp)
    8000471a:	7402                	ld	s0,32(sp)
    8000471c:	64e2                	ld	s1,24(sp)
    8000471e:	6942                	ld	s2,16(sp)
    80004720:	69a2                	ld	s3,8(sp)
    80004722:	6145                	addi	sp,sp,48
    80004724:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004726:	6908                	ld	a0,16(a0)
    80004728:	00000097          	auipc	ra,0x0
    8000472c:	3c2080e7          	jalr	962(ra) # 80004aea <piperead>
    80004730:	892a                	mv	s2,a0
    80004732:	b7d5                	j	80004716 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004734:	02451783          	lh	a5,36(a0)
    80004738:	03079693          	slli	a3,a5,0x30
    8000473c:	92c1                	srli	a3,a3,0x30
    8000473e:	4725                	li	a4,9
    80004740:	02d76863          	bltu	a4,a3,80004770 <fileread+0xba>
    80004744:	0792                	slli	a5,a5,0x4
    80004746:	00024717          	auipc	a4,0x24
    8000474a:	12270713          	addi	a4,a4,290 # 80028868 <devsw>
    8000474e:	97ba                	add	a5,a5,a4
    80004750:	639c                	ld	a5,0(a5)
    80004752:	c38d                	beqz	a5,80004774 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004754:	4505                	li	a0,1
    80004756:	9782                	jalr	a5
    80004758:	892a                	mv	s2,a0
    8000475a:	bf75                	j	80004716 <fileread+0x60>
    panic("fileread");
    8000475c:	00004517          	auipc	a0,0x4
    80004760:	f5450513          	addi	a0,a0,-172 # 800086b0 <syscalls+0x258>
    80004764:	ffffc097          	auipc	ra,0xffffc
    80004768:	ddc080e7          	jalr	-548(ra) # 80000540 <panic>
    return -1;
    8000476c:	597d                	li	s2,-1
    8000476e:	b765                	j	80004716 <fileread+0x60>
      return -1;
    80004770:	597d                	li	s2,-1
    80004772:	b755                	j	80004716 <fileread+0x60>
    80004774:	597d                	li	s2,-1
    80004776:	b745                	j	80004716 <fileread+0x60>

0000000080004778 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004778:	00954783          	lbu	a5,9(a0)
    8000477c:	10078e63          	beqz	a5,80004898 <filewrite+0x120>
{
    80004780:	715d                	addi	sp,sp,-80
    80004782:	e486                	sd	ra,72(sp)
    80004784:	e0a2                	sd	s0,64(sp)
    80004786:	fc26                	sd	s1,56(sp)
    80004788:	f84a                	sd	s2,48(sp)
    8000478a:	f44e                	sd	s3,40(sp)
    8000478c:	f052                	sd	s4,32(sp)
    8000478e:	ec56                	sd	s5,24(sp)
    80004790:	e85a                	sd	s6,16(sp)
    80004792:	e45e                	sd	s7,8(sp)
    80004794:	e062                	sd	s8,0(sp)
    80004796:	0880                	addi	s0,sp,80
    80004798:	892a                	mv	s2,a0
    8000479a:	8b2e                	mv	s6,a1
    8000479c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000479e:	411c                	lw	a5,0(a0)
    800047a0:	4705                	li	a4,1
    800047a2:	02e78263          	beq	a5,a4,800047c6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047a6:	470d                	li	a4,3
    800047a8:	02e78563          	beq	a5,a4,800047d2 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047ac:	4709                	li	a4,2
    800047ae:	0ce79d63          	bne	a5,a4,80004888 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047b2:	0ac05b63          	blez	a2,80004868 <filewrite+0xf0>
    int i = 0;
    800047b6:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    800047b8:	6b85                	lui	s7,0x1
    800047ba:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800047be:	6c05                	lui	s8,0x1
    800047c0:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800047c4:	a851                	j	80004858 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800047c6:	6908                	ld	a0,16(a0)
    800047c8:	00000097          	auipc	ra,0x0
    800047cc:	22a080e7          	jalr	554(ra) # 800049f2 <pipewrite>
    800047d0:	a045                	j	80004870 <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800047d2:	02451783          	lh	a5,36(a0)
    800047d6:	03079693          	slli	a3,a5,0x30
    800047da:	92c1                	srli	a3,a3,0x30
    800047dc:	4725                	li	a4,9
    800047de:	0ad76f63          	bltu	a4,a3,8000489c <filewrite+0x124>
    800047e2:	0792                	slli	a5,a5,0x4
    800047e4:	00024717          	auipc	a4,0x24
    800047e8:	08470713          	addi	a4,a4,132 # 80028868 <devsw>
    800047ec:	97ba                	add	a5,a5,a4
    800047ee:	679c                	ld	a5,8(a5)
    800047f0:	cbc5                	beqz	a5,800048a0 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    800047f2:	4505                	li	a0,1
    800047f4:	9782                	jalr	a5
    800047f6:	a8ad                	j	80004870 <filewrite+0xf8>
      if(n1 > max)
    800047f8:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    800047fc:	00000097          	auipc	ra,0x0
    80004800:	8bc080e7          	jalr	-1860(ra) # 800040b8 <begin_op>
      ilock(f->ip);
    80004804:	01893503          	ld	a0,24(s2)
    80004808:	fffff097          	auipc	ra,0xfffff
    8000480c:	f0a080e7          	jalr	-246(ra) # 80003712 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004810:	8756                	mv	a4,s5
    80004812:	02092683          	lw	a3,32(s2)
    80004816:	01698633          	add	a2,s3,s6
    8000481a:	4585                	li	a1,1
    8000481c:	01893503          	ld	a0,24(s2)
    80004820:	fffff097          	auipc	ra,0xfffff
    80004824:	29e080e7          	jalr	670(ra) # 80003abe <writei>
    80004828:	84aa                	mv	s1,a0
    8000482a:	00a05763          	blez	a0,80004838 <filewrite+0xc0>
        f->off += r;
    8000482e:	02092783          	lw	a5,32(s2)
    80004832:	9fa9                	addw	a5,a5,a0
    80004834:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004838:	01893503          	ld	a0,24(s2)
    8000483c:	fffff097          	auipc	ra,0xfffff
    80004840:	f98080e7          	jalr	-104(ra) # 800037d4 <iunlock>
      end_op();
    80004844:	00000097          	auipc	ra,0x0
    80004848:	8ee080e7          	jalr	-1810(ra) # 80004132 <end_op>

      if(r != n1){
    8000484c:	009a9f63          	bne	s5,s1,8000486a <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004850:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004854:	0149db63          	bge	s3,s4,8000486a <filewrite+0xf2>
      int n1 = n - i;
    80004858:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    8000485c:	0004879b          	sext.w	a5,s1
    80004860:	f8fbdce3          	bge	s7,a5,800047f8 <filewrite+0x80>
    80004864:	84e2                	mv	s1,s8
    80004866:	bf49                	j	800047f8 <filewrite+0x80>
    int i = 0;
    80004868:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000486a:	033a1d63          	bne	s4,s3,800048a4 <filewrite+0x12c>
    8000486e:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004870:	60a6                	ld	ra,72(sp)
    80004872:	6406                	ld	s0,64(sp)
    80004874:	74e2                	ld	s1,56(sp)
    80004876:	7942                	ld	s2,48(sp)
    80004878:	79a2                	ld	s3,40(sp)
    8000487a:	7a02                	ld	s4,32(sp)
    8000487c:	6ae2                	ld	s5,24(sp)
    8000487e:	6b42                	ld	s6,16(sp)
    80004880:	6ba2                	ld	s7,8(sp)
    80004882:	6c02                	ld	s8,0(sp)
    80004884:	6161                	addi	sp,sp,80
    80004886:	8082                	ret
    panic("filewrite");
    80004888:	00004517          	auipc	a0,0x4
    8000488c:	e3850513          	addi	a0,a0,-456 # 800086c0 <syscalls+0x268>
    80004890:	ffffc097          	auipc	ra,0xffffc
    80004894:	cb0080e7          	jalr	-848(ra) # 80000540 <panic>
    return -1;
    80004898:	557d                	li	a0,-1
}
    8000489a:	8082                	ret
      return -1;
    8000489c:	557d                	li	a0,-1
    8000489e:	bfc9                	j	80004870 <filewrite+0xf8>
    800048a0:	557d                	li	a0,-1
    800048a2:	b7f9                	j	80004870 <filewrite+0xf8>
    ret = (i == n ? n : -1);
    800048a4:	557d                	li	a0,-1
    800048a6:	b7e9                	j	80004870 <filewrite+0xf8>

00000000800048a8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048a8:	7179                	addi	sp,sp,-48
    800048aa:	f406                	sd	ra,40(sp)
    800048ac:	f022                	sd	s0,32(sp)
    800048ae:	ec26                	sd	s1,24(sp)
    800048b0:	e84a                	sd	s2,16(sp)
    800048b2:	e44e                	sd	s3,8(sp)
    800048b4:	e052                	sd	s4,0(sp)
    800048b6:	1800                	addi	s0,sp,48
    800048b8:	84aa                	mv	s1,a0
    800048ba:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048bc:	0005b023          	sd	zero,0(a1)
    800048c0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048c4:	00000097          	auipc	ra,0x0
    800048c8:	bfc080e7          	jalr	-1028(ra) # 800044c0 <filealloc>
    800048cc:	e088                	sd	a0,0(s1)
    800048ce:	c551                	beqz	a0,8000495a <pipealloc+0xb2>
    800048d0:	00000097          	auipc	ra,0x0
    800048d4:	bf0080e7          	jalr	-1040(ra) # 800044c0 <filealloc>
    800048d8:	00aa3023          	sd	a0,0(s4)
    800048dc:	c92d                	beqz	a0,8000494e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800048de:	ffffc097          	auipc	ra,0xffffc
    800048e2:	27a080e7          	jalr	634(ra) # 80000b58 <kalloc>
    800048e6:	892a                	mv	s2,a0
    800048e8:	c125                	beqz	a0,80004948 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800048ea:	4985                	li	s3,1
    800048ec:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800048f0:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800048f4:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800048f8:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800048fc:	00004597          	auipc	a1,0x4
    80004900:	dd458593          	addi	a1,a1,-556 # 800086d0 <syscalls+0x278>
    80004904:	ffffc097          	auipc	ra,0xffffc
    80004908:	2b4080e7          	jalr	692(ra) # 80000bb8 <initlock>
  (*f0)->type = FD_PIPE;
    8000490c:	609c                	ld	a5,0(s1)
    8000490e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004912:	609c                	ld	a5,0(s1)
    80004914:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004918:	609c                	ld	a5,0(s1)
    8000491a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000491e:	609c                	ld	a5,0(s1)
    80004920:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004924:	000a3783          	ld	a5,0(s4)
    80004928:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000492c:	000a3783          	ld	a5,0(s4)
    80004930:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004934:	000a3783          	ld	a5,0(s4)
    80004938:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000493c:	000a3783          	ld	a5,0(s4)
    80004940:	0127b823          	sd	s2,16(a5)
  return 0;
    80004944:	4501                	li	a0,0
    80004946:	a025                	j	8000496e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004948:	6088                	ld	a0,0(s1)
    8000494a:	e501                	bnez	a0,80004952 <pipealloc+0xaa>
    8000494c:	a039                	j	8000495a <pipealloc+0xb2>
    8000494e:	6088                	ld	a0,0(s1)
    80004950:	c51d                	beqz	a0,8000497e <pipealloc+0xd6>
    fileclose(*f0);
    80004952:	00000097          	auipc	ra,0x0
    80004956:	c2a080e7          	jalr	-982(ra) # 8000457c <fileclose>
  if(*f1)
    8000495a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000495e:	557d                	li	a0,-1
  if(*f1)
    80004960:	c799                	beqz	a5,8000496e <pipealloc+0xc6>
    fileclose(*f1);
    80004962:	853e                	mv	a0,a5
    80004964:	00000097          	auipc	ra,0x0
    80004968:	c18080e7          	jalr	-1000(ra) # 8000457c <fileclose>
  return -1;
    8000496c:	557d                	li	a0,-1
}
    8000496e:	70a2                	ld	ra,40(sp)
    80004970:	7402                	ld	s0,32(sp)
    80004972:	64e2                	ld	s1,24(sp)
    80004974:	6942                	ld	s2,16(sp)
    80004976:	69a2                	ld	s3,8(sp)
    80004978:	6a02                	ld	s4,0(sp)
    8000497a:	6145                	addi	sp,sp,48
    8000497c:	8082                	ret
  return -1;
    8000497e:	557d                	li	a0,-1
    80004980:	b7fd                	j	8000496e <pipealloc+0xc6>

0000000080004982 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004982:	1101                	addi	sp,sp,-32
    80004984:	ec06                	sd	ra,24(sp)
    80004986:	e822                	sd	s0,16(sp)
    80004988:	e426                	sd	s1,8(sp)
    8000498a:	e04a                	sd	s2,0(sp)
    8000498c:	1000                	addi	s0,sp,32
    8000498e:	84aa                	mv	s1,a0
    80004990:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004992:	ffffc097          	auipc	ra,0xffffc
    80004996:	2b6080e7          	jalr	694(ra) # 80000c48 <acquire>
  if(writable){
    8000499a:	02090d63          	beqz	s2,800049d4 <pipeclose+0x52>
    pi->writeopen = 0;
    8000499e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049a2:	21848513          	addi	a0,s1,536
    800049a6:	ffffd097          	auipc	ra,0xffffd
    800049aa:	7c4080e7          	jalr	1988(ra) # 8000216a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049ae:	2204b783          	ld	a5,544(s1)
    800049b2:	eb95                	bnez	a5,800049e6 <pipeclose+0x64>
    release(&pi->lock);
    800049b4:	8526                	mv	a0,s1
    800049b6:	ffffc097          	auipc	ra,0xffffc
    800049ba:	346080e7          	jalr	838(ra) # 80000cfc <release>
    kfree((char*)pi);
    800049be:	8526                	mv	a0,s1
    800049c0:	ffffc097          	auipc	ra,0xffffc
    800049c4:	09a080e7          	jalr	154(ra) # 80000a5a <kfree>
  } else
    release(&pi->lock);
}
    800049c8:	60e2                	ld	ra,24(sp)
    800049ca:	6442                	ld	s0,16(sp)
    800049cc:	64a2                	ld	s1,8(sp)
    800049ce:	6902                	ld	s2,0(sp)
    800049d0:	6105                	addi	sp,sp,32
    800049d2:	8082                	ret
    pi->readopen = 0;
    800049d4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800049d8:	21c48513          	addi	a0,s1,540
    800049dc:	ffffd097          	auipc	ra,0xffffd
    800049e0:	78e080e7          	jalr	1934(ra) # 8000216a <wakeup>
    800049e4:	b7e9                	j	800049ae <pipeclose+0x2c>
    release(&pi->lock);
    800049e6:	8526                	mv	a0,s1
    800049e8:	ffffc097          	auipc	ra,0xffffc
    800049ec:	314080e7          	jalr	788(ra) # 80000cfc <release>
}
    800049f0:	bfe1                	j	800049c8 <pipeclose+0x46>

00000000800049f2 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800049f2:	711d                	addi	sp,sp,-96
    800049f4:	ec86                	sd	ra,88(sp)
    800049f6:	e8a2                	sd	s0,80(sp)
    800049f8:	e4a6                	sd	s1,72(sp)
    800049fa:	e0ca                	sd	s2,64(sp)
    800049fc:	fc4e                	sd	s3,56(sp)
    800049fe:	f852                	sd	s4,48(sp)
    80004a00:	f456                	sd	s5,40(sp)
    80004a02:	f05a                	sd	s6,32(sp)
    80004a04:	ec5e                	sd	s7,24(sp)
    80004a06:	e862                	sd	s8,16(sp)
    80004a08:	1080                	addi	s0,sp,96
    80004a0a:	84aa                	mv	s1,a0
    80004a0c:	8aae                	mv	s5,a1
    80004a0e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a10:	ffffd097          	auipc	ra,0xffffd
    80004a14:	014080e7          	jalr	20(ra) # 80001a24 <myproc>
    80004a18:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a1a:	8526                	mv	a0,s1
    80004a1c:	ffffc097          	auipc	ra,0xffffc
    80004a20:	22c080e7          	jalr	556(ra) # 80000c48 <acquire>
  while(i < n){
    80004a24:	0b405663          	blez	s4,80004ad0 <pipewrite+0xde>
  int i = 0;
    80004a28:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a2a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a2c:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a30:	21c48b93          	addi	s7,s1,540
    80004a34:	a089                	j	80004a76 <pipewrite+0x84>
      release(&pi->lock);
    80004a36:	8526                	mv	a0,s1
    80004a38:	ffffc097          	auipc	ra,0xffffc
    80004a3c:	2c4080e7          	jalr	708(ra) # 80000cfc <release>
      return -1;
    80004a40:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a42:	854a                	mv	a0,s2
    80004a44:	60e6                	ld	ra,88(sp)
    80004a46:	6446                	ld	s0,80(sp)
    80004a48:	64a6                	ld	s1,72(sp)
    80004a4a:	6906                	ld	s2,64(sp)
    80004a4c:	79e2                	ld	s3,56(sp)
    80004a4e:	7a42                	ld	s4,48(sp)
    80004a50:	7aa2                	ld	s5,40(sp)
    80004a52:	7b02                	ld	s6,32(sp)
    80004a54:	6be2                	ld	s7,24(sp)
    80004a56:	6c42                	ld	s8,16(sp)
    80004a58:	6125                	addi	sp,sp,96
    80004a5a:	8082                	ret
      wakeup(&pi->nread);
    80004a5c:	8562                	mv	a0,s8
    80004a5e:	ffffd097          	auipc	ra,0xffffd
    80004a62:	70c080e7          	jalr	1804(ra) # 8000216a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a66:	85a6                	mv	a1,s1
    80004a68:	855e                	mv	a0,s7
    80004a6a:	ffffd097          	auipc	ra,0xffffd
    80004a6e:	69c080e7          	jalr	1692(ra) # 80002106 <sleep>
  while(i < n){
    80004a72:	07495063          	bge	s2,s4,80004ad2 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004a76:	2204a783          	lw	a5,544(s1)
    80004a7a:	dfd5                	beqz	a5,80004a36 <pipewrite+0x44>
    80004a7c:	854e                	mv	a0,s3
    80004a7e:	ffffe097          	auipc	ra,0xffffe
    80004a82:	930080e7          	jalr	-1744(ra) # 800023ae <killed>
    80004a86:	f945                	bnez	a0,80004a36 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004a88:	2184a783          	lw	a5,536(s1)
    80004a8c:	21c4a703          	lw	a4,540(s1)
    80004a90:	2007879b          	addiw	a5,a5,512
    80004a94:	fcf704e3          	beq	a4,a5,80004a5c <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a98:	4685                	li	a3,1
    80004a9a:	01590633          	add	a2,s2,s5
    80004a9e:	faf40593          	addi	a1,s0,-81
    80004aa2:	0509b503          	ld	a0,80(s3)
    80004aa6:	ffffd097          	auipc	ra,0xffffd
    80004aaa:	cca080e7          	jalr	-822(ra) # 80001770 <copyin>
    80004aae:	03650263          	beq	a0,s6,80004ad2 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ab2:	21c4a783          	lw	a5,540(s1)
    80004ab6:	0017871b          	addiw	a4,a5,1
    80004aba:	20e4ae23          	sw	a4,540(s1)
    80004abe:	1ff7f793          	andi	a5,a5,511
    80004ac2:	97a6                	add	a5,a5,s1
    80004ac4:	faf44703          	lbu	a4,-81(s0)
    80004ac8:	00e78c23          	sb	a4,24(a5)
      i++;
    80004acc:	2905                	addiw	s2,s2,1
    80004ace:	b755                	j	80004a72 <pipewrite+0x80>
  int i = 0;
    80004ad0:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004ad2:	21848513          	addi	a0,s1,536
    80004ad6:	ffffd097          	auipc	ra,0xffffd
    80004ada:	694080e7          	jalr	1684(ra) # 8000216a <wakeup>
  release(&pi->lock);
    80004ade:	8526                	mv	a0,s1
    80004ae0:	ffffc097          	auipc	ra,0xffffc
    80004ae4:	21c080e7          	jalr	540(ra) # 80000cfc <release>
  return i;
    80004ae8:	bfa9                	j	80004a42 <pipewrite+0x50>

0000000080004aea <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004aea:	715d                	addi	sp,sp,-80
    80004aec:	e486                	sd	ra,72(sp)
    80004aee:	e0a2                	sd	s0,64(sp)
    80004af0:	fc26                	sd	s1,56(sp)
    80004af2:	f84a                	sd	s2,48(sp)
    80004af4:	f44e                	sd	s3,40(sp)
    80004af6:	f052                	sd	s4,32(sp)
    80004af8:	ec56                	sd	s5,24(sp)
    80004afa:	e85a                	sd	s6,16(sp)
    80004afc:	0880                	addi	s0,sp,80
    80004afe:	84aa                	mv	s1,a0
    80004b00:	892e                	mv	s2,a1
    80004b02:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b04:	ffffd097          	auipc	ra,0xffffd
    80004b08:	f20080e7          	jalr	-224(ra) # 80001a24 <myproc>
    80004b0c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b0e:	8526                	mv	a0,s1
    80004b10:	ffffc097          	auipc	ra,0xffffc
    80004b14:	138080e7          	jalr	312(ra) # 80000c48 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b18:	2184a703          	lw	a4,536(s1)
    80004b1c:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b20:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b24:	02f71763          	bne	a4,a5,80004b52 <piperead+0x68>
    80004b28:	2244a783          	lw	a5,548(s1)
    80004b2c:	c39d                	beqz	a5,80004b52 <piperead+0x68>
    if(killed(pr)){
    80004b2e:	8552                	mv	a0,s4
    80004b30:	ffffe097          	auipc	ra,0xffffe
    80004b34:	87e080e7          	jalr	-1922(ra) # 800023ae <killed>
    80004b38:	e949                	bnez	a0,80004bca <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b3a:	85a6                	mv	a1,s1
    80004b3c:	854e                	mv	a0,s3
    80004b3e:	ffffd097          	auipc	ra,0xffffd
    80004b42:	5c8080e7          	jalr	1480(ra) # 80002106 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b46:	2184a703          	lw	a4,536(s1)
    80004b4a:	21c4a783          	lw	a5,540(s1)
    80004b4e:	fcf70de3          	beq	a4,a5,80004b28 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b52:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b54:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b56:	05505463          	blez	s5,80004b9e <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004b5a:	2184a783          	lw	a5,536(s1)
    80004b5e:	21c4a703          	lw	a4,540(s1)
    80004b62:	02f70e63          	beq	a4,a5,80004b9e <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b66:	0017871b          	addiw	a4,a5,1
    80004b6a:	20e4ac23          	sw	a4,536(s1)
    80004b6e:	1ff7f793          	andi	a5,a5,511
    80004b72:	97a6                	add	a5,a5,s1
    80004b74:	0187c783          	lbu	a5,24(a5)
    80004b78:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b7c:	4685                	li	a3,1
    80004b7e:	fbf40613          	addi	a2,s0,-65
    80004b82:	85ca                	mv	a1,s2
    80004b84:	050a3503          	ld	a0,80(s4)
    80004b88:	ffffd097          	auipc	ra,0xffffd
    80004b8c:	b5c080e7          	jalr	-1188(ra) # 800016e4 <copyout>
    80004b90:	01650763          	beq	a0,s6,80004b9e <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b94:	2985                	addiw	s3,s3,1
    80004b96:	0905                	addi	s2,s2,1
    80004b98:	fd3a91e3          	bne	s5,s3,80004b5a <piperead+0x70>
    80004b9c:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b9e:	21c48513          	addi	a0,s1,540
    80004ba2:	ffffd097          	auipc	ra,0xffffd
    80004ba6:	5c8080e7          	jalr	1480(ra) # 8000216a <wakeup>
  release(&pi->lock);
    80004baa:	8526                	mv	a0,s1
    80004bac:	ffffc097          	auipc	ra,0xffffc
    80004bb0:	150080e7          	jalr	336(ra) # 80000cfc <release>
  return i;
}
    80004bb4:	854e                	mv	a0,s3
    80004bb6:	60a6                	ld	ra,72(sp)
    80004bb8:	6406                	ld	s0,64(sp)
    80004bba:	74e2                	ld	s1,56(sp)
    80004bbc:	7942                	ld	s2,48(sp)
    80004bbe:	79a2                	ld	s3,40(sp)
    80004bc0:	7a02                	ld	s4,32(sp)
    80004bc2:	6ae2                	ld	s5,24(sp)
    80004bc4:	6b42                	ld	s6,16(sp)
    80004bc6:	6161                	addi	sp,sp,80
    80004bc8:	8082                	ret
      release(&pi->lock);
    80004bca:	8526                	mv	a0,s1
    80004bcc:	ffffc097          	auipc	ra,0xffffc
    80004bd0:	130080e7          	jalr	304(ra) # 80000cfc <release>
      return -1;
    80004bd4:	59fd                	li	s3,-1
    80004bd6:	bff9                	j	80004bb4 <piperead+0xca>

0000000080004bd8 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004bd8:	1141                	addi	sp,sp,-16
    80004bda:	e422                	sd	s0,8(sp)
    80004bdc:	0800                	addi	s0,sp,16
    80004bde:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004be0:	8905                	andi	a0,a0,1
    80004be2:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004be4:	8b89                	andi	a5,a5,2
    80004be6:	c399                	beqz	a5,80004bec <flags2perm+0x14>
      perm |= PTE_W;
    80004be8:	00456513          	ori	a0,a0,4
    return perm;
}
    80004bec:	6422                	ld	s0,8(sp)
    80004bee:	0141                	addi	sp,sp,16
    80004bf0:	8082                	ret

0000000080004bf2 <exec>:

int
exec(char *path, char **argv)
{
    80004bf2:	df010113          	addi	sp,sp,-528
    80004bf6:	20113423          	sd	ra,520(sp)
    80004bfa:	20813023          	sd	s0,512(sp)
    80004bfe:	ffa6                	sd	s1,504(sp)
    80004c00:	fbca                	sd	s2,496(sp)
    80004c02:	f7ce                	sd	s3,488(sp)
    80004c04:	f3d2                	sd	s4,480(sp)
    80004c06:	efd6                	sd	s5,472(sp)
    80004c08:	ebda                	sd	s6,464(sp)
    80004c0a:	e7de                	sd	s7,456(sp)
    80004c0c:	e3e2                	sd	s8,448(sp)
    80004c0e:	ff66                	sd	s9,440(sp)
    80004c10:	fb6a                	sd	s10,432(sp)
    80004c12:	f76e                	sd	s11,424(sp)
    80004c14:	0c00                	addi	s0,sp,528
    80004c16:	892a                	mv	s2,a0
    80004c18:	dea43c23          	sd	a0,-520(s0)
    80004c1c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c20:	ffffd097          	auipc	ra,0xffffd
    80004c24:	e04080e7          	jalr	-508(ra) # 80001a24 <myproc>
    80004c28:	84aa                	mv	s1,a0

  begin_op();
    80004c2a:	fffff097          	auipc	ra,0xfffff
    80004c2e:	48e080e7          	jalr	1166(ra) # 800040b8 <begin_op>

  if((ip = namei(path)) == 0){
    80004c32:	854a                	mv	a0,s2
    80004c34:	fffff097          	auipc	ra,0xfffff
    80004c38:	284080e7          	jalr	644(ra) # 80003eb8 <namei>
    80004c3c:	c92d                	beqz	a0,80004cae <exec+0xbc>
    80004c3e:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c40:	fffff097          	auipc	ra,0xfffff
    80004c44:	ad2080e7          	jalr	-1326(ra) # 80003712 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c48:	04000713          	li	a4,64
    80004c4c:	4681                	li	a3,0
    80004c4e:	e5040613          	addi	a2,s0,-432
    80004c52:	4581                	li	a1,0
    80004c54:	8552                	mv	a0,s4
    80004c56:	fffff097          	auipc	ra,0xfffff
    80004c5a:	d70080e7          	jalr	-656(ra) # 800039c6 <readi>
    80004c5e:	04000793          	li	a5,64
    80004c62:	00f51a63          	bne	a0,a5,80004c76 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004c66:	e5042703          	lw	a4,-432(s0)
    80004c6a:	464c47b7          	lui	a5,0x464c4
    80004c6e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c72:	04f70463          	beq	a4,a5,80004cba <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c76:	8552                	mv	a0,s4
    80004c78:	fffff097          	auipc	ra,0xfffff
    80004c7c:	cfc080e7          	jalr	-772(ra) # 80003974 <iunlockput>
    end_op();
    80004c80:	fffff097          	auipc	ra,0xfffff
    80004c84:	4b2080e7          	jalr	1202(ra) # 80004132 <end_op>
  }
  return -1;
    80004c88:	557d                	li	a0,-1
}
    80004c8a:	20813083          	ld	ra,520(sp)
    80004c8e:	20013403          	ld	s0,512(sp)
    80004c92:	74fe                	ld	s1,504(sp)
    80004c94:	795e                	ld	s2,496(sp)
    80004c96:	79be                	ld	s3,488(sp)
    80004c98:	7a1e                	ld	s4,480(sp)
    80004c9a:	6afe                	ld	s5,472(sp)
    80004c9c:	6b5e                	ld	s6,464(sp)
    80004c9e:	6bbe                	ld	s7,456(sp)
    80004ca0:	6c1e                	ld	s8,448(sp)
    80004ca2:	7cfa                	ld	s9,440(sp)
    80004ca4:	7d5a                	ld	s10,432(sp)
    80004ca6:	7dba                	ld	s11,424(sp)
    80004ca8:	21010113          	addi	sp,sp,528
    80004cac:	8082                	ret
    end_op();
    80004cae:	fffff097          	auipc	ra,0xfffff
    80004cb2:	484080e7          	jalr	1156(ra) # 80004132 <end_op>
    return -1;
    80004cb6:	557d                	li	a0,-1
    80004cb8:	bfc9                	j	80004c8a <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004cba:	8526                	mv	a0,s1
    80004cbc:	ffffd097          	auipc	ra,0xffffd
    80004cc0:	e2c080e7          	jalr	-468(ra) # 80001ae8 <proc_pagetable>
    80004cc4:	8b2a                	mv	s6,a0
    80004cc6:	d945                	beqz	a0,80004c76 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cc8:	e7042d03          	lw	s10,-400(s0)
    80004ccc:	e8845783          	lhu	a5,-376(s0)
    80004cd0:	10078463          	beqz	a5,80004dd8 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004cd4:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cd6:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80004cd8:	6c85                	lui	s9,0x1
    80004cda:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004cde:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004ce2:	6a85                	lui	s5,0x1
    80004ce4:	a0b5                	j	80004d50 <exec+0x15e>
      panic("loadseg: address should exist");
    80004ce6:	00004517          	auipc	a0,0x4
    80004cea:	9f250513          	addi	a0,a0,-1550 # 800086d8 <syscalls+0x280>
    80004cee:	ffffc097          	auipc	ra,0xffffc
    80004cf2:	852080e7          	jalr	-1966(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
    80004cf6:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004cf8:	8726                	mv	a4,s1
    80004cfa:	012c06bb          	addw	a3,s8,s2
    80004cfe:	4581                	li	a1,0
    80004d00:	8552                	mv	a0,s4
    80004d02:	fffff097          	auipc	ra,0xfffff
    80004d06:	cc4080e7          	jalr	-828(ra) # 800039c6 <readi>
    80004d0a:	2501                	sext.w	a0,a0
    80004d0c:	2aa49b63          	bne	s1,a0,80004fc2 <exec+0x3d0>
  for(i = 0; i < sz; i += PGSIZE){
    80004d10:	012a893b          	addw	s2,s5,s2
    80004d14:	03397563          	bgeu	s2,s3,80004d3e <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80004d18:	02091593          	slli	a1,s2,0x20
    80004d1c:	9181                	srli	a1,a1,0x20
    80004d1e:	95de                	add	a1,a1,s7
    80004d20:	855a                	mv	a0,s6
    80004d22:	ffffc097          	auipc	ra,0xffffc
    80004d26:	3b2080e7          	jalr	946(ra) # 800010d4 <walkaddr>
    80004d2a:	862a                	mv	a2,a0
    if(pa == 0)
    80004d2c:	dd4d                	beqz	a0,80004ce6 <exec+0xf4>
    if(sz - i < PGSIZE)
    80004d2e:	412984bb          	subw	s1,s3,s2
    80004d32:	0004879b          	sext.w	a5,s1
    80004d36:	fcfcf0e3          	bgeu	s9,a5,80004cf6 <exec+0x104>
    80004d3a:	84d6                	mv	s1,s5
    80004d3c:	bf6d                	j	80004cf6 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004d3e:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d42:	2d85                	addiw	s11,s11,1
    80004d44:	038d0d1b          	addiw	s10,s10,56
    80004d48:	e8845783          	lhu	a5,-376(s0)
    80004d4c:	08fdd763          	bge	s11,a5,80004dda <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004d50:	2d01                	sext.w	s10,s10
    80004d52:	03800713          	li	a4,56
    80004d56:	86ea                	mv	a3,s10
    80004d58:	e1840613          	addi	a2,s0,-488
    80004d5c:	4581                	li	a1,0
    80004d5e:	8552                	mv	a0,s4
    80004d60:	fffff097          	auipc	ra,0xfffff
    80004d64:	c66080e7          	jalr	-922(ra) # 800039c6 <readi>
    80004d68:	03800793          	li	a5,56
    80004d6c:	24f51963          	bne	a0,a5,80004fbe <exec+0x3cc>
    if(ph.type != ELF_PROG_LOAD)
    80004d70:	e1842783          	lw	a5,-488(s0)
    80004d74:	4705                	li	a4,1
    80004d76:	fce796e3          	bne	a5,a4,80004d42 <exec+0x150>
    if(ph.memsz < ph.filesz)
    80004d7a:	e4043483          	ld	s1,-448(s0)
    80004d7e:	e3843783          	ld	a5,-456(s0)
    80004d82:	24f4eb63          	bltu	s1,a5,80004fd8 <exec+0x3e6>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004d86:	e2843783          	ld	a5,-472(s0)
    80004d8a:	94be                	add	s1,s1,a5
    80004d8c:	24f4e963          	bltu	s1,a5,80004fde <exec+0x3ec>
    if(ph.vaddr % PGSIZE != 0)
    80004d90:	df043703          	ld	a4,-528(s0)
    80004d94:	8ff9                	and	a5,a5,a4
    80004d96:	24079763          	bnez	a5,80004fe4 <exec+0x3f2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004d9a:	e1c42503          	lw	a0,-484(s0)
    80004d9e:	00000097          	auipc	ra,0x0
    80004da2:	e3a080e7          	jalr	-454(ra) # 80004bd8 <flags2perm>
    80004da6:	86aa                	mv	a3,a0
    80004da8:	8626                	mv	a2,s1
    80004daa:	85ca                	mv	a1,s2
    80004dac:	855a                	mv	a0,s6
    80004dae:	ffffc097          	auipc	ra,0xffffc
    80004db2:	6da080e7          	jalr	1754(ra) # 80001488 <uvmalloc>
    80004db6:	e0a43423          	sd	a0,-504(s0)
    80004dba:	22050863          	beqz	a0,80004fea <exec+0x3f8>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004dbe:	e2843b83          	ld	s7,-472(s0)
    80004dc2:	e2042c03          	lw	s8,-480(s0)
    80004dc6:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004dca:	00098463          	beqz	s3,80004dd2 <exec+0x1e0>
    80004dce:	4901                	li	s2,0
    80004dd0:	b7a1                	j	80004d18 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004dd2:	e0843903          	ld	s2,-504(s0)
    80004dd6:	b7b5                	j	80004d42 <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004dd8:	4901                	li	s2,0
  iunlockput(ip);
    80004dda:	8552                	mv	a0,s4
    80004ddc:	fffff097          	auipc	ra,0xfffff
    80004de0:	b98080e7          	jalr	-1128(ra) # 80003974 <iunlockput>
  end_op();
    80004de4:	fffff097          	auipc	ra,0xfffff
    80004de8:	34e080e7          	jalr	846(ra) # 80004132 <end_op>
  p = myproc();
    80004dec:	ffffd097          	auipc	ra,0xffffd
    80004df0:	c38080e7          	jalr	-968(ra) # 80001a24 <myproc>
    80004df4:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004df6:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80004dfa:	6985                	lui	s3,0x1
    80004dfc:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80004dfe:	99ca                	add	s3,s3,s2
    80004e00:	77fd                	lui	a5,0xfffff
    80004e02:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e06:	4691                	li	a3,4
    80004e08:	6609                	lui	a2,0x2
    80004e0a:	964e                	add	a2,a2,s3
    80004e0c:	85ce                	mv	a1,s3
    80004e0e:	855a                	mv	a0,s6
    80004e10:	ffffc097          	auipc	ra,0xffffc
    80004e14:	678080e7          	jalr	1656(ra) # 80001488 <uvmalloc>
    80004e18:	892a                	mv	s2,a0
    80004e1a:	e0a43423          	sd	a0,-504(s0)
    80004e1e:	e509                	bnez	a0,80004e28 <exec+0x236>
  if(pagetable)
    80004e20:	e1343423          	sd	s3,-504(s0)
    80004e24:	4a01                	li	s4,0
    80004e26:	aa71                	j	80004fc2 <exec+0x3d0>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e28:	75f9                	lui	a1,0xffffe
    80004e2a:	95aa                	add	a1,a1,a0
    80004e2c:	855a                	mv	a0,s6
    80004e2e:	ffffd097          	auipc	ra,0xffffd
    80004e32:	884080e7          	jalr	-1916(ra) # 800016b2 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e36:	7bfd                	lui	s7,0xfffff
    80004e38:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80004e3a:	e0043783          	ld	a5,-512(s0)
    80004e3e:	6388                	ld	a0,0(a5)
    80004e40:	c52d                	beqz	a0,80004eaa <exec+0x2b8>
    80004e42:	e9040993          	addi	s3,s0,-368
    80004e46:	f9040c13          	addi	s8,s0,-112
    80004e4a:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e4c:	ffffc097          	auipc	ra,0xffffc
    80004e50:	072080e7          	jalr	114(ra) # 80000ebe <strlen>
    80004e54:	0015079b          	addiw	a5,a0,1
    80004e58:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e5c:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004e60:	19796863          	bltu	s2,s7,80004ff0 <exec+0x3fe>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e64:	e0043d03          	ld	s10,-512(s0)
    80004e68:	000d3a03          	ld	s4,0(s10)
    80004e6c:	8552                	mv	a0,s4
    80004e6e:	ffffc097          	auipc	ra,0xffffc
    80004e72:	050080e7          	jalr	80(ra) # 80000ebe <strlen>
    80004e76:	0015069b          	addiw	a3,a0,1
    80004e7a:	8652                	mv	a2,s4
    80004e7c:	85ca                	mv	a1,s2
    80004e7e:	855a                	mv	a0,s6
    80004e80:	ffffd097          	auipc	ra,0xffffd
    80004e84:	864080e7          	jalr	-1948(ra) # 800016e4 <copyout>
    80004e88:	16054663          	bltz	a0,80004ff4 <exec+0x402>
    ustack[argc] = sp;
    80004e8c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e90:	0485                	addi	s1,s1,1
    80004e92:	008d0793          	addi	a5,s10,8
    80004e96:	e0f43023          	sd	a5,-512(s0)
    80004e9a:	008d3503          	ld	a0,8(s10)
    80004e9e:	c909                	beqz	a0,80004eb0 <exec+0x2be>
    if(argc >= MAXARG)
    80004ea0:	09a1                	addi	s3,s3,8
    80004ea2:	fb8995e3          	bne	s3,s8,80004e4c <exec+0x25a>
  ip = 0;
    80004ea6:	4a01                	li	s4,0
    80004ea8:	aa29                	j	80004fc2 <exec+0x3d0>
  sp = sz;
    80004eaa:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80004eae:	4481                	li	s1,0
  ustack[argc] = 0;
    80004eb0:	00349793          	slli	a5,s1,0x3
    80004eb4:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffd53c0>
    80004eb8:	97a2                	add	a5,a5,s0
    80004eba:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004ebe:	00148693          	addi	a3,s1,1
    80004ec2:	068e                	slli	a3,a3,0x3
    80004ec4:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ec8:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    80004ecc:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80004ed0:	f57968e3          	bltu	s2,s7,80004e20 <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ed4:	e9040613          	addi	a2,s0,-368
    80004ed8:	85ca                	mv	a1,s2
    80004eda:	855a                	mv	a0,s6
    80004edc:	ffffd097          	auipc	ra,0xffffd
    80004ee0:	808080e7          	jalr	-2040(ra) # 800016e4 <copyout>
    80004ee4:	10054a63          	bltz	a0,80004ff8 <exec+0x406>
  p->trapframe->a1 = sp;
    80004ee8:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80004eec:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004ef0:	df843783          	ld	a5,-520(s0)
    80004ef4:	0007c703          	lbu	a4,0(a5)
    80004ef8:	cf11                	beqz	a4,80004f14 <exec+0x322>
    80004efa:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004efc:	02f00693          	li	a3,47
    80004f00:	a039                	j	80004f0e <exec+0x31c>
      last = s+1;
    80004f02:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004f06:	0785                	addi	a5,a5,1
    80004f08:	fff7c703          	lbu	a4,-1(a5)
    80004f0c:	c701                	beqz	a4,80004f14 <exec+0x322>
    if(*s == '/')
    80004f0e:	fed71ce3          	bne	a4,a3,80004f06 <exec+0x314>
    80004f12:	bfc5                	j	80004f02 <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f14:	158a8993          	addi	s3,s5,344
    80004f18:	4641                	li	a2,16
    80004f1a:	df843583          	ld	a1,-520(s0)
    80004f1e:	854e                	mv	a0,s3
    80004f20:	ffffc097          	auipc	ra,0xffffc
    80004f24:	f6c080e7          	jalr	-148(ra) # 80000e8c <safestrcpy>
  oldpagetable = p->pagetable;
    80004f28:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f2c:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80004f30:	e0843783          	ld	a5,-504(s0)
    80004f34:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f38:	058ab783          	ld	a5,88(s5)
    80004f3c:	e6843703          	ld	a4,-408(s0)
    80004f40:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f42:	058ab783          	ld	a5,88(s5)
    80004f46:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f4a:	85e6                	mv	a1,s9
    80004f4c:	ffffd097          	auipc	ra,0xffffd
    80004f50:	c38080e7          	jalr	-968(ra) # 80001b84 <proc_freepagetable>
  if (strncmp(p->name, "vm-", 3) == 0) {
    80004f54:	460d                	li	a2,3
    80004f56:	00003597          	auipc	a1,0x3
    80004f5a:	2aa58593          	addi	a1,a1,682 # 80008200 <digits+0x1c0>
    80004f5e:	854e                	mv	a0,s3
    80004f60:	ffffc097          	auipc	ra,0xffffc
    80004f64:	eb4080e7          	jalr	-332(ra) # 80000e14 <strncmp>
    80004f68:	c501                	beqz	a0,80004f70 <exec+0x37e>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f6a:	0004851b          	sext.w	a0,s1
    80004f6e:	bb31                	j	80004c8a <exec+0x98>
    if((sz1 = uvmalloc(pagetable, memaddr, memaddr + 1024*PGSIZE, PTE_W)) == 0) {
    80004f70:	4691                	li	a3,4
    80004f72:	20100613          	li	a2,513
    80004f76:	065a                	slli	a2,a2,0x16
    80004f78:	4585                	li	a1,1
    80004f7a:	05fe                	slli	a1,a1,0x1f
    80004f7c:	855a                	mv	a0,s6
    80004f7e:	ffffc097          	auipc	ra,0xffffc
    80004f82:	50a080e7          	jalr	1290(ra) # 80001488 <uvmalloc>
    80004f86:	c10d                	beqz	a0,80004fa8 <exec+0x3b6>
    p->proc_te_vm = 1;
    80004f88:	4585                	li	a1,1
    80004f8a:	16baa423          	sw	a1,360(s5)
    printf("Created a VM process and allocated memory region (%p - %p).\n", memaddr, memaddr + 1024*PGSIZE);
    80004f8e:	20100613          	li	a2,513
    80004f92:	065a                	slli	a2,a2,0x16
    80004f94:	05fe                	slli	a1,a1,0x1f
    80004f96:	00003517          	auipc	a0,0x3
    80004f9a:	79a50513          	addi	a0,a0,1946 # 80008730 <syscalls+0x2d8>
    80004f9e:	ffffb097          	auipc	ra,0xffffb
    80004fa2:	5ec080e7          	jalr	1516(ra) # 8000058a <printf>
    80004fa6:	b7d1                	j	80004f6a <exec+0x378>
      printf("Error: could not allocate memory at 0x80000000 for VM.\n");
    80004fa8:	00003517          	auipc	a0,0x3
    80004fac:	75050513          	addi	a0,a0,1872 # 800086f8 <syscalls+0x2a0>
    80004fb0:	ffffb097          	auipc	ra,0xffffb
    80004fb4:	5da080e7          	jalr	1498(ra) # 8000058a <printf>
  sz = sz1;
    80004fb8:	e0843983          	ld	s3,-504(s0)
      goto bad;
    80004fbc:	b595                	j	80004e20 <exec+0x22e>
    80004fbe:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004fc2:	e0843583          	ld	a1,-504(s0)
    80004fc6:	855a                	mv	a0,s6
    80004fc8:	ffffd097          	auipc	ra,0xffffd
    80004fcc:	bbc080e7          	jalr	-1092(ra) # 80001b84 <proc_freepagetable>
  return -1;
    80004fd0:	557d                	li	a0,-1
  if(ip){
    80004fd2:	ca0a0ce3          	beqz	s4,80004c8a <exec+0x98>
    80004fd6:	b145                	j	80004c76 <exec+0x84>
    80004fd8:	e1243423          	sd	s2,-504(s0)
    80004fdc:	b7dd                	j	80004fc2 <exec+0x3d0>
    80004fde:	e1243423          	sd	s2,-504(s0)
    80004fe2:	b7c5                	j	80004fc2 <exec+0x3d0>
    80004fe4:	e1243423          	sd	s2,-504(s0)
    80004fe8:	bfe9                	j	80004fc2 <exec+0x3d0>
    80004fea:	e1243423          	sd	s2,-504(s0)
    80004fee:	bfd1                	j	80004fc2 <exec+0x3d0>
  ip = 0;
    80004ff0:	4a01                	li	s4,0
    80004ff2:	bfc1                	j	80004fc2 <exec+0x3d0>
    80004ff4:	4a01                	li	s4,0
  if(pagetable)
    80004ff6:	b7f1                	j	80004fc2 <exec+0x3d0>
  sz = sz1;
    80004ff8:	e0843983          	ld	s3,-504(s0)
    80004ffc:	b515                	j	80004e20 <exec+0x22e>

0000000080004ffe <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004ffe:	7179                	addi	sp,sp,-48
    80005000:	f406                	sd	ra,40(sp)
    80005002:	f022                	sd	s0,32(sp)
    80005004:	ec26                	sd	s1,24(sp)
    80005006:	e84a                	sd	s2,16(sp)
    80005008:	1800                	addi	s0,sp,48
    8000500a:	892e                	mv	s2,a1
    8000500c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000500e:	fdc40593          	addi	a1,s0,-36
    80005012:	ffffe097          	auipc	ra,0xffffe
    80005016:	b9e080e7          	jalr	-1122(ra) # 80002bb0 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000501a:	fdc42703          	lw	a4,-36(s0)
    8000501e:	47bd                	li	a5,15
    80005020:	02e7eb63          	bltu	a5,a4,80005056 <argfd+0x58>
    80005024:	ffffd097          	auipc	ra,0xffffd
    80005028:	a00080e7          	jalr	-1536(ra) # 80001a24 <myproc>
    8000502c:	fdc42703          	lw	a4,-36(s0)
    80005030:	01a70793          	addi	a5,a4,26
    80005034:	078e                	slli	a5,a5,0x3
    80005036:	953e                	add	a0,a0,a5
    80005038:	611c                	ld	a5,0(a0)
    8000503a:	c385                	beqz	a5,8000505a <argfd+0x5c>
    return -1;
  if(pfd)
    8000503c:	00090463          	beqz	s2,80005044 <argfd+0x46>
    *pfd = fd;
    80005040:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005044:	4501                	li	a0,0
  if(pf)
    80005046:	c091                	beqz	s1,8000504a <argfd+0x4c>
    *pf = f;
    80005048:	e09c                	sd	a5,0(s1)
}
    8000504a:	70a2                	ld	ra,40(sp)
    8000504c:	7402                	ld	s0,32(sp)
    8000504e:	64e2                	ld	s1,24(sp)
    80005050:	6942                	ld	s2,16(sp)
    80005052:	6145                	addi	sp,sp,48
    80005054:	8082                	ret
    return -1;
    80005056:	557d                	li	a0,-1
    80005058:	bfcd                	j	8000504a <argfd+0x4c>
    8000505a:	557d                	li	a0,-1
    8000505c:	b7fd                	j	8000504a <argfd+0x4c>

000000008000505e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000505e:	1101                	addi	sp,sp,-32
    80005060:	ec06                	sd	ra,24(sp)
    80005062:	e822                	sd	s0,16(sp)
    80005064:	e426                	sd	s1,8(sp)
    80005066:	1000                	addi	s0,sp,32
    80005068:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000506a:	ffffd097          	auipc	ra,0xffffd
    8000506e:	9ba080e7          	jalr	-1606(ra) # 80001a24 <myproc>
    80005072:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005074:	0d050793          	addi	a5,a0,208
    80005078:	4501                	li	a0,0
    8000507a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000507c:	6398                	ld	a4,0(a5)
    8000507e:	cb19                	beqz	a4,80005094 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005080:	2505                	addiw	a0,a0,1
    80005082:	07a1                	addi	a5,a5,8
    80005084:	fed51ce3          	bne	a0,a3,8000507c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005088:	557d                	li	a0,-1
}
    8000508a:	60e2                	ld	ra,24(sp)
    8000508c:	6442                	ld	s0,16(sp)
    8000508e:	64a2                	ld	s1,8(sp)
    80005090:	6105                	addi	sp,sp,32
    80005092:	8082                	ret
      p->ofile[fd] = f;
    80005094:	01a50793          	addi	a5,a0,26
    80005098:	078e                	slli	a5,a5,0x3
    8000509a:	963e                	add	a2,a2,a5
    8000509c:	e204                	sd	s1,0(a2)
      return fd;
    8000509e:	b7f5                	j	8000508a <fdalloc+0x2c>

00000000800050a0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050a0:	715d                	addi	sp,sp,-80
    800050a2:	e486                	sd	ra,72(sp)
    800050a4:	e0a2                	sd	s0,64(sp)
    800050a6:	fc26                	sd	s1,56(sp)
    800050a8:	f84a                	sd	s2,48(sp)
    800050aa:	f44e                	sd	s3,40(sp)
    800050ac:	f052                	sd	s4,32(sp)
    800050ae:	ec56                	sd	s5,24(sp)
    800050b0:	e85a                	sd	s6,16(sp)
    800050b2:	0880                	addi	s0,sp,80
    800050b4:	8b2e                	mv	s6,a1
    800050b6:	89b2                	mv	s3,a2
    800050b8:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050ba:	fb040593          	addi	a1,s0,-80
    800050be:	fffff097          	auipc	ra,0xfffff
    800050c2:	e18080e7          	jalr	-488(ra) # 80003ed6 <nameiparent>
    800050c6:	84aa                	mv	s1,a0
    800050c8:	14050b63          	beqz	a0,8000521e <create+0x17e>
    return 0;

  ilock(dp);
    800050cc:	ffffe097          	auipc	ra,0xffffe
    800050d0:	646080e7          	jalr	1606(ra) # 80003712 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050d4:	4601                	li	a2,0
    800050d6:	fb040593          	addi	a1,s0,-80
    800050da:	8526                	mv	a0,s1
    800050dc:	fffff097          	auipc	ra,0xfffff
    800050e0:	b1a080e7          	jalr	-1254(ra) # 80003bf6 <dirlookup>
    800050e4:	8aaa                	mv	s5,a0
    800050e6:	c921                	beqz	a0,80005136 <create+0x96>
    iunlockput(dp);
    800050e8:	8526                	mv	a0,s1
    800050ea:	fffff097          	auipc	ra,0xfffff
    800050ee:	88a080e7          	jalr	-1910(ra) # 80003974 <iunlockput>
    ilock(ip);
    800050f2:	8556                	mv	a0,s5
    800050f4:	ffffe097          	auipc	ra,0xffffe
    800050f8:	61e080e7          	jalr	1566(ra) # 80003712 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800050fc:	4789                	li	a5,2
    800050fe:	02fb1563          	bne	s6,a5,80005128 <create+0x88>
    80005102:	044ad783          	lhu	a5,68(s5)
    80005106:	37f9                	addiw	a5,a5,-2
    80005108:	17c2                	slli	a5,a5,0x30
    8000510a:	93c1                	srli	a5,a5,0x30
    8000510c:	4705                	li	a4,1
    8000510e:	00f76d63          	bltu	a4,a5,80005128 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005112:	8556                	mv	a0,s5
    80005114:	60a6                	ld	ra,72(sp)
    80005116:	6406                	ld	s0,64(sp)
    80005118:	74e2                	ld	s1,56(sp)
    8000511a:	7942                	ld	s2,48(sp)
    8000511c:	79a2                	ld	s3,40(sp)
    8000511e:	7a02                	ld	s4,32(sp)
    80005120:	6ae2                	ld	s5,24(sp)
    80005122:	6b42                	ld	s6,16(sp)
    80005124:	6161                	addi	sp,sp,80
    80005126:	8082                	ret
    iunlockput(ip);
    80005128:	8556                	mv	a0,s5
    8000512a:	fffff097          	auipc	ra,0xfffff
    8000512e:	84a080e7          	jalr	-1974(ra) # 80003974 <iunlockput>
    return 0;
    80005132:	4a81                	li	s5,0
    80005134:	bff9                	j	80005112 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005136:	85da                	mv	a1,s6
    80005138:	4088                	lw	a0,0(s1)
    8000513a:	ffffe097          	auipc	ra,0xffffe
    8000513e:	440080e7          	jalr	1088(ra) # 8000357a <ialloc>
    80005142:	8a2a                	mv	s4,a0
    80005144:	c529                	beqz	a0,8000518e <create+0xee>
  ilock(ip);
    80005146:	ffffe097          	auipc	ra,0xffffe
    8000514a:	5cc080e7          	jalr	1484(ra) # 80003712 <ilock>
  ip->major = major;
    8000514e:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005152:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005156:	4905                	li	s2,1
    80005158:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000515c:	8552                	mv	a0,s4
    8000515e:	ffffe097          	auipc	ra,0xffffe
    80005162:	4e8080e7          	jalr	1256(ra) # 80003646 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005166:	032b0b63          	beq	s6,s2,8000519c <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000516a:	004a2603          	lw	a2,4(s4)
    8000516e:	fb040593          	addi	a1,s0,-80
    80005172:	8526                	mv	a0,s1
    80005174:	fffff097          	auipc	ra,0xfffff
    80005178:	c92080e7          	jalr	-878(ra) # 80003e06 <dirlink>
    8000517c:	06054f63          	bltz	a0,800051fa <create+0x15a>
  iunlockput(dp);
    80005180:	8526                	mv	a0,s1
    80005182:	ffffe097          	auipc	ra,0xffffe
    80005186:	7f2080e7          	jalr	2034(ra) # 80003974 <iunlockput>
  return ip;
    8000518a:	8ad2                	mv	s5,s4
    8000518c:	b759                	j	80005112 <create+0x72>
    iunlockput(dp);
    8000518e:	8526                	mv	a0,s1
    80005190:	ffffe097          	auipc	ra,0xffffe
    80005194:	7e4080e7          	jalr	2020(ra) # 80003974 <iunlockput>
    return 0;
    80005198:	8ad2                	mv	s5,s4
    8000519a:	bfa5                	j	80005112 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000519c:	004a2603          	lw	a2,4(s4)
    800051a0:	00003597          	auipc	a1,0x3
    800051a4:	5d058593          	addi	a1,a1,1488 # 80008770 <syscalls+0x318>
    800051a8:	8552                	mv	a0,s4
    800051aa:	fffff097          	auipc	ra,0xfffff
    800051ae:	c5c080e7          	jalr	-932(ra) # 80003e06 <dirlink>
    800051b2:	04054463          	bltz	a0,800051fa <create+0x15a>
    800051b6:	40d0                	lw	a2,4(s1)
    800051b8:	00003597          	auipc	a1,0x3
    800051bc:	5c058593          	addi	a1,a1,1472 # 80008778 <syscalls+0x320>
    800051c0:	8552                	mv	a0,s4
    800051c2:	fffff097          	auipc	ra,0xfffff
    800051c6:	c44080e7          	jalr	-956(ra) # 80003e06 <dirlink>
    800051ca:	02054863          	bltz	a0,800051fa <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    800051ce:	004a2603          	lw	a2,4(s4)
    800051d2:	fb040593          	addi	a1,s0,-80
    800051d6:	8526                	mv	a0,s1
    800051d8:	fffff097          	auipc	ra,0xfffff
    800051dc:	c2e080e7          	jalr	-978(ra) # 80003e06 <dirlink>
    800051e0:	00054d63          	bltz	a0,800051fa <create+0x15a>
    dp->nlink++;  // for ".."
    800051e4:	04a4d783          	lhu	a5,74(s1)
    800051e8:	2785                	addiw	a5,a5,1
    800051ea:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800051ee:	8526                	mv	a0,s1
    800051f0:	ffffe097          	auipc	ra,0xffffe
    800051f4:	456080e7          	jalr	1110(ra) # 80003646 <iupdate>
    800051f8:	b761                	j	80005180 <create+0xe0>
  ip->nlink = 0;
    800051fa:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800051fe:	8552                	mv	a0,s4
    80005200:	ffffe097          	auipc	ra,0xffffe
    80005204:	446080e7          	jalr	1094(ra) # 80003646 <iupdate>
  iunlockput(ip);
    80005208:	8552                	mv	a0,s4
    8000520a:	ffffe097          	auipc	ra,0xffffe
    8000520e:	76a080e7          	jalr	1898(ra) # 80003974 <iunlockput>
  iunlockput(dp);
    80005212:	8526                	mv	a0,s1
    80005214:	ffffe097          	auipc	ra,0xffffe
    80005218:	760080e7          	jalr	1888(ra) # 80003974 <iunlockput>
  return 0;
    8000521c:	bddd                	j	80005112 <create+0x72>
    return 0;
    8000521e:	8aaa                	mv	s5,a0
    80005220:	bdcd                	j	80005112 <create+0x72>

0000000080005222 <sys_dup>:
{
    80005222:	7179                	addi	sp,sp,-48
    80005224:	f406                	sd	ra,40(sp)
    80005226:	f022                	sd	s0,32(sp)
    80005228:	ec26                	sd	s1,24(sp)
    8000522a:	e84a                	sd	s2,16(sp)
    8000522c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000522e:	fd840613          	addi	a2,s0,-40
    80005232:	4581                	li	a1,0
    80005234:	4501                	li	a0,0
    80005236:	00000097          	auipc	ra,0x0
    8000523a:	dc8080e7          	jalr	-568(ra) # 80004ffe <argfd>
    return -1;
    8000523e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005240:	02054363          	bltz	a0,80005266 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005244:	fd843903          	ld	s2,-40(s0)
    80005248:	854a                	mv	a0,s2
    8000524a:	00000097          	auipc	ra,0x0
    8000524e:	e14080e7          	jalr	-492(ra) # 8000505e <fdalloc>
    80005252:	84aa                	mv	s1,a0
    return -1;
    80005254:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005256:	00054863          	bltz	a0,80005266 <sys_dup+0x44>
  filedup(f);
    8000525a:	854a                	mv	a0,s2
    8000525c:	fffff097          	auipc	ra,0xfffff
    80005260:	2ce080e7          	jalr	718(ra) # 8000452a <filedup>
  return fd;
    80005264:	87a6                	mv	a5,s1
}
    80005266:	853e                	mv	a0,a5
    80005268:	70a2                	ld	ra,40(sp)
    8000526a:	7402                	ld	s0,32(sp)
    8000526c:	64e2                	ld	s1,24(sp)
    8000526e:	6942                	ld	s2,16(sp)
    80005270:	6145                	addi	sp,sp,48
    80005272:	8082                	ret

0000000080005274 <sys_read>:
{
    80005274:	7179                	addi	sp,sp,-48
    80005276:	f406                	sd	ra,40(sp)
    80005278:	f022                	sd	s0,32(sp)
    8000527a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000527c:	fd840593          	addi	a1,s0,-40
    80005280:	4505                	li	a0,1
    80005282:	ffffe097          	auipc	ra,0xffffe
    80005286:	94e080e7          	jalr	-1714(ra) # 80002bd0 <argaddr>
  argint(2, &n);
    8000528a:	fe440593          	addi	a1,s0,-28
    8000528e:	4509                	li	a0,2
    80005290:	ffffe097          	auipc	ra,0xffffe
    80005294:	920080e7          	jalr	-1760(ra) # 80002bb0 <argint>
  if(argfd(0, 0, &f) < 0)
    80005298:	fe840613          	addi	a2,s0,-24
    8000529c:	4581                	li	a1,0
    8000529e:	4501                	li	a0,0
    800052a0:	00000097          	auipc	ra,0x0
    800052a4:	d5e080e7          	jalr	-674(ra) # 80004ffe <argfd>
    800052a8:	87aa                	mv	a5,a0
    return -1;
    800052aa:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800052ac:	0007cc63          	bltz	a5,800052c4 <sys_read+0x50>
  return fileread(f, p, n);
    800052b0:	fe442603          	lw	a2,-28(s0)
    800052b4:	fd843583          	ld	a1,-40(s0)
    800052b8:	fe843503          	ld	a0,-24(s0)
    800052bc:	fffff097          	auipc	ra,0xfffff
    800052c0:	3fa080e7          	jalr	1018(ra) # 800046b6 <fileread>
}
    800052c4:	70a2                	ld	ra,40(sp)
    800052c6:	7402                	ld	s0,32(sp)
    800052c8:	6145                	addi	sp,sp,48
    800052ca:	8082                	ret

00000000800052cc <sys_write>:
{
    800052cc:	7179                	addi	sp,sp,-48
    800052ce:	f406                	sd	ra,40(sp)
    800052d0:	f022                	sd	s0,32(sp)
    800052d2:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800052d4:	fd840593          	addi	a1,s0,-40
    800052d8:	4505                	li	a0,1
    800052da:	ffffe097          	auipc	ra,0xffffe
    800052de:	8f6080e7          	jalr	-1802(ra) # 80002bd0 <argaddr>
  argint(2, &n);
    800052e2:	fe440593          	addi	a1,s0,-28
    800052e6:	4509                	li	a0,2
    800052e8:	ffffe097          	auipc	ra,0xffffe
    800052ec:	8c8080e7          	jalr	-1848(ra) # 80002bb0 <argint>
  if(argfd(0, 0, &f) < 0)
    800052f0:	fe840613          	addi	a2,s0,-24
    800052f4:	4581                	li	a1,0
    800052f6:	4501                	li	a0,0
    800052f8:	00000097          	auipc	ra,0x0
    800052fc:	d06080e7          	jalr	-762(ra) # 80004ffe <argfd>
    80005300:	87aa                	mv	a5,a0
    return -1;
    80005302:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005304:	0007cc63          	bltz	a5,8000531c <sys_write+0x50>
  return filewrite(f, p, n);
    80005308:	fe442603          	lw	a2,-28(s0)
    8000530c:	fd843583          	ld	a1,-40(s0)
    80005310:	fe843503          	ld	a0,-24(s0)
    80005314:	fffff097          	auipc	ra,0xfffff
    80005318:	464080e7          	jalr	1124(ra) # 80004778 <filewrite>
}
    8000531c:	70a2                	ld	ra,40(sp)
    8000531e:	7402                	ld	s0,32(sp)
    80005320:	6145                	addi	sp,sp,48
    80005322:	8082                	ret

0000000080005324 <sys_close>:
{
    80005324:	1101                	addi	sp,sp,-32
    80005326:	ec06                	sd	ra,24(sp)
    80005328:	e822                	sd	s0,16(sp)
    8000532a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000532c:	fe040613          	addi	a2,s0,-32
    80005330:	fec40593          	addi	a1,s0,-20
    80005334:	4501                	li	a0,0
    80005336:	00000097          	auipc	ra,0x0
    8000533a:	cc8080e7          	jalr	-824(ra) # 80004ffe <argfd>
    return -1;
    8000533e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005340:	02054463          	bltz	a0,80005368 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005344:	ffffc097          	auipc	ra,0xffffc
    80005348:	6e0080e7          	jalr	1760(ra) # 80001a24 <myproc>
    8000534c:	fec42783          	lw	a5,-20(s0)
    80005350:	07e9                	addi	a5,a5,26
    80005352:	078e                	slli	a5,a5,0x3
    80005354:	953e                	add	a0,a0,a5
    80005356:	00053023          	sd	zero,0(a0)
  fileclose(f);
    8000535a:	fe043503          	ld	a0,-32(s0)
    8000535e:	fffff097          	auipc	ra,0xfffff
    80005362:	21e080e7          	jalr	542(ra) # 8000457c <fileclose>
  return 0;
    80005366:	4781                	li	a5,0
}
    80005368:	853e                	mv	a0,a5
    8000536a:	60e2                	ld	ra,24(sp)
    8000536c:	6442                	ld	s0,16(sp)
    8000536e:	6105                	addi	sp,sp,32
    80005370:	8082                	ret

0000000080005372 <sys_fstat>:
{
    80005372:	1101                	addi	sp,sp,-32
    80005374:	ec06                	sd	ra,24(sp)
    80005376:	e822                	sd	s0,16(sp)
    80005378:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000537a:	fe040593          	addi	a1,s0,-32
    8000537e:	4505                	li	a0,1
    80005380:	ffffe097          	auipc	ra,0xffffe
    80005384:	850080e7          	jalr	-1968(ra) # 80002bd0 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005388:	fe840613          	addi	a2,s0,-24
    8000538c:	4581                	li	a1,0
    8000538e:	4501                	li	a0,0
    80005390:	00000097          	auipc	ra,0x0
    80005394:	c6e080e7          	jalr	-914(ra) # 80004ffe <argfd>
    80005398:	87aa                	mv	a5,a0
    return -1;
    8000539a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000539c:	0007ca63          	bltz	a5,800053b0 <sys_fstat+0x3e>
  return filestat(f, st);
    800053a0:	fe043583          	ld	a1,-32(s0)
    800053a4:	fe843503          	ld	a0,-24(s0)
    800053a8:	fffff097          	auipc	ra,0xfffff
    800053ac:	29c080e7          	jalr	668(ra) # 80004644 <filestat>
}
    800053b0:	60e2                	ld	ra,24(sp)
    800053b2:	6442                	ld	s0,16(sp)
    800053b4:	6105                	addi	sp,sp,32
    800053b6:	8082                	ret

00000000800053b8 <sys_link>:
{
    800053b8:	7169                	addi	sp,sp,-304
    800053ba:	f606                	sd	ra,296(sp)
    800053bc:	f222                	sd	s0,288(sp)
    800053be:	ee26                	sd	s1,280(sp)
    800053c0:	ea4a                	sd	s2,272(sp)
    800053c2:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053c4:	08000613          	li	a2,128
    800053c8:	ed040593          	addi	a1,s0,-304
    800053cc:	4501                	li	a0,0
    800053ce:	ffffe097          	auipc	ra,0xffffe
    800053d2:	822080e7          	jalr	-2014(ra) # 80002bf0 <argstr>
    return -1;
    800053d6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053d8:	10054e63          	bltz	a0,800054f4 <sys_link+0x13c>
    800053dc:	08000613          	li	a2,128
    800053e0:	f5040593          	addi	a1,s0,-176
    800053e4:	4505                	li	a0,1
    800053e6:	ffffe097          	auipc	ra,0xffffe
    800053ea:	80a080e7          	jalr	-2038(ra) # 80002bf0 <argstr>
    return -1;
    800053ee:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053f0:	10054263          	bltz	a0,800054f4 <sys_link+0x13c>
  begin_op();
    800053f4:	fffff097          	auipc	ra,0xfffff
    800053f8:	cc4080e7          	jalr	-828(ra) # 800040b8 <begin_op>
  if((ip = namei(old)) == 0){
    800053fc:	ed040513          	addi	a0,s0,-304
    80005400:	fffff097          	auipc	ra,0xfffff
    80005404:	ab8080e7          	jalr	-1352(ra) # 80003eb8 <namei>
    80005408:	84aa                	mv	s1,a0
    8000540a:	c551                	beqz	a0,80005496 <sys_link+0xde>
  ilock(ip);
    8000540c:	ffffe097          	auipc	ra,0xffffe
    80005410:	306080e7          	jalr	774(ra) # 80003712 <ilock>
  if(ip->type == T_DIR){
    80005414:	04449703          	lh	a4,68(s1)
    80005418:	4785                	li	a5,1
    8000541a:	08f70463          	beq	a4,a5,800054a2 <sys_link+0xea>
  ip->nlink++;
    8000541e:	04a4d783          	lhu	a5,74(s1)
    80005422:	2785                	addiw	a5,a5,1
    80005424:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005428:	8526                	mv	a0,s1
    8000542a:	ffffe097          	auipc	ra,0xffffe
    8000542e:	21c080e7          	jalr	540(ra) # 80003646 <iupdate>
  iunlock(ip);
    80005432:	8526                	mv	a0,s1
    80005434:	ffffe097          	auipc	ra,0xffffe
    80005438:	3a0080e7          	jalr	928(ra) # 800037d4 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000543c:	fd040593          	addi	a1,s0,-48
    80005440:	f5040513          	addi	a0,s0,-176
    80005444:	fffff097          	auipc	ra,0xfffff
    80005448:	a92080e7          	jalr	-1390(ra) # 80003ed6 <nameiparent>
    8000544c:	892a                	mv	s2,a0
    8000544e:	c935                	beqz	a0,800054c2 <sys_link+0x10a>
  ilock(dp);
    80005450:	ffffe097          	auipc	ra,0xffffe
    80005454:	2c2080e7          	jalr	706(ra) # 80003712 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005458:	00092703          	lw	a4,0(s2)
    8000545c:	409c                	lw	a5,0(s1)
    8000545e:	04f71d63          	bne	a4,a5,800054b8 <sys_link+0x100>
    80005462:	40d0                	lw	a2,4(s1)
    80005464:	fd040593          	addi	a1,s0,-48
    80005468:	854a                	mv	a0,s2
    8000546a:	fffff097          	auipc	ra,0xfffff
    8000546e:	99c080e7          	jalr	-1636(ra) # 80003e06 <dirlink>
    80005472:	04054363          	bltz	a0,800054b8 <sys_link+0x100>
  iunlockput(dp);
    80005476:	854a                	mv	a0,s2
    80005478:	ffffe097          	auipc	ra,0xffffe
    8000547c:	4fc080e7          	jalr	1276(ra) # 80003974 <iunlockput>
  iput(ip);
    80005480:	8526                	mv	a0,s1
    80005482:	ffffe097          	auipc	ra,0xffffe
    80005486:	44a080e7          	jalr	1098(ra) # 800038cc <iput>
  end_op();
    8000548a:	fffff097          	auipc	ra,0xfffff
    8000548e:	ca8080e7          	jalr	-856(ra) # 80004132 <end_op>
  return 0;
    80005492:	4781                	li	a5,0
    80005494:	a085                	j	800054f4 <sys_link+0x13c>
    end_op();
    80005496:	fffff097          	auipc	ra,0xfffff
    8000549a:	c9c080e7          	jalr	-868(ra) # 80004132 <end_op>
    return -1;
    8000549e:	57fd                	li	a5,-1
    800054a0:	a891                	j	800054f4 <sys_link+0x13c>
    iunlockput(ip);
    800054a2:	8526                	mv	a0,s1
    800054a4:	ffffe097          	auipc	ra,0xffffe
    800054a8:	4d0080e7          	jalr	1232(ra) # 80003974 <iunlockput>
    end_op();
    800054ac:	fffff097          	auipc	ra,0xfffff
    800054b0:	c86080e7          	jalr	-890(ra) # 80004132 <end_op>
    return -1;
    800054b4:	57fd                	li	a5,-1
    800054b6:	a83d                	j	800054f4 <sys_link+0x13c>
    iunlockput(dp);
    800054b8:	854a                	mv	a0,s2
    800054ba:	ffffe097          	auipc	ra,0xffffe
    800054be:	4ba080e7          	jalr	1210(ra) # 80003974 <iunlockput>
  ilock(ip);
    800054c2:	8526                	mv	a0,s1
    800054c4:	ffffe097          	auipc	ra,0xffffe
    800054c8:	24e080e7          	jalr	590(ra) # 80003712 <ilock>
  ip->nlink--;
    800054cc:	04a4d783          	lhu	a5,74(s1)
    800054d0:	37fd                	addiw	a5,a5,-1
    800054d2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054d6:	8526                	mv	a0,s1
    800054d8:	ffffe097          	auipc	ra,0xffffe
    800054dc:	16e080e7          	jalr	366(ra) # 80003646 <iupdate>
  iunlockput(ip);
    800054e0:	8526                	mv	a0,s1
    800054e2:	ffffe097          	auipc	ra,0xffffe
    800054e6:	492080e7          	jalr	1170(ra) # 80003974 <iunlockput>
  end_op();
    800054ea:	fffff097          	auipc	ra,0xfffff
    800054ee:	c48080e7          	jalr	-952(ra) # 80004132 <end_op>
  return -1;
    800054f2:	57fd                	li	a5,-1
}
    800054f4:	853e                	mv	a0,a5
    800054f6:	70b2                	ld	ra,296(sp)
    800054f8:	7412                	ld	s0,288(sp)
    800054fa:	64f2                	ld	s1,280(sp)
    800054fc:	6952                	ld	s2,272(sp)
    800054fe:	6155                	addi	sp,sp,304
    80005500:	8082                	ret

0000000080005502 <sys_unlink>:
{
    80005502:	7151                	addi	sp,sp,-240
    80005504:	f586                	sd	ra,232(sp)
    80005506:	f1a2                	sd	s0,224(sp)
    80005508:	eda6                	sd	s1,216(sp)
    8000550a:	e9ca                	sd	s2,208(sp)
    8000550c:	e5ce                	sd	s3,200(sp)
    8000550e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005510:	08000613          	li	a2,128
    80005514:	f3040593          	addi	a1,s0,-208
    80005518:	4501                	li	a0,0
    8000551a:	ffffd097          	auipc	ra,0xffffd
    8000551e:	6d6080e7          	jalr	1750(ra) # 80002bf0 <argstr>
    80005522:	18054163          	bltz	a0,800056a4 <sys_unlink+0x1a2>
  begin_op();
    80005526:	fffff097          	auipc	ra,0xfffff
    8000552a:	b92080e7          	jalr	-1134(ra) # 800040b8 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000552e:	fb040593          	addi	a1,s0,-80
    80005532:	f3040513          	addi	a0,s0,-208
    80005536:	fffff097          	auipc	ra,0xfffff
    8000553a:	9a0080e7          	jalr	-1632(ra) # 80003ed6 <nameiparent>
    8000553e:	84aa                	mv	s1,a0
    80005540:	c979                	beqz	a0,80005616 <sys_unlink+0x114>
  ilock(dp);
    80005542:	ffffe097          	auipc	ra,0xffffe
    80005546:	1d0080e7          	jalr	464(ra) # 80003712 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000554a:	00003597          	auipc	a1,0x3
    8000554e:	22658593          	addi	a1,a1,550 # 80008770 <syscalls+0x318>
    80005552:	fb040513          	addi	a0,s0,-80
    80005556:	ffffe097          	auipc	ra,0xffffe
    8000555a:	686080e7          	jalr	1670(ra) # 80003bdc <namecmp>
    8000555e:	14050a63          	beqz	a0,800056b2 <sys_unlink+0x1b0>
    80005562:	00003597          	auipc	a1,0x3
    80005566:	21658593          	addi	a1,a1,534 # 80008778 <syscalls+0x320>
    8000556a:	fb040513          	addi	a0,s0,-80
    8000556e:	ffffe097          	auipc	ra,0xffffe
    80005572:	66e080e7          	jalr	1646(ra) # 80003bdc <namecmp>
    80005576:	12050e63          	beqz	a0,800056b2 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000557a:	f2c40613          	addi	a2,s0,-212
    8000557e:	fb040593          	addi	a1,s0,-80
    80005582:	8526                	mv	a0,s1
    80005584:	ffffe097          	auipc	ra,0xffffe
    80005588:	672080e7          	jalr	1650(ra) # 80003bf6 <dirlookup>
    8000558c:	892a                	mv	s2,a0
    8000558e:	12050263          	beqz	a0,800056b2 <sys_unlink+0x1b0>
  ilock(ip);
    80005592:	ffffe097          	auipc	ra,0xffffe
    80005596:	180080e7          	jalr	384(ra) # 80003712 <ilock>
  if(ip->nlink < 1)
    8000559a:	04a91783          	lh	a5,74(s2)
    8000559e:	08f05263          	blez	a5,80005622 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055a2:	04491703          	lh	a4,68(s2)
    800055a6:	4785                	li	a5,1
    800055a8:	08f70563          	beq	a4,a5,80005632 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055ac:	4641                	li	a2,16
    800055ae:	4581                	li	a1,0
    800055b0:	fc040513          	addi	a0,s0,-64
    800055b4:	ffffb097          	auipc	ra,0xffffb
    800055b8:	790080e7          	jalr	1936(ra) # 80000d44 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055bc:	4741                	li	a4,16
    800055be:	f2c42683          	lw	a3,-212(s0)
    800055c2:	fc040613          	addi	a2,s0,-64
    800055c6:	4581                	li	a1,0
    800055c8:	8526                	mv	a0,s1
    800055ca:	ffffe097          	auipc	ra,0xffffe
    800055ce:	4f4080e7          	jalr	1268(ra) # 80003abe <writei>
    800055d2:	47c1                	li	a5,16
    800055d4:	0af51563          	bne	a0,a5,8000567e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800055d8:	04491703          	lh	a4,68(s2)
    800055dc:	4785                	li	a5,1
    800055de:	0af70863          	beq	a4,a5,8000568e <sys_unlink+0x18c>
  iunlockput(dp);
    800055e2:	8526                	mv	a0,s1
    800055e4:	ffffe097          	auipc	ra,0xffffe
    800055e8:	390080e7          	jalr	912(ra) # 80003974 <iunlockput>
  ip->nlink--;
    800055ec:	04a95783          	lhu	a5,74(s2)
    800055f0:	37fd                	addiw	a5,a5,-1
    800055f2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800055f6:	854a                	mv	a0,s2
    800055f8:	ffffe097          	auipc	ra,0xffffe
    800055fc:	04e080e7          	jalr	78(ra) # 80003646 <iupdate>
  iunlockput(ip);
    80005600:	854a                	mv	a0,s2
    80005602:	ffffe097          	auipc	ra,0xffffe
    80005606:	372080e7          	jalr	882(ra) # 80003974 <iunlockput>
  end_op();
    8000560a:	fffff097          	auipc	ra,0xfffff
    8000560e:	b28080e7          	jalr	-1240(ra) # 80004132 <end_op>
  return 0;
    80005612:	4501                	li	a0,0
    80005614:	a84d                	j	800056c6 <sys_unlink+0x1c4>
    end_op();
    80005616:	fffff097          	auipc	ra,0xfffff
    8000561a:	b1c080e7          	jalr	-1252(ra) # 80004132 <end_op>
    return -1;
    8000561e:	557d                	li	a0,-1
    80005620:	a05d                	j	800056c6 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005622:	00003517          	auipc	a0,0x3
    80005626:	15e50513          	addi	a0,a0,350 # 80008780 <syscalls+0x328>
    8000562a:	ffffb097          	auipc	ra,0xffffb
    8000562e:	f16080e7          	jalr	-234(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005632:	04c92703          	lw	a4,76(s2)
    80005636:	02000793          	li	a5,32
    8000563a:	f6e7f9e3          	bgeu	a5,a4,800055ac <sys_unlink+0xaa>
    8000563e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005642:	4741                	li	a4,16
    80005644:	86ce                	mv	a3,s3
    80005646:	f1840613          	addi	a2,s0,-232
    8000564a:	4581                	li	a1,0
    8000564c:	854a                	mv	a0,s2
    8000564e:	ffffe097          	auipc	ra,0xffffe
    80005652:	378080e7          	jalr	888(ra) # 800039c6 <readi>
    80005656:	47c1                	li	a5,16
    80005658:	00f51b63          	bne	a0,a5,8000566e <sys_unlink+0x16c>
    if(de.inum != 0)
    8000565c:	f1845783          	lhu	a5,-232(s0)
    80005660:	e7a1                	bnez	a5,800056a8 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005662:	29c1                	addiw	s3,s3,16
    80005664:	04c92783          	lw	a5,76(s2)
    80005668:	fcf9ede3          	bltu	s3,a5,80005642 <sys_unlink+0x140>
    8000566c:	b781                	j	800055ac <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000566e:	00003517          	auipc	a0,0x3
    80005672:	12a50513          	addi	a0,a0,298 # 80008798 <syscalls+0x340>
    80005676:	ffffb097          	auipc	ra,0xffffb
    8000567a:	eca080e7          	jalr	-310(ra) # 80000540 <panic>
    panic("unlink: writei");
    8000567e:	00003517          	auipc	a0,0x3
    80005682:	13250513          	addi	a0,a0,306 # 800087b0 <syscalls+0x358>
    80005686:	ffffb097          	auipc	ra,0xffffb
    8000568a:	eba080e7          	jalr	-326(ra) # 80000540 <panic>
    dp->nlink--;
    8000568e:	04a4d783          	lhu	a5,74(s1)
    80005692:	37fd                	addiw	a5,a5,-1
    80005694:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005698:	8526                	mv	a0,s1
    8000569a:	ffffe097          	auipc	ra,0xffffe
    8000569e:	fac080e7          	jalr	-84(ra) # 80003646 <iupdate>
    800056a2:	b781                	j	800055e2 <sys_unlink+0xe0>
    return -1;
    800056a4:	557d                	li	a0,-1
    800056a6:	a005                	j	800056c6 <sys_unlink+0x1c4>
    iunlockput(ip);
    800056a8:	854a                	mv	a0,s2
    800056aa:	ffffe097          	auipc	ra,0xffffe
    800056ae:	2ca080e7          	jalr	714(ra) # 80003974 <iunlockput>
  iunlockput(dp);
    800056b2:	8526                	mv	a0,s1
    800056b4:	ffffe097          	auipc	ra,0xffffe
    800056b8:	2c0080e7          	jalr	704(ra) # 80003974 <iunlockput>
  end_op();
    800056bc:	fffff097          	auipc	ra,0xfffff
    800056c0:	a76080e7          	jalr	-1418(ra) # 80004132 <end_op>
  return -1;
    800056c4:	557d                	li	a0,-1
}
    800056c6:	70ae                	ld	ra,232(sp)
    800056c8:	740e                	ld	s0,224(sp)
    800056ca:	64ee                	ld	s1,216(sp)
    800056cc:	694e                	ld	s2,208(sp)
    800056ce:	69ae                	ld	s3,200(sp)
    800056d0:	616d                	addi	sp,sp,240
    800056d2:	8082                	ret

00000000800056d4 <sys_open>:

uint64
sys_open(void)
{
    800056d4:	7131                	addi	sp,sp,-192
    800056d6:	fd06                	sd	ra,184(sp)
    800056d8:	f922                	sd	s0,176(sp)
    800056da:	f526                	sd	s1,168(sp)
    800056dc:	f14a                	sd	s2,160(sp)
    800056de:	ed4e                	sd	s3,152(sp)
    800056e0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800056e2:	f4c40593          	addi	a1,s0,-180
    800056e6:	4505                	li	a0,1
    800056e8:	ffffd097          	auipc	ra,0xffffd
    800056ec:	4c8080e7          	jalr	1224(ra) # 80002bb0 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800056f0:	08000613          	li	a2,128
    800056f4:	f5040593          	addi	a1,s0,-176
    800056f8:	4501                	li	a0,0
    800056fa:	ffffd097          	auipc	ra,0xffffd
    800056fe:	4f6080e7          	jalr	1270(ra) # 80002bf0 <argstr>
    80005702:	87aa                	mv	a5,a0
    return -1;
    80005704:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005706:	0a07c863          	bltz	a5,800057b6 <sys_open+0xe2>

  begin_op();
    8000570a:	fffff097          	auipc	ra,0xfffff
    8000570e:	9ae080e7          	jalr	-1618(ra) # 800040b8 <begin_op>

  if(omode & O_CREATE){
    80005712:	f4c42783          	lw	a5,-180(s0)
    80005716:	2007f793          	andi	a5,a5,512
    8000571a:	cbdd                	beqz	a5,800057d0 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    8000571c:	4681                	li	a3,0
    8000571e:	4601                	li	a2,0
    80005720:	4589                	li	a1,2
    80005722:	f5040513          	addi	a0,s0,-176
    80005726:	00000097          	auipc	ra,0x0
    8000572a:	97a080e7          	jalr	-1670(ra) # 800050a0 <create>
    8000572e:	84aa                	mv	s1,a0
    if(ip == 0){
    80005730:	c951                	beqz	a0,800057c4 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005732:	04449703          	lh	a4,68(s1)
    80005736:	478d                	li	a5,3
    80005738:	00f71763          	bne	a4,a5,80005746 <sys_open+0x72>
    8000573c:	0464d703          	lhu	a4,70(s1)
    80005740:	47a5                	li	a5,9
    80005742:	0ce7ec63          	bltu	a5,a4,8000581a <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005746:	fffff097          	auipc	ra,0xfffff
    8000574a:	d7a080e7          	jalr	-646(ra) # 800044c0 <filealloc>
    8000574e:	892a                	mv	s2,a0
    80005750:	c56d                	beqz	a0,8000583a <sys_open+0x166>
    80005752:	00000097          	auipc	ra,0x0
    80005756:	90c080e7          	jalr	-1780(ra) # 8000505e <fdalloc>
    8000575a:	89aa                	mv	s3,a0
    8000575c:	0c054a63          	bltz	a0,80005830 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005760:	04449703          	lh	a4,68(s1)
    80005764:	478d                	li	a5,3
    80005766:	0ef70563          	beq	a4,a5,80005850 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000576a:	4789                	li	a5,2
    8000576c:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005770:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005774:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005778:	f4c42783          	lw	a5,-180(s0)
    8000577c:	0017c713          	xori	a4,a5,1
    80005780:	8b05                	andi	a4,a4,1
    80005782:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005786:	0037f713          	andi	a4,a5,3
    8000578a:	00e03733          	snez	a4,a4
    8000578e:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005792:	4007f793          	andi	a5,a5,1024
    80005796:	c791                	beqz	a5,800057a2 <sys_open+0xce>
    80005798:	04449703          	lh	a4,68(s1)
    8000579c:	4789                	li	a5,2
    8000579e:	0cf70063          	beq	a4,a5,8000585e <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    800057a2:	8526                	mv	a0,s1
    800057a4:	ffffe097          	auipc	ra,0xffffe
    800057a8:	030080e7          	jalr	48(ra) # 800037d4 <iunlock>
  end_op();
    800057ac:	fffff097          	auipc	ra,0xfffff
    800057b0:	986080e7          	jalr	-1658(ra) # 80004132 <end_op>

  return fd;
    800057b4:	854e                	mv	a0,s3
}
    800057b6:	70ea                	ld	ra,184(sp)
    800057b8:	744a                	ld	s0,176(sp)
    800057ba:	74aa                	ld	s1,168(sp)
    800057bc:	790a                	ld	s2,160(sp)
    800057be:	69ea                	ld	s3,152(sp)
    800057c0:	6129                	addi	sp,sp,192
    800057c2:	8082                	ret
      end_op();
    800057c4:	fffff097          	auipc	ra,0xfffff
    800057c8:	96e080e7          	jalr	-1682(ra) # 80004132 <end_op>
      return -1;
    800057cc:	557d                	li	a0,-1
    800057ce:	b7e5                	j	800057b6 <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    800057d0:	f5040513          	addi	a0,s0,-176
    800057d4:	ffffe097          	auipc	ra,0xffffe
    800057d8:	6e4080e7          	jalr	1764(ra) # 80003eb8 <namei>
    800057dc:	84aa                	mv	s1,a0
    800057de:	c905                	beqz	a0,8000580e <sys_open+0x13a>
    ilock(ip);
    800057e0:	ffffe097          	auipc	ra,0xffffe
    800057e4:	f32080e7          	jalr	-206(ra) # 80003712 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800057e8:	04449703          	lh	a4,68(s1)
    800057ec:	4785                	li	a5,1
    800057ee:	f4f712e3          	bne	a4,a5,80005732 <sys_open+0x5e>
    800057f2:	f4c42783          	lw	a5,-180(s0)
    800057f6:	dba1                	beqz	a5,80005746 <sys_open+0x72>
      iunlockput(ip);
    800057f8:	8526                	mv	a0,s1
    800057fa:	ffffe097          	auipc	ra,0xffffe
    800057fe:	17a080e7          	jalr	378(ra) # 80003974 <iunlockput>
      end_op();
    80005802:	fffff097          	auipc	ra,0xfffff
    80005806:	930080e7          	jalr	-1744(ra) # 80004132 <end_op>
      return -1;
    8000580a:	557d                	li	a0,-1
    8000580c:	b76d                	j	800057b6 <sys_open+0xe2>
      end_op();
    8000580e:	fffff097          	auipc	ra,0xfffff
    80005812:	924080e7          	jalr	-1756(ra) # 80004132 <end_op>
      return -1;
    80005816:	557d                	li	a0,-1
    80005818:	bf79                	j	800057b6 <sys_open+0xe2>
    iunlockput(ip);
    8000581a:	8526                	mv	a0,s1
    8000581c:	ffffe097          	auipc	ra,0xffffe
    80005820:	158080e7          	jalr	344(ra) # 80003974 <iunlockput>
    end_op();
    80005824:	fffff097          	auipc	ra,0xfffff
    80005828:	90e080e7          	jalr	-1778(ra) # 80004132 <end_op>
    return -1;
    8000582c:	557d                	li	a0,-1
    8000582e:	b761                	j	800057b6 <sys_open+0xe2>
      fileclose(f);
    80005830:	854a                	mv	a0,s2
    80005832:	fffff097          	auipc	ra,0xfffff
    80005836:	d4a080e7          	jalr	-694(ra) # 8000457c <fileclose>
    iunlockput(ip);
    8000583a:	8526                	mv	a0,s1
    8000583c:	ffffe097          	auipc	ra,0xffffe
    80005840:	138080e7          	jalr	312(ra) # 80003974 <iunlockput>
    end_op();
    80005844:	fffff097          	auipc	ra,0xfffff
    80005848:	8ee080e7          	jalr	-1810(ra) # 80004132 <end_op>
    return -1;
    8000584c:	557d                	li	a0,-1
    8000584e:	b7a5                	j	800057b6 <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005850:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005854:	04649783          	lh	a5,70(s1)
    80005858:	02f91223          	sh	a5,36(s2)
    8000585c:	bf21                	j	80005774 <sys_open+0xa0>
    itrunc(ip);
    8000585e:	8526                	mv	a0,s1
    80005860:	ffffe097          	auipc	ra,0xffffe
    80005864:	fc0080e7          	jalr	-64(ra) # 80003820 <itrunc>
    80005868:	bf2d                	j	800057a2 <sys_open+0xce>

000000008000586a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000586a:	7175                	addi	sp,sp,-144
    8000586c:	e506                	sd	ra,136(sp)
    8000586e:	e122                	sd	s0,128(sp)
    80005870:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005872:	fffff097          	auipc	ra,0xfffff
    80005876:	846080e7          	jalr	-1978(ra) # 800040b8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000587a:	08000613          	li	a2,128
    8000587e:	f7040593          	addi	a1,s0,-144
    80005882:	4501                	li	a0,0
    80005884:	ffffd097          	auipc	ra,0xffffd
    80005888:	36c080e7          	jalr	876(ra) # 80002bf0 <argstr>
    8000588c:	02054963          	bltz	a0,800058be <sys_mkdir+0x54>
    80005890:	4681                	li	a3,0
    80005892:	4601                	li	a2,0
    80005894:	4585                	li	a1,1
    80005896:	f7040513          	addi	a0,s0,-144
    8000589a:	00000097          	auipc	ra,0x0
    8000589e:	806080e7          	jalr	-2042(ra) # 800050a0 <create>
    800058a2:	cd11                	beqz	a0,800058be <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058a4:	ffffe097          	auipc	ra,0xffffe
    800058a8:	0d0080e7          	jalr	208(ra) # 80003974 <iunlockput>
  end_op();
    800058ac:	fffff097          	auipc	ra,0xfffff
    800058b0:	886080e7          	jalr	-1914(ra) # 80004132 <end_op>
  return 0;
    800058b4:	4501                	li	a0,0
}
    800058b6:	60aa                	ld	ra,136(sp)
    800058b8:	640a                	ld	s0,128(sp)
    800058ba:	6149                	addi	sp,sp,144
    800058bc:	8082                	ret
    end_op();
    800058be:	fffff097          	auipc	ra,0xfffff
    800058c2:	874080e7          	jalr	-1932(ra) # 80004132 <end_op>
    return -1;
    800058c6:	557d                	li	a0,-1
    800058c8:	b7fd                	j	800058b6 <sys_mkdir+0x4c>

00000000800058ca <sys_mknod>:

uint64
sys_mknod(void)
{
    800058ca:	7135                	addi	sp,sp,-160
    800058cc:	ed06                	sd	ra,152(sp)
    800058ce:	e922                	sd	s0,144(sp)
    800058d0:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058d2:	ffffe097          	auipc	ra,0xffffe
    800058d6:	7e6080e7          	jalr	2022(ra) # 800040b8 <begin_op>
  argint(1, &major);
    800058da:	f6c40593          	addi	a1,s0,-148
    800058de:	4505                	li	a0,1
    800058e0:	ffffd097          	auipc	ra,0xffffd
    800058e4:	2d0080e7          	jalr	720(ra) # 80002bb0 <argint>
  argint(2, &minor);
    800058e8:	f6840593          	addi	a1,s0,-152
    800058ec:	4509                	li	a0,2
    800058ee:	ffffd097          	auipc	ra,0xffffd
    800058f2:	2c2080e7          	jalr	706(ra) # 80002bb0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058f6:	08000613          	li	a2,128
    800058fa:	f7040593          	addi	a1,s0,-144
    800058fe:	4501                	li	a0,0
    80005900:	ffffd097          	auipc	ra,0xffffd
    80005904:	2f0080e7          	jalr	752(ra) # 80002bf0 <argstr>
    80005908:	02054b63          	bltz	a0,8000593e <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000590c:	f6841683          	lh	a3,-152(s0)
    80005910:	f6c41603          	lh	a2,-148(s0)
    80005914:	458d                	li	a1,3
    80005916:	f7040513          	addi	a0,s0,-144
    8000591a:	fffff097          	auipc	ra,0xfffff
    8000591e:	786080e7          	jalr	1926(ra) # 800050a0 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005922:	cd11                	beqz	a0,8000593e <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005924:	ffffe097          	auipc	ra,0xffffe
    80005928:	050080e7          	jalr	80(ra) # 80003974 <iunlockput>
  end_op();
    8000592c:	fffff097          	auipc	ra,0xfffff
    80005930:	806080e7          	jalr	-2042(ra) # 80004132 <end_op>
  return 0;
    80005934:	4501                	li	a0,0
}
    80005936:	60ea                	ld	ra,152(sp)
    80005938:	644a                	ld	s0,144(sp)
    8000593a:	610d                	addi	sp,sp,160
    8000593c:	8082                	ret
    end_op();
    8000593e:	ffffe097          	auipc	ra,0xffffe
    80005942:	7f4080e7          	jalr	2036(ra) # 80004132 <end_op>
    return -1;
    80005946:	557d                	li	a0,-1
    80005948:	b7fd                	j	80005936 <sys_mknod+0x6c>

000000008000594a <sys_chdir>:

uint64
sys_chdir(void)
{
    8000594a:	7135                	addi	sp,sp,-160
    8000594c:	ed06                	sd	ra,152(sp)
    8000594e:	e922                	sd	s0,144(sp)
    80005950:	e526                	sd	s1,136(sp)
    80005952:	e14a                	sd	s2,128(sp)
    80005954:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005956:	ffffc097          	auipc	ra,0xffffc
    8000595a:	0ce080e7          	jalr	206(ra) # 80001a24 <myproc>
    8000595e:	892a                	mv	s2,a0
  
  begin_op();
    80005960:	ffffe097          	auipc	ra,0xffffe
    80005964:	758080e7          	jalr	1880(ra) # 800040b8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005968:	08000613          	li	a2,128
    8000596c:	f6040593          	addi	a1,s0,-160
    80005970:	4501                	li	a0,0
    80005972:	ffffd097          	auipc	ra,0xffffd
    80005976:	27e080e7          	jalr	638(ra) # 80002bf0 <argstr>
    8000597a:	04054b63          	bltz	a0,800059d0 <sys_chdir+0x86>
    8000597e:	f6040513          	addi	a0,s0,-160
    80005982:	ffffe097          	auipc	ra,0xffffe
    80005986:	536080e7          	jalr	1334(ra) # 80003eb8 <namei>
    8000598a:	84aa                	mv	s1,a0
    8000598c:	c131                	beqz	a0,800059d0 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000598e:	ffffe097          	auipc	ra,0xffffe
    80005992:	d84080e7          	jalr	-636(ra) # 80003712 <ilock>
  if(ip->type != T_DIR){
    80005996:	04449703          	lh	a4,68(s1)
    8000599a:	4785                	li	a5,1
    8000599c:	04f71063          	bne	a4,a5,800059dc <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059a0:	8526                	mv	a0,s1
    800059a2:	ffffe097          	auipc	ra,0xffffe
    800059a6:	e32080e7          	jalr	-462(ra) # 800037d4 <iunlock>
  iput(p->cwd);
    800059aa:	15093503          	ld	a0,336(s2)
    800059ae:	ffffe097          	auipc	ra,0xffffe
    800059b2:	f1e080e7          	jalr	-226(ra) # 800038cc <iput>
  end_op();
    800059b6:	ffffe097          	auipc	ra,0xffffe
    800059ba:	77c080e7          	jalr	1916(ra) # 80004132 <end_op>
  p->cwd = ip;
    800059be:	14993823          	sd	s1,336(s2)
  return 0;
    800059c2:	4501                	li	a0,0
}
    800059c4:	60ea                	ld	ra,152(sp)
    800059c6:	644a                	ld	s0,144(sp)
    800059c8:	64aa                	ld	s1,136(sp)
    800059ca:	690a                	ld	s2,128(sp)
    800059cc:	610d                	addi	sp,sp,160
    800059ce:	8082                	ret
    end_op();
    800059d0:	ffffe097          	auipc	ra,0xffffe
    800059d4:	762080e7          	jalr	1890(ra) # 80004132 <end_op>
    return -1;
    800059d8:	557d                	li	a0,-1
    800059da:	b7ed                	j	800059c4 <sys_chdir+0x7a>
    iunlockput(ip);
    800059dc:	8526                	mv	a0,s1
    800059de:	ffffe097          	auipc	ra,0xffffe
    800059e2:	f96080e7          	jalr	-106(ra) # 80003974 <iunlockput>
    end_op();
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	74c080e7          	jalr	1868(ra) # 80004132 <end_op>
    return -1;
    800059ee:	557d                	li	a0,-1
    800059f0:	bfd1                	j	800059c4 <sys_chdir+0x7a>

00000000800059f2 <sys_exec>:

uint64
sys_exec(void)
{
    800059f2:	7121                	addi	sp,sp,-448
    800059f4:	ff06                	sd	ra,440(sp)
    800059f6:	fb22                	sd	s0,432(sp)
    800059f8:	f726                	sd	s1,424(sp)
    800059fa:	f34a                	sd	s2,416(sp)
    800059fc:	ef4e                	sd	s3,408(sp)
    800059fe:	eb52                	sd	s4,400(sp)
    80005a00:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a02:	e4840593          	addi	a1,s0,-440
    80005a06:	4505                	li	a0,1
    80005a08:	ffffd097          	auipc	ra,0xffffd
    80005a0c:	1c8080e7          	jalr	456(ra) # 80002bd0 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005a10:	08000613          	li	a2,128
    80005a14:	f5040593          	addi	a1,s0,-176
    80005a18:	4501                	li	a0,0
    80005a1a:	ffffd097          	auipc	ra,0xffffd
    80005a1e:	1d6080e7          	jalr	470(ra) # 80002bf0 <argstr>
    80005a22:	87aa                	mv	a5,a0
    return -1;
    80005a24:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005a26:	0c07c263          	bltz	a5,80005aea <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005a2a:	10000613          	li	a2,256
    80005a2e:	4581                	li	a1,0
    80005a30:	e5040513          	addi	a0,s0,-432
    80005a34:	ffffb097          	auipc	ra,0xffffb
    80005a38:	310080e7          	jalr	784(ra) # 80000d44 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a3c:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005a40:	89a6                	mv	s3,s1
    80005a42:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a44:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a48:	00391513          	slli	a0,s2,0x3
    80005a4c:	e4040593          	addi	a1,s0,-448
    80005a50:	e4843783          	ld	a5,-440(s0)
    80005a54:	953e                	add	a0,a0,a5
    80005a56:	ffffd097          	auipc	ra,0xffffd
    80005a5a:	0bc080e7          	jalr	188(ra) # 80002b12 <fetchaddr>
    80005a5e:	02054a63          	bltz	a0,80005a92 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005a62:	e4043783          	ld	a5,-448(s0)
    80005a66:	c3b9                	beqz	a5,80005aac <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a68:	ffffb097          	auipc	ra,0xffffb
    80005a6c:	0f0080e7          	jalr	240(ra) # 80000b58 <kalloc>
    80005a70:	85aa                	mv	a1,a0
    80005a72:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a76:	cd11                	beqz	a0,80005a92 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a78:	6605                	lui	a2,0x1
    80005a7a:	e4043503          	ld	a0,-448(s0)
    80005a7e:	ffffd097          	auipc	ra,0xffffd
    80005a82:	0e6080e7          	jalr	230(ra) # 80002b64 <fetchstr>
    80005a86:	00054663          	bltz	a0,80005a92 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005a8a:	0905                	addi	s2,s2,1
    80005a8c:	09a1                	addi	s3,s3,8
    80005a8e:	fb491de3          	bne	s2,s4,80005a48 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a92:	f5040913          	addi	s2,s0,-176
    80005a96:	6088                	ld	a0,0(s1)
    80005a98:	c921                	beqz	a0,80005ae8 <sys_exec+0xf6>
    kfree(argv[i]);
    80005a9a:	ffffb097          	auipc	ra,0xffffb
    80005a9e:	fc0080e7          	jalr	-64(ra) # 80000a5a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aa2:	04a1                	addi	s1,s1,8
    80005aa4:	ff2499e3          	bne	s1,s2,80005a96 <sys_exec+0xa4>
  return -1;
    80005aa8:	557d                	li	a0,-1
    80005aaa:	a081                	j	80005aea <sys_exec+0xf8>
      argv[i] = 0;
    80005aac:	0009079b          	sext.w	a5,s2
    80005ab0:	078e                	slli	a5,a5,0x3
    80005ab2:	fd078793          	addi	a5,a5,-48
    80005ab6:	97a2                	add	a5,a5,s0
    80005ab8:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005abc:	e5040593          	addi	a1,s0,-432
    80005ac0:	f5040513          	addi	a0,s0,-176
    80005ac4:	fffff097          	auipc	ra,0xfffff
    80005ac8:	12e080e7          	jalr	302(ra) # 80004bf2 <exec>
    80005acc:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ace:	f5040993          	addi	s3,s0,-176
    80005ad2:	6088                	ld	a0,0(s1)
    80005ad4:	c901                	beqz	a0,80005ae4 <sys_exec+0xf2>
    kfree(argv[i]);
    80005ad6:	ffffb097          	auipc	ra,0xffffb
    80005ada:	f84080e7          	jalr	-124(ra) # 80000a5a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ade:	04a1                	addi	s1,s1,8
    80005ae0:	ff3499e3          	bne	s1,s3,80005ad2 <sys_exec+0xe0>
  return ret;
    80005ae4:	854a                	mv	a0,s2
    80005ae6:	a011                	j	80005aea <sys_exec+0xf8>
  return -1;
    80005ae8:	557d                	li	a0,-1
}
    80005aea:	70fa                	ld	ra,440(sp)
    80005aec:	745a                	ld	s0,432(sp)
    80005aee:	74ba                	ld	s1,424(sp)
    80005af0:	791a                	ld	s2,416(sp)
    80005af2:	69fa                	ld	s3,408(sp)
    80005af4:	6a5a                	ld	s4,400(sp)
    80005af6:	6139                	addi	sp,sp,448
    80005af8:	8082                	ret

0000000080005afa <sys_pipe>:

uint64
sys_pipe(void)
{
    80005afa:	7139                	addi	sp,sp,-64
    80005afc:	fc06                	sd	ra,56(sp)
    80005afe:	f822                	sd	s0,48(sp)
    80005b00:	f426                	sd	s1,40(sp)
    80005b02:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b04:	ffffc097          	auipc	ra,0xffffc
    80005b08:	f20080e7          	jalr	-224(ra) # 80001a24 <myproc>
    80005b0c:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005b0e:	fd840593          	addi	a1,s0,-40
    80005b12:	4501                	li	a0,0
    80005b14:	ffffd097          	auipc	ra,0xffffd
    80005b18:	0bc080e7          	jalr	188(ra) # 80002bd0 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005b1c:	fc840593          	addi	a1,s0,-56
    80005b20:	fd040513          	addi	a0,s0,-48
    80005b24:	fffff097          	auipc	ra,0xfffff
    80005b28:	d84080e7          	jalr	-636(ra) # 800048a8 <pipealloc>
    return -1;
    80005b2c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b2e:	0c054463          	bltz	a0,80005bf6 <sys_pipe+0xfc>
  fd0 = -1;
    80005b32:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b36:	fd043503          	ld	a0,-48(s0)
    80005b3a:	fffff097          	auipc	ra,0xfffff
    80005b3e:	524080e7          	jalr	1316(ra) # 8000505e <fdalloc>
    80005b42:	fca42223          	sw	a0,-60(s0)
    80005b46:	08054b63          	bltz	a0,80005bdc <sys_pipe+0xe2>
    80005b4a:	fc843503          	ld	a0,-56(s0)
    80005b4e:	fffff097          	auipc	ra,0xfffff
    80005b52:	510080e7          	jalr	1296(ra) # 8000505e <fdalloc>
    80005b56:	fca42023          	sw	a0,-64(s0)
    80005b5a:	06054863          	bltz	a0,80005bca <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b5e:	4691                	li	a3,4
    80005b60:	fc440613          	addi	a2,s0,-60
    80005b64:	fd843583          	ld	a1,-40(s0)
    80005b68:	68a8                	ld	a0,80(s1)
    80005b6a:	ffffc097          	auipc	ra,0xffffc
    80005b6e:	b7a080e7          	jalr	-1158(ra) # 800016e4 <copyout>
    80005b72:	02054063          	bltz	a0,80005b92 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b76:	4691                	li	a3,4
    80005b78:	fc040613          	addi	a2,s0,-64
    80005b7c:	fd843583          	ld	a1,-40(s0)
    80005b80:	0591                	addi	a1,a1,4
    80005b82:	68a8                	ld	a0,80(s1)
    80005b84:	ffffc097          	auipc	ra,0xffffc
    80005b88:	b60080e7          	jalr	-1184(ra) # 800016e4 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b8c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b8e:	06055463          	bgez	a0,80005bf6 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005b92:	fc442783          	lw	a5,-60(s0)
    80005b96:	07e9                	addi	a5,a5,26
    80005b98:	078e                	slli	a5,a5,0x3
    80005b9a:	97a6                	add	a5,a5,s1
    80005b9c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005ba0:	fc042783          	lw	a5,-64(s0)
    80005ba4:	07e9                	addi	a5,a5,26
    80005ba6:	078e                	slli	a5,a5,0x3
    80005ba8:	94be                	add	s1,s1,a5
    80005baa:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005bae:	fd043503          	ld	a0,-48(s0)
    80005bb2:	fffff097          	auipc	ra,0xfffff
    80005bb6:	9ca080e7          	jalr	-1590(ra) # 8000457c <fileclose>
    fileclose(wf);
    80005bba:	fc843503          	ld	a0,-56(s0)
    80005bbe:	fffff097          	auipc	ra,0xfffff
    80005bc2:	9be080e7          	jalr	-1602(ra) # 8000457c <fileclose>
    return -1;
    80005bc6:	57fd                	li	a5,-1
    80005bc8:	a03d                	j	80005bf6 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005bca:	fc442783          	lw	a5,-60(s0)
    80005bce:	0007c763          	bltz	a5,80005bdc <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005bd2:	07e9                	addi	a5,a5,26
    80005bd4:	078e                	slli	a5,a5,0x3
    80005bd6:	97a6                	add	a5,a5,s1
    80005bd8:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005bdc:	fd043503          	ld	a0,-48(s0)
    80005be0:	fffff097          	auipc	ra,0xfffff
    80005be4:	99c080e7          	jalr	-1636(ra) # 8000457c <fileclose>
    fileclose(wf);
    80005be8:	fc843503          	ld	a0,-56(s0)
    80005bec:	fffff097          	auipc	ra,0xfffff
    80005bf0:	990080e7          	jalr	-1648(ra) # 8000457c <fileclose>
    return -1;
    80005bf4:	57fd                	li	a5,-1
}
    80005bf6:	853e                	mv	a0,a5
    80005bf8:	70e2                	ld	ra,56(sp)
    80005bfa:	7442                	ld	s0,48(sp)
    80005bfc:	74a2                	ld	s1,40(sp)
    80005bfe:	6121                	addi	sp,sp,64
    80005c00:	8082                	ret
	...

0000000080005c10 <kernelvec>:
    80005c10:	7111                	addi	sp,sp,-256
    80005c12:	e006                	sd	ra,0(sp)
    80005c14:	e40a                	sd	sp,8(sp)
    80005c16:	e80e                	sd	gp,16(sp)
    80005c18:	ec12                	sd	tp,24(sp)
    80005c1a:	f016                	sd	t0,32(sp)
    80005c1c:	f41a                	sd	t1,40(sp)
    80005c1e:	f81e                	sd	t2,48(sp)
    80005c20:	fc22                	sd	s0,56(sp)
    80005c22:	e0a6                	sd	s1,64(sp)
    80005c24:	e4aa                	sd	a0,72(sp)
    80005c26:	e8ae                	sd	a1,80(sp)
    80005c28:	ecb2                	sd	a2,88(sp)
    80005c2a:	f0b6                	sd	a3,96(sp)
    80005c2c:	f4ba                	sd	a4,104(sp)
    80005c2e:	f8be                	sd	a5,112(sp)
    80005c30:	fcc2                	sd	a6,120(sp)
    80005c32:	e146                	sd	a7,128(sp)
    80005c34:	e54a                	sd	s2,136(sp)
    80005c36:	e94e                	sd	s3,144(sp)
    80005c38:	ed52                	sd	s4,152(sp)
    80005c3a:	f156                	sd	s5,160(sp)
    80005c3c:	f55a                	sd	s6,168(sp)
    80005c3e:	f95e                	sd	s7,176(sp)
    80005c40:	fd62                	sd	s8,184(sp)
    80005c42:	e1e6                	sd	s9,192(sp)
    80005c44:	e5ea                	sd	s10,200(sp)
    80005c46:	e9ee                	sd	s11,208(sp)
    80005c48:	edf2                	sd	t3,216(sp)
    80005c4a:	f1f6                	sd	t4,224(sp)
    80005c4c:	f5fa                	sd	t5,232(sp)
    80005c4e:	f9fe                	sd	t6,240(sp)
    80005c50:	d8ffc0ef          	jal	ra,800029de <kerneltrap>
    80005c54:	6082                	ld	ra,0(sp)
    80005c56:	6122                	ld	sp,8(sp)
    80005c58:	61c2                	ld	gp,16(sp)
    80005c5a:	7282                	ld	t0,32(sp)
    80005c5c:	7322                	ld	t1,40(sp)
    80005c5e:	73c2                	ld	t2,48(sp)
    80005c60:	7462                	ld	s0,56(sp)
    80005c62:	6486                	ld	s1,64(sp)
    80005c64:	6526                	ld	a0,72(sp)
    80005c66:	65c6                	ld	a1,80(sp)
    80005c68:	6666                	ld	a2,88(sp)
    80005c6a:	7686                	ld	a3,96(sp)
    80005c6c:	7726                	ld	a4,104(sp)
    80005c6e:	77c6                	ld	a5,112(sp)
    80005c70:	7866                	ld	a6,120(sp)
    80005c72:	688a                	ld	a7,128(sp)
    80005c74:	692a                	ld	s2,136(sp)
    80005c76:	69ca                	ld	s3,144(sp)
    80005c78:	6a6a                	ld	s4,152(sp)
    80005c7a:	7a8a                	ld	s5,160(sp)
    80005c7c:	7b2a                	ld	s6,168(sp)
    80005c7e:	7bca                	ld	s7,176(sp)
    80005c80:	7c6a                	ld	s8,184(sp)
    80005c82:	6c8e                	ld	s9,192(sp)
    80005c84:	6d2e                	ld	s10,200(sp)
    80005c86:	6dce                	ld	s11,208(sp)
    80005c88:	6e6e                	ld	t3,216(sp)
    80005c8a:	7e8e                	ld	t4,224(sp)
    80005c8c:	7f2e                	ld	t5,232(sp)
    80005c8e:	7fce                	ld	t6,240(sp)
    80005c90:	6111                	addi	sp,sp,256
    80005c92:	10200073          	sret
    80005c96:	00000013          	nop
    80005c9a:	00000013          	nop
    80005c9e:	0001                	nop

0000000080005ca0 <timervec>:
    80005ca0:	34051573          	csrrw	a0,mscratch,a0
    80005ca4:	e10c                	sd	a1,0(a0)
    80005ca6:	e510                	sd	a2,8(a0)
    80005ca8:	e914                	sd	a3,16(a0)
    80005caa:	6d0c                	ld	a1,24(a0)
    80005cac:	7110                	ld	a2,32(a0)
    80005cae:	6194                	ld	a3,0(a1)
    80005cb0:	96b2                	add	a3,a3,a2
    80005cb2:	e194                	sd	a3,0(a1)
    80005cb4:	4589                	li	a1,2
    80005cb6:	14459073          	csrw	sip,a1
    80005cba:	6914                	ld	a3,16(a0)
    80005cbc:	6510                	ld	a2,8(a0)
    80005cbe:	610c                	ld	a1,0(a0)
    80005cc0:	34051573          	csrrw	a0,mscratch,a0
    80005cc4:	30200073          	mret
	...

0000000080005cca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005cca:	1141                	addi	sp,sp,-16
    80005ccc:	e422                	sd	s0,8(sp)
    80005cce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005cd0:	0c0007b7          	lui	a5,0xc000
    80005cd4:	4705                	li	a4,1
    80005cd6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005cd8:	c3d8                	sw	a4,4(a5)
}
    80005cda:	6422                	ld	s0,8(sp)
    80005cdc:	0141                	addi	sp,sp,16
    80005cde:	8082                	ret

0000000080005ce0 <plicinithart>:

void
plicinithart(void)
{
    80005ce0:	1141                	addi	sp,sp,-16
    80005ce2:	e406                	sd	ra,8(sp)
    80005ce4:	e022                	sd	s0,0(sp)
    80005ce6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ce8:	ffffc097          	auipc	ra,0xffffc
    80005cec:	d10080e7          	jalr	-752(ra) # 800019f8 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005cf0:	0085171b          	slliw	a4,a0,0x8
    80005cf4:	0c0027b7          	lui	a5,0xc002
    80005cf8:	97ba                	add	a5,a5,a4
    80005cfa:	40200713          	li	a4,1026
    80005cfe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d02:	00d5151b          	slliw	a0,a0,0xd
    80005d06:	0c2017b7          	lui	a5,0xc201
    80005d0a:	97aa                	add	a5,a5,a0
    80005d0c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005d10:	60a2                	ld	ra,8(sp)
    80005d12:	6402                	ld	s0,0(sp)
    80005d14:	0141                	addi	sp,sp,16
    80005d16:	8082                	ret

0000000080005d18 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d18:	1141                	addi	sp,sp,-16
    80005d1a:	e406                	sd	ra,8(sp)
    80005d1c:	e022                	sd	s0,0(sp)
    80005d1e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d20:	ffffc097          	auipc	ra,0xffffc
    80005d24:	cd8080e7          	jalr	-808(ra) # 800019f8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d28:	00d5151b          	slliw	a0,a0,0xd
    80005d2c:	0c2017b7          	lui	a5,0xc201
    80005d30:	97aa                	add	a5,a5,a0
  return irq;
}
    80005d32:	43c8                	lw	a0,4(a5)
    80005d34:	60a2                	ld	ra,8(sp)
    80005d36:	6402                	ld	s0,0(sp)
    80005d38:	0141                	addi	sp,sp,16
    80005d3a:	8082                	ret

0000000080005d3c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d3c:	1101                	addi	sp,sp,-32
    80005d3e:	ec06                	sd	ra,24(sp)
    80005d40:	e822                	sd	s0,16(sp)
    80005d42:	e426                	sd	s1,8(sp)
    80005d44:	1000                	addi	s0,sp,32
    80005d46:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d48:	ffffc097          	auipc	ra,0xffffc
    80005d4c:	cb0080e7          	jalr	-848(ra) # 800019f8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d50:	00d5151b          	slliw	a0,a0,0xd
    80005d54:	0c2017b7          	lui	a5,0xc201
    80005d58:	97aa                	add	a5,a5,a0
    80005d5a:	c3c4                	sw	s1,4(a5)
}
    80005d5c:	60e2                	ld	ra,24(sp)
    80005d5e:	6442                	ld	s0,16(sp)
    80005d60:	64a2                	ld	s1,8(sp)
    80005d62:	6105                	addi	sp,sp,32
    80005d64:	8082                	ret

0000000080005d66 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d66:	1141                	addi	sp,sp,-16
    80005d68:	e406                	sd	ra,8(sp)
    80005d6a:	e022                	sd	s0,0(sp)
    80005d6c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d6e:	479d                	li	a5,7
    80005d70:	04a7cc63          	blt	a5,a0,80005dc8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005d74:	00024797          	auipc	a5,0x24
    80005d78:	b4c78793          	addi	a5,a5,-1204 # 800298c0 <disk>
    80005d7c:	97aa                	add	a5,a5,a0
    80005d7e:	0187c783          	lbu	a5,24(a5)
    80005d82:	ebb9                	bnez	a5,80005dd8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d84:	00451693          	slli	a3,a0,0x4
    80005d88:	00024797          	auipc	a5,0x24
    80005d8c:	b3878793          	addi	a5,a5,-1224 # 800298c0 <disk>
    80005d90:	6398                	ld	a4,0(a5)
    80005d92:	9736                	add	a4,a4,a3
    80005d94:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005d98:	6398                	ld	a4,0(a5)
    80005d9a:	9736                	add	a4,a4,a3
    80005d9c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005da0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005da4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005da8:	97aa                	add	a5,a5,a0
    80005daa:	4705                	li	a4,1
    80005dac:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005db0:	00024517          	auipc	a0,0x24
    80005db4:	b2850513          	addi	a0,a0,-1240 # 800298d8 <disk+0x18>
    80005db8:	ffffc097          	auipc	ra,0xffffc
    80005dbc:	3b2080e7          	jalr	946(ra) # 8000216a <wakeup>
}
    80005dc0:	60a2                	ld	ra,8(sp)
    80005dc2:	6402                	ld	s0,0(sp)
    80005dc4:	0141                	addi	sp,sp,16
    80005dc6:	8082                	ret
    panic("free_desc 1");
    80005dc8:	00003517          	auipc	a0,0x3
    80005dcc:	9f850513          	addi	a0,a0,-1544 # 800087c0 <syscalls+0x368>
    80005dd0:	ffffa097          	auipc	ra,0xffffa
    80005dd4:	770080e7          	jalr	1904(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005dd8:	00003517          	auipc	a0,0x3
    80005ddc:	9f850513          	addi	a0,a0,-1544 # 800087d0 <syscalls+0x378>
    80005de0:	ffffa097          	auipc	ra,0xffffa
    80005de4:	760080e7          	jalr	1888(ra) # 80000540 <panic>

0000000080005de8 <virtio_disk_init>:
{
    80005de8:	1101                	addi	sp,sp,-32
    80005dea:	ec06                	sd	ra,24(sp)
    80005dec:	e822                	sd	s0,16(sp)
    80005dee:	e426                	sd	s1,8(sp)
    80005df0:	e04a                	sd	s2,0(sp)
    80005df2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005df4:	00003597          	auipc	a1,0x3
    80005df8:	9ec58593          	addi	a1,a1,-1556 # 800087e0 <syscalls+0x388>
    80005dfc:	00024517          	auipc	a0,0x24
    80005e00:	bec50513          	addi	a0,a0,-1044 # 800299e8 <disk+0x128>
    80005e04:	ffffb097          	auipc	ra,0xffffb
    80005e08:	db4080e7          	jalr	-588(ra) # 80000bb8 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e0c:	100017b7          	lui	a5,0x10001
    80005e10:	4398                	lw	a4,0(a5)
    80005e12:	2701                	sext.w	a4,a4
    80005e14:	747277b7          	lui	a5,0x74727
    80005e18:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e1c:	14f71b63          	bne	a4,a5,80005f72 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e20:	100017b7          	lui	a5,0x10001
    80005e24:	43dc                	lw	a5,4(a5)
    80005e26:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e28:	4709                	li	a4,2
    80005e2a:	14e79463          	bne	a5,a4,80005f72 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e2e:	100017b7          	lui	a5,0x10001
    80005e32:	479c                	lw	a5,8(a5)
    80005e34:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e36:	12e79e63          	bne	a5,a4,80005f72 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e3a:	100017b7          	lui	a5,0x10001
    80005e3e:	47d8                	lw	a4,12(a5)
    80005e40:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e42:	554d47b7          	lui	a5,0x554d4
    80005e46:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e4a:	12f71463          	bne	a4,a5,80005f72 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e4e:	100017b7          	lui	a5,0x10001
    80005e52:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e56:	4705                	li	a4,1
    80005e58:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e5a:	470d                	li	a4,3
    80005e5c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e5e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e60:	c7ffe6b7          	lui	a3,0xc7ffe
    80005e64:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd4b8f>
    80005e68:	8f75                	and	a4,a4,a3
    80005e6a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e6c:	472d                	li	a4,11
    80005e6e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005e70:	5bbc                	lw	a5,112(a5)
    80005e72:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005e76:	8ba1                	andi	a5,a5,8
    80005e78:	10078563          	beqz	a5,80005f82 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e7c:	100017b7          	lui	a5,0x10001
    80005e80:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005e84:	43fc                	lw	a5,68(a5)
    80005e86:	2781                	sext.w	a5,a5
    80005e88:	10079563          	bnez	a5,80005f92 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e8c:	100017b7          	lui	a5,0x10001
    80005e90:	5bdc                	lw	a5,52(a5)
    80005e92:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e94:	10078763          	beqz	a5,80005fa2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005e98:	471d                	li	a4,7
    80005e9a:	10f77c63          	bgeu	a4,a5,80005fb2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005e9e:	ffffb097          	auipc	ra,0xffffb
    80005ea2:	cba080e7          	jalr	-838(ra) # 80000b58 <kalloc>
    80005ea6:	00024497          	auipc	s1,0x24
    80005eaa:	a1a48493          	addi	s1,s1,-1510 # 800298c0 <disk>
    80005eae:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005eb0:	ffffb097          	auipc	ra,0xffffb
    80005eb4:	ca8080e7          	jalr	-856(ra) # 80000b58 <kalloc>
    80005eb8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005eba:	ffffb097          	auipc	ra,0xffffb
    80005ebe:	c9e080e7          	jalr	-866(ra) # 80000b58 <kalloc>
    80005ec2:	87aa                	mv	a5,a0
    80005ec4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005ec6:	6088                	ld	a0,0(s1)
    80005ec8:	cd6d                	beqz	a0,80005fc2 <virtio_disk_init+0x1da>
    80005eca:	00024717          	auipc	a4,0x24
    80005ece:	9fe73703          	ld	a4,-1538(a4) # 800298c8 <disk+0x8>
    80005ed2:	cb65                	beqz	a4,80005fc2 <virtio_disk_init+0x1da>
    80005ed4:	c7fd                	beqz	a5,80005fc2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005ed6:	6605                	lui	a2,0x1
    80005ed8:	4581                	li	a1,0
    80005eda:	ffffb097          	auipc	ra,0xffffb
    80005ede:	e6a080e7          	jalr	-406(ra) # 80000d44 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005ee2:	00024497          	auipc	s1,0x24
    80005ee6:	9de48493          	addi	s1,s1,-1570 # 800298c0 <disk>
    80005eea:	6605                	lui	a2,0x1
    80005eec:	4581                	li	a1,0
    80005eee:	6488                	ld	a0,8(s1)
    80005ef0:	ffffb097          	auipc	ra,0xffffb
    80005ef4:	e54080e7          	jalr	-428(ra) # 80000d44 <memset>
  memset(disk.used, 0, PGSIZE);
    80005ef8:	6605                	lui	a2,0x1
    80005efa:	4581                	li	a1,0
    80005efc:	6888                	ld	a0,16(s1)
    80005efe:	ffffb097          	auipc	ra,0xffffb
    80005f02:	e46080e7          	jalr	-442(ra) # 80000d44 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f06:	100017b7          	lui	a5,0x10001
    80005f0a:	4721                	li	a4,8
    80005f0c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005f0e:	4098                	lw	a4,0(s1)
    80005f10:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005f14:	40d8                	lw	a4,4(s1)
    80005f16:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005f1a:	6498                	ld	a4,8(s1)
    80005f1c:	0007069b          	sext.w	a3,a4
    80005f20:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005f24:	9701                	srai	a4,a4,0x20
    80005f26:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005f2a:	6898                	ld	a4,16(s1)
    80005f2c:	0007069b          	sext.w	a3,a4
    80005f30:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005f34:	9701                	srai	a4,a4,0x20
    80005f36:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005f3a:	4705                	li	a4,1
    80005f3c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005f3e:	00e48c23          	sb	a4,24(s1)
    80005f42:	00e48ca3          	sb	a4,25(s1)
    80005f46:	00e48d23          	sb	a4,26(s1)
    80005f4a:	00e48da3          	sb	a4,27(s1)
    80005f4e:	00e48e23          	sb	a4,28(s1)
    80005f52:	00e48ea3          	sb	a4,29(s1)
    80005f56:	00e48f23          	sb	a4,30(s1)
    80005f5a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005f5e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f62:	0727a823          	sw	s2,112(a5)
}
    80005f66:	60e2                	ld	ra,24(sp)
    80005f68:	6442                	ld	s0,16(sp)
    80005f6a:	64a2                	ld	s1,8(sp)
    80005f6c:	6902                	ld	s2,0(sp)
    80005f6e:	6105                	addi	sp,sp,32
    80005f70:	8082                	ret
    panic("could not find virtio disk");
    80005f72:	00003517          	auipc	a0,0x3
    80005f76:	87e50513          	addi	a0,a0,-1922 # 800087f0 <syscalls+0x398>
    80005f7a:	ffffa097          	auipc	ra,0xffffa
    80005f7e:	5c6080e7          	jalr	1478(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005f82:	00003517          	auipc	a0,0x3
    80005f86:	88e50513          	addi	a0,a0,-1906 # 80008810 <syscalls+0x3b8>
    80005f8a:	ffffa097          	auipc	ra,0xffffa
    80005f8e:	5b6080e7          	jalr	1462(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80005f92:	00003517          	auipc	a0,0x3
    80005f96:	89e50513          	addi	a0,a0,-1890 # 80008830 <syscalls+0x3d8>
    80005f9a:	ffffa097          	auipc	ra,0xffffa
    80005f9e:	5a6080e7          	jalr	1446(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80005fa2:	00003517          	auipc	a0,0x3
    80005fa6:	8ae50513          	addi	a0,a0,-1874 # 80008850 <syscalls+0x3f8>
    80005faa:	ffffa097          	auipc	ra,0xffffa
    80005fae:	596080e7          	jalr	1430(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80005fb2:	00003517          	auipc	a0,0x3
    80005fb6:	8be50513          	addi	a0,a0,-1858 # 80008870 <syscalls+0x418>
    80005fba:	ffffa097          	auipc	ra,0xffffa
    80005fbe:	586080e7          	jalr	1414(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80005fc2:	00003517          	auipc	a0,0x3
    80005fc6:	8ce50513          	addi	a0,a0,-1842 # 80008890 <syscalls+0x438>
    80005fca:	ffffa097          	auipc	ra,0xffffa
    80005fce:	576080e7          	jalr	1398(ra) # 80000540 <panic>

0000000080005fd2 <virtio_disk_init_bootloader>:
{
    80005fd2:	1101                	addi	sp,sp,-32
    80005fd4:	ec06                	sd	ra,24(sp)
    80005fd6:	e822                	sd	s0,16(sp)
    80005fd8:	e426                	sd	s1,8(sp)
    80005fda:	e04a                	sd	s2,0(sp)
    80005fdc:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005fde:	00003597          	auipc	a1,0x3
    80005fe2:	80258593          	addi	a1,a1,-2046 # 800087e0 <syscalls+0x388>
    80005fe6:	00024517          	auipc	a0,0x24
    80005fea:	a0250513          	addi	a0,a0,-1534 # 800299e8 <disk+0x128>
    80005fee:	ffffb097          	auipc	ra,0xffffb
    80005ff2:	bca080e7          	jalr	-1078(ra) # 80000bb8 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ff6:	100017b7          	lui	a5,0x10001
    80005ffa:	4398                	lw	a4,0(a5)
    80005ffc:	2701                	sext.w	a4,a4
    80005ffe:	747277b7          	lui	a5,0x74727
    80006002:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006006:	12f71763          	bne	a4,a5,80006134 <virtio_disk_init_bootloader+0x162>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    8000600a:	100017b7          	lui	a5,0x10001
    8000600e:	43dc                	lw	a5,4(a5)
    80006010:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006012:	4709                	li	a4,2
    80006014:	12e79063          	bne	a5,a4,80006134 <virtio_disk_init_bootloader+0x162>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006018:	100017b7          	lui	a5,0x10001
    8000601c:	479c                	lw	a5,8(a5)
    8000601e:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006020:	10e79a63          	bne	a5,a4,80006134 <virtio_disk_init_bootloader+0x162>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006024:	100017b7          	lui	a5,0x10001
    80006028:	47d8                	lw	a4,12(a5)
    8000602a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000602c:	554d47b7          	lui	a5,0x554d4
    80006030:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006034:	10f71063          	bne	a4,a5,80006134 <virtio_disk_init_bootloader+0x162>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006038:	100017b7          	lui	a5,0x10001
    8000603c:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006040:	4705                	li	a4,1
    80006042:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006044:	470d                	li	a4,3
    80006046:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006048:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000604a:	c7ffe6b7          	lui	a3,0xc7ffe
    8000604e:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd4b8f>
    80006052:	8f75                	and	a4,a4,a3
    80006054:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006056:	472d                	li	a4,11
    80006058:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    8000605a:	5bbc                	lw	a5,112(a5)
    8000605c:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006060:	8ba1                	andi	a5,a5,8
    80006062:	c3ed                	beqz	a5,80006144 <virtio_disk_init_bootloader+0x172>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006064:	100017b7          	lui	a5,0x10001
    80006068:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    8000606c:	43fc                	lw	a5,68(a5)
    8000606e:	2781                	sext.w	a5,a5
    80006070:	e3f5                	bnez	a5,80006154 <virtio_disk_init_bootloader+0x182>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006072:	100017b7          	lui	a5,0x10001
    80006076:	5bdc                	lw	a5,52(a5)
    80006078:	2781                	sext.w	a5,a5
  if(max == 0)
    8000607a:	c7ed                	beqz	a5,80006164 <virtio_disk_init_bootloader+0x192>
  if(max < NUM)
    8000607c:	471d                	li	a4,7
    8000607e:	0ef77b63          	bgeu	a4,a5,80006174 <virtio_disk_init_bootloader+0x1a2>
  disk.desc  = (void*) 0x77000000;
    80006082:	00024497          	auipc	s1,0x24
    80006086:	83e48493          	addi	s1,s1,-1986 # 800298c0 <disk>
    8000608a:	770007b7          	lui	a5,0x77000
    8000608e:	e09c                	sd	a5,0(s1)
  disk.avail = (void*) 0x77001000;
    80006090:	770017b7          	lui	a5,0x77001
    80006094:	e49c                	sd	a5,8(s1)
  disk.used  = (void*) 0x77002000;
    80006096:	770027b7          	lui	a5,0x77002
    8000609a:	e89c                	sd	a5,16(s1)
  memset(disk.desc, 0, PGSIZE);
    8000609c:	6605                	lui	a2,0x1
    8000609e:	4581                	li	a1,0
    800060a0:	77000537          	lui	a0,0x77000
    800060a4:	ffffb097          	auipc	ra,0xffffb
    800060a8:	ca0080e7          	jalr	-864(ra) # 80000d44 <memset>
  memset(disk.avail, 0, PGSIZE);
    800060ac:	6605                	lui	a2,0x1
    800060ae:	4581                	li	a1,0
    800060b0:	6488                	ld	a0,8(s1)
    800060b2:	ffffb097          	auipc	ra,0xffffb
    800060b6:	c92080e7          	jalr	-878(ra) # 80000d44 <memset>
  memset(disk.used, 0, PGSIZE);
    800060ba:	6605                	lui	a2,0x1
    800060bc:	4581                	li	a1,0
    800060be:	6888                	ld	a0,16(s1)
    800060c0:	ffffb097          	auipc	ra,0xffffb
    800060c4:	c84080e7          	jalr	-892(ra) # 80000d44 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060c8:	100017b7          	lui	a5,0x10001
    800060cc:	4721                	li	a4,8
    800060ce:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800060d0:	4098                	lw	a4,0(s1)
    800060d2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800060d6:	40d8                	lw	a4,4(s1)
    800060d8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800060dc:	6498                	ld	a4,8(s1)
    800060de:	0007069b          	sext.w	a3,a4
    800060e2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800060e6:	9701                	srai	a4,a4,0x20
    800060e8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800060ec:	6898                	ld	a4,16(s1)
    800060ee:	0007069b          	sext.w	a3,a4
    800060f2:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800060f6:	9701                	srai	a4,a4,0x20
    800060f8:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800060fc:	4705                	li	a4,1
    800060fe:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006100:	00e48c23          	sb	a4,24(s1)
    80006104:	00e48ca3          	sb	a4,25(s1)
    80006108:	00e48d23          	sb	a4,26(s1)
    8000610c:	00e48da3          	sb	a4,27(s1)
    80006110:	00e48e23          	sb	a4,28(s1)
    80006114:	00e48ea3          	sb	a4,29(s1)
    80006118:	00e48f23          	sb	a4,30(s1)
    8000611c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006120:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006124:	0727a823          	sw	s2,112(a5)
}
    80006128:	60e2                	ld	ra,24(sp)
    8000612a:	6442                	ld	s0,16(sp)
    8000612c:	64a2                	ld	s1,8(sp)
    8000612e:	6902                	ld	s2,0(sp)
    80006130:	6105                	addi	sp,sp,32
    80006132:	8082                	ret
    panic("could not find virtio disk");
    80006134:	00002517          	auipc	a0,0x2
    80006138:	6bc50513          	addi	a0,a0,1724 # 800087f0 <syscalls+0x398>
    8000613c:	ffffa097          	auipc	ra,0xffffa
    80006140:	404080e7          	jalr	1028(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006144:	00002517          	auipc	a0,0x2
    80006148:	6cc50513          	addi	a0,a0,1740 # 80008810 <syscalls+0x3b8>
    8000614c:	ffffa097          	auipc	ra,0xffffa
    80006150:	3f4080e7          	jalr	1012(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006154:	00002517          	auipc	a0,0x2
    80006158:	6dc50513          	addi	a0,a0,1756 # 80008830 <syscalls+0x3d8>
    8000615c:	ffffa097          	auipc	ra,0xffffa
    80006160:	3e4080e7          	jalr	996(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006164:	00002517          	auipc	a0,0x2
    80006168:	6ec50513          	addi	a0,a0,1772 # 80008850 <syscalls+0x3f8>
    8000616c:	ffffa097          	auipc	ra,0xffffa
    80006170:	3d4080e7          	jalr	980(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006174:	00002517          	auipc	a0,0x2
    80006178:	6fc50513          	addi	a0,a0,1788 # 80008870 <syscalls+0x418>
    8000617c:	ffffa097          	auipc	ra,0xffffa
    80006180:	3c4080e7          	jalr	964(ra) # 80000540 <panic>

0000000080006184 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006184:	7159                	addi	sp,sp,-112
    80006186:	f486                	sd	ra,104(sp)
    80006188:	f0a2                	sd	s0,96(sp)
    8000618a:	eca6                	sd	s1,88(sp)
    8000618c:	e8ca                	sd	s2,80(sp)
    8000618e:	e4ce                	sd	s3,72(sp)
    80006190:	e0d2                	sd	s4,64(sp)
    80006192:	fc56                	sd	s5,56(sp)
    80006194:	f85a                	sd	s6,48(sp)
    80006196:	f45e                	sd	s7,40(sp)
    80006198:	f062                	sd	s8,32(sp)
    8000619a:	ec66                	sd	s9,24(sp)
    8000619c:	e86a                	sd	s10,16(sp)
    8000619e:	1880                	addi	s0,sp,112
    800061a0:	8a2a                	mv	s4,a0
    800061a2:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061a4:	00c52c83          	lw	s9,12(a0)
    800061a8:	001c9c9b          	slliw	s9,s9,0x1
    800061ac:	1c82                	slli	s9,s9,0x20
    800061ae:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800061b2:	00024517          	auipc	a0,0x24
    800061b6:	83650513          	addi	a0,a0,-1994 # 800299e8 <disk+0x128>
    800061ba:	ffffb097          	auipc	ra,0xffffb
    800061be:	a8e080e7          	jalr	-1394(ra) # 80000c48 <acquire>
  for(int i = 0; i < 3; i++){
    800061c2:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    800061c4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800061c6:	00023b17          	auipc	s6,0x23
    800061ca:	6fab0b13          	addi	s6,s6,1786 # 800298c0 <disk>
  for(int i = 0; i < 3; i++){
    800061ce:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061d0:	00024c17          	auipc	s8,0x24
    800061d4:	818c0c13          	addi	s8,s8,-2024 # 800299e8 <disk+0x128>
    800061d8:	a095                	j	8000623c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800061da:	00fb0733          	add	a4,s6,a5
    800061de:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800061e2:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    800061e4:	0207c563          	bltz	a5,8000620e <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    800061e8:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    800061ea:	0591                	addi	a1,a1,4
    800061ec:	05560d63          	beq	a2,s5,80006246 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800061f0:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    800061f2:	00023717          	auipc	a4,0x23
    800061f6:	6ce70713          	addi	a4,a4,1742 # 800298c0 <disk>
    800061fa:	87ca                	mv	a5,s2
    if(disk.free[i]){
    800061fc:	01874683          	lbu	a3,24(a4)
    80006200:	fee9                	bnez	a3,800061da <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006202:	2785                	addiw	a5,a5,1
    80006204:	0705                	addi	a4,a4,1
    80006206:	fe979be3          	bne	a5,s1,800061fc <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    8000620a:	57fd                	li	a5,-1
    8000620c:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000620e:	00c05e63          	blez	a2,8000622a <virtio_disk_rw+0xa6>
    80006212:	060a                	slli	a2,a2,0x2
    80006214:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006218:	0009a503          	lw	a0,0(s3)
    8000621c:	00000097          	auipc	ra,0x0
    80006220:	b4a080e7          	jalr	-1206(ra) # 80005d66 <free_desc>
      for(int j = 0; j < i; j++)
    80006224:	0991                	addi	s3,s3,4
    80006226:	ffa999e3          	bne	s3,s10,80006218 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000622a:	85e2                	mv	a1,s8
    8000622c:	00023517          	auipc	a0,0x23
    80006230:	6ac50513          	addi	a0,a0,1708 # 800298d8 <disk+0x18>
    80006234:	ffffc097          	auipc	ra,0xffffc
    80006238:	ed2080e7          	jalr	-302(ra) # 80002106 <sleep>
  for(int i = 0; i < 3; i++){
    8000623c:	f9040993          	addi	s3,s0,-112
{
    80006240:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006242:	864a                	mv	a2,s2
    80006244:	b775                	j	800061f0 <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006246:	f9042503          	lw	a0,-112(s0)
    8000624a:	00a50713          	addi	a4,a0,10
    8000624e:	0712                	slli	a4,a4,0x4

  if(write)
    80006250:	00023797          	auipc	a5,0x23
    80006254:	67078793          	addi	a5,a5,1648 # 800298c0 <disk>
    80006258:	00e786b3          	add	a3,a5,a4
    8000625c:	01703633          	snez	a2,s7
    80006260:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006262:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006266:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000626a:	f6070613          	addi	a2,a4,-160
    8000626e:	6394                	ld	a3,0(a5)
    80006270:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006272:	00870593          	addi	a1,a4,8
    80006276:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006278:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000627a:	0007b803          	ld	a6,0(a5)
    8000627e:	9642                	add	a2,a2,a6
    80006280:	46c1                	li	a3,16
    80006282:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006284:	4585                	li	a1,1
    80006286:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    8000628a:	f9442683          	lw	a3,-108(s0)
    8000628e:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006292:	0692                	slli	a3,a3,0x4
    80006294:	9836                	add	a6,a6,a3
    80006296:	058a0613          	addi	a2,s4,88
    8000629a:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000629e:	0007b803          	ld	a6,0(a5)
    800062a2:	96c2                	add	a3,a3,a6
    800062a4:	40000613          	li	a2,1024
    800062a8:	c690                	sw	a2,8(a3)
  if(write)
    800062aa:	001bb613          	seqz	a2,s7
    800062ae:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062b2:	00166613          	ori	a2,a2,1
    800062b6:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800062ba:	f9842603          	lw	a2,-104(s0)
    800062be:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800062c2:	00250693          	addi	a3,a0,2
    800062c6:	0692                	slli	a3,a3,0x4
    800062c8:	96be                	add	a3,a3,a5
    800062ca:	58fd                	li	a7,-1
    800062cc:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800062d0:	0612                	slli	a2,a2,0x4
    800062d2:	9832                	add	a6,a6,a2
    800062d4:	f9070713          	addi	a4,a4,-112
    800062d8:	973e                	add	a4,a4,a5
    800062da:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800062de:	6398                	ld	a4,0(a5)
    800062e0:	9732                	add	a4,a4,a2
    800062e2:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062e4:	4609                	li	a2,2
    800062e6:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800062ea:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800062ee:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    800062f2:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800062f6:	6794                	ld	a3,8(a5)
    800062f8:	0026d703          	lhu	a4,2(a3)
    800062fc:	8b1d                	andi	a4,a4,7
    800062fe:	0706                	slli	a4,a4,0x1
    80006300:	96ba                	add	a3,a3,a4
    80006302:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006306:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000630a:	6798                	ld	a4,8(a5)
    8000630c:	00275783          	lhu	a5,2(a4)
    80006310:	2785                	addiw	a5,a5,1
    80006312:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006316:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000631a:	100017b7          	lui	a5,0x10001
    8000631e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006322:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006326:	00023917          	auipc	s2,0x23
    8000632a:	6c290913          	addi	s2,s2,1730 # 800299e8 <disk+0x128>
  while(b->disk == 1) {
    8000632e:	4485                	li	s1,1
    80006330:	00b79c63          	bne	a5,a1,80006348 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006334:	85ca                	mv	a1,s2
    80006336:	8552                	mv	a0,s4
    80006338:	ffffc097          	auipc	ra,0xffffc
    8000633c:	dce080e7          	jalr	-562(ra) # 80002106 <sleep>
  while(b->disk == 1) {
    80006340:	004a2783          	lw	a5,4(s4)
    80006344:	fe9788e3          	beq	a5,s1,80006334 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006348:	f9042903          	lw	s2,-112(s0)
    8000634c:	00290713          	addi	a4,s2,2
    80006350:	0712                	slli	a4,a4,0x4
    80006352:	00023797          	auipc	a5,0x23
    80006356:	56e78793          	addi	a5,a5,1390 # 800298c0 <disk>
    8000635a:	97ba                	add	a5,a5,a4
    8000635c:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006360:	00023997          	auipc	s3,0x23
    80006364:	56098993          	addi	s3,s3,1376 # 800298c0 <disk>
    80006368:	00491713          	slli	a4,s2,0x4
    8000636c:	0009b783          	ld	a5,0(s3)
    80006370:	97ba                	add	a5,a5,a4
    80006372:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006376:	854a                	mv	a0,s2
    80006378:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000637c:	00000097          	auipc	ra,0x0
    80006380:	9ea080e7          	jalr	-1558(ra) # 80005d66 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006384:	8885                	andi	s1,s1,1
    80006386:	f0ed                	bnez	s1,80006368 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006388:	00023517          	auipc	a0,0x23
    8000638c:	66050513          	addi	a0,a0,1632 # 800299e8 <disk+0x128>
    80006390:	ffffb097          	auipc	ra,0xffffb
    80006394:	96c080e7          	jalr	-1684(ra) # 80000cfc <release>
}
    80006398:	70a6                	ld	ra,104(sp)
    8000639a:	7406                	ld	s0,96(sp)
    8000639c:	64e6                	ld	s1,88(sp)
    8000639e:	6946                	ld	s2,80(sp)
    800063a0:	69a6                	ld	s3,72(sp)
    800063a2:	6a06                	ld	s4,64(sp)
    800063a4:	7ae2                	ld	s5,56(sp)
    800063a6:	7b42                	ld	s6,48(sp)
    800063a8:	7ba2                	ld	s7,40(sp)
    800063aa:	7c02                	ld	s8,32(sp)
    800063ac:	6ce2                	ld	s9,24(sp)
    800063ae:	6d42                	ld	s10,16(sp)
    800063b0:	6165                	addi	sp,sp,112
    800063b2:	8082                	ret

00000000800063b4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800063b4:	1101                	addi	sp,sp,-32
    800063b6:	ec06                	sd	ra,24(sp)
    800063b8:	e822                	sd	s0,16(sp)
    800063ba:	e426                	sd	s1,8(sp)
    800063bc:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063be:	00023497          	auipc	s1,0x23
    800063c2:	50248493          	addi	s1,s1,1282 # 800298c0 <disk>
    800063c6:	00023517          	auipc	a0,0x23
    800063ca:	62250513          	addi	a0,a0,1570 # 800299e8 <disk+0x128>
    800063ce:	ffffb097          	auipc	ra,0xffffb
    800063d2:	87a080e7          	jalr	-1926(ra) # 80000c48 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063d6:	10001737          	lui	a4,0x10001
    800063da:	533c                	lw	a5,96(a4)
    800063dc:	8b8d                	andi	a5,a5,3
    800063de:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800063e0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800063e4:	689c                	ld	a5,16(s1)
    800063e6:	0204d703          	lhu	a4,32(s1)
    800063ea:	0027d783          	lhu	a5,2(a5)
    800063ee:	04f70863          	beq	a4,a5,8000643e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800063f2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063f6:	6898                	ld	a4,16(s1)
    800063f8:	0204d783          	lhu	a5,32(s1)
    800063fc:	8b9d                	andi	a5,a5,7
    800063fe:	078e                	slli	a5,a5,0x3
    80006400:	97ba                	add	a5,a5,a4
    80006402:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006404:	00278713          	addi	a4,a5,2
    80006408:	0712                	slli	a4,a4,0x4
    8000640a:	9726                	add	a4,a4,s1
    8000640c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006410:	e721                	bnez	a4,80006458 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006412:	0789                	addi	a5,a5,2
    80006414:	0792                	slli	a5,a5,0x4
    80006416:	97a6                	add	a5,a5,s1
    80006418:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000641a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000641e:	ffffc097          	auipc	ra,0xffffc
    80006422:	d4c080e7          	jalr	-692(ra) # 8000216a <wakeup>

    disk.used_idx += 1;
    80006426:	0204d783          	lhu	a5,32(s1)
    8000642a:	2785                	addiw	a5,a5,1
    8000642c:	17c2                	slli	a5,a5,0x30
    8000642e:	93c1                	srli	a5,a5,0x30
    80006430:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006434:	6898                	ld	a4,16(s1)
    80006436:	00275703          	lhu	a4,2(a4)
    8000643a:	faf71ce3          	bne	a4,a5,800063f2 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000643e:	00023517          	auipc	a0,0x23
    80006442:	5aa50513          	addi	a0,a0,1450 # 800299e8 <disk+0x128>
    80006446:	ffffb097          	auipc	ra,0xffffb
    8000644a:	8b6080e7          	jalr	-1866(ra) # 80000cfc <release>
}
    8000644e:	60e2                	ld	ra,24(sp)
    80006450:	6442                	ld	s0,16(sp)
    80006452:	64a2                	ld	s1,8(sp)
    80006454:	6105                	addi	sp,sp,32
    80006456:	8082                	ret
      panic("virtio_disk_intr status");
    80006458:	00002517          	auipc	a0,0x2
    8000645c:	45050513          	addi	a0,a0,1104 # 800088a8 <syscalls+0x450>
    80006460:	ffffa097          	auipc	ra,0xffffa
    80006464:	0e0080e7          	jalr	224(ra) # 80000540 <panic>

0000000080006468 <ramdiskinit>:
/* TODO: find the location of the QEMU ramdisk. */
#define RAMDISK 0x84000000

void
ramdiskinit(void)
{
    80006468:	1141                	addi	sp,sp,-16
    8000646a:	e422                	sd	s0,8(sp)
    8000646c:	0800                	addi	s0,sp,16
}
    8000646e:	6422                	ld	s0,8(sp)
    80006470:	0141                	addi	sp,sp,16
    80006472:	8082                	ret

0000000080006474 <ramdiskrw>:

// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
ramdiskrw(struct buf *b)
{
    80006474:	1101                	addi	sp,sp,-32
    80006476:	ec06                	sd	ra,24(sp)
    80006478:	e822                	sd	s0,16(sp)
    8000647a:	e426                	sd	s1,8(sp)
    8000647c:	1000                	addi	s0,sp,32
    panic("ramdiskrw: buf not locked");
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
    panic("ramdiskrw: nothing to do");
#endif

  if(b->blockno >= FSSIZE)
    8000647e:	454c                	lw	a1,12(a0)
    80006480:	7cf00793          	li	a5,1999
    80006484:	02b7ea63          	bltu	a5,a1,800064b8 <ramdiskrw+0x44>
    80006488:	84aa                	mv	s1,a0
    panic("ramdiskrw: blockno too big");

  uint64 diskaddr = b->blockno * BSIZE;
    8000648a:	00a5959b          	slliw	a1,a1,0xa
    8000648e:	1582                	slli	a1,a1,0x20
    80006490:	9181                	srli	a1,a1,0x20
  char *addr = (char *)RAMDISK + diskaddr;

  // read from the location
  memmove(b->data, addr, BSIZE);
    80006492:	40000613          	li	a2,1024
    80006496:	02100793          	li	a5,33
    8000649a:	07ea                	slli	a5,a5,0x1a
    8000649c:	95be                	add	a1,a1,a5
    8000649e:	05850513          	addi	a0,a0,88
    800064a2:	ffffb097          	auipc	ra,0xffffb
    800064a6:	8fe080e7          	jalr	-1794(ra) # 80000da0 <memmove>
  b->valid = 1;
    800064aa:	4785                	li	a5,1
    800064ac:	c09c                	sw	a5,0(s1)
    // read
    memmove(b->data, addr, BSIZE);
    b->flags |= B_VALID;
  }
#endif
}
    800064ae:	60e2                	ld	ra,24(sp)
    800064b0:	6442                	ld	s0,16(sp)
    800064b2:	64a2                	ld	s1,8(sp)
    800064b4:	6105                	addi	sp,sp,32
    800064b6:	8082                	ret
    panic("ramdiskrw: blockno too big");
    800064b8:	00002517          	auipc	a0,0x2
    800064bc:	40850513          	addi	a0,a0,1032 # 800088c0 <syscalls+0x468>
    800064c0:	ffffa097          	auipc	ra,0xffffa
    800064c4:	080080e7          	jalr	128(ra) # 80000540 <panic>

00000000800064c8 <dump_hex>:
#include "fs.h"
#include "buf.h"
#include <stddef.h>

/* Acknowledgement: https://gist.github.com/ccbrown/9722406 */
void dump_hex(const void* data, size_t size) {
    800064c8:	7119                	addi	sp,sp,-128
    800064ca:	fc86                	sd	ra,120(sp)
    800064cc:	f8a2                	sd	s0,112(sp)
    800064ce:	f4a6                	sd	s1,104(sp)
    800064d0:	f0ca                	sd	s2,96(sp)
    800064d2:	ecce                	sd	s3,88(sp)
    800064d4:	e8d2                	sd	s4,80(sp)
    800064d6:	e4d6                	sd	s5,72(sp)
    800064d8:	e0da                	sd	s6,64(sp)
    800064da:	fc5e                	sd	s7,56(sp)
    800064dc:	f862                	sd	s8,48(sp)
    800064de:	f466                	sd	s9,40(sp)
    800064e0:	0100                	addi	s0,sp,128
	char ascii[17];
	size_t i, j;
	ascii[16] = '\0';
    800064e2:	f8040c23          	sb	zero,-104(s0)
	for (i = 0; i < size; ++i) {
    800064e6:	c5e1                	beqz	a1,800065ae <dump_hex+0xe6>
    800064e8:	89ae                	mv	s3,a1
    800064ea:	892a                	mv	s2,a0
    800064ec:	4481                	li	s1,0
		printf("%x ", ((unsigned char*)data)[i]);
    800064ee:	00002a97          	auipc	s5,0x2
    800064f2:	3f2a8a93          	addi	s5,s5,1010 # 800088e0 <syscalls+0x488>
		if (((unsigned char*)data)[i] >= ' ' && ((unsigned char*)data)[i] <= '~') {
    800064f6:	05e00a13          	li	s4,94
			ascii[i % 16] = ((unsigned char*)data)[i];
		} else {
			ascii[i % 16] = '.';
    800064fa:	02e00b13          	li	s6,46
		}
		if ((i+1) % 8 == 0 || i+1 == size) {
			printf(" ");
			if ((i+1) % 16 == 0) {
				printf("|  %s \n", ascii);
    800064fe:	00002c17          	auipc	s8,0x2
    80006502:	3f2c0c13          	addi	s8,s8,1010 # 800088f0 <syscalls+0x498>
			printf(" ");
    80006506:	00002b97          	auipc	s7,0x2
    8000650a:	3e2b8b93          	addi	s7,s7,994 # 800088e8 <syscalls+0x490>
    8000650e:	a839                	j	8000652c <dump_hex+0x64>
			ascii[i % 16] = '.';
    80006510:	00f4f793          	andi	a5,s1,15
    80006514:	fa078793          	addi	a5,a5,-96
    80006518:	97a2                	add	a5,a5,s0
    8000651a:	ff678423          	sb	s6,-24(a5)
		if ((i+1) % 8 == 0 || i+1 == size) {
    8000651e:	0485                	addi	s1,s1,1
    80006520:	0074f793          	andi	a5,s1,7
    80006524:	cb9d                	beqz	a5,8000655a <dump_hex+0x92>
    80006526:	0b348a63          	beq	s1,s3,800065da <dump_hex+0x112>
	for (i = 0; i < size; ++i) {
    8000652a:	0905                	addi	s2,s2,1
		printf("%x ", ((unsigned char*)data)[i]);
    8000652c:	00094583          	lbu	a1,0(s2)
    80006530:	8556                	mv	a0,s5
    80006532:	ffffa097          	auipc	ra,0xffffa
    80006536:	058080e7          	jalr	88(ra) # 8000058a <printf>
		if (((unsigned char*)data)[i] >= ' ' && ((unsigned char*)data)[i] <= '~') {
    8000653a:	00094703          	lbu	a4,0(s2)
    8000653e:	fe07079b          	addiw	a5,a4,-32
    80006542:	0ff7f793          	zext.b	a5,a5
    80006546:	fcfa65e3          	bltu	s4,a5,80006510 <dump_hex+0x48>
			ascii[i % 16] = ((unsigned char*)data)[i];
    8000654a:	00f4f793          	andi	a5,s1,15
    8000654e:	fa078793          	addi	a5,a5,-96
    80006552:	97a2                	add	a5,a5,s0
    80006554:	fee78423          	sb	a4,-24(a5)
    80006558:	b7d9                	j	8000651e <dump_hex+0x56>
			printf(" ");
    8000655a:	855e                	mv	a0,s7
    8000655c:	ffffa097          	auipc	ra,0xffffa
    80006560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
			if ((i+1) % 16 == 0) {
    80006564:	00f4fc93          	andi	s9,s1,15
    80006568:	080c8263          	beqz	s9,800065ec <dump_hex+0x124>
			} else if (i+1 == size) {
    8000656c:	fb349fe3          	bne	s1,s3,8000652a <dump_hex+0x62>
				ascii[(i+1) % 16] = '\0';
    80006570:	fa0c8793          	addi	a5,s9,-96
    80006574:	97a2                	add	a5,a5,s0
    80006576:	fe078423          	sb	zero,-24(a5)
				if ((i+1) % 16 <= 8) {
    8000657a:	47a1                	li	a5,8
    8000657c:	0597f663          	bgeu	a5,s9,800065c8 <dump_hex+0x100>
					printf(" ");
				}
				for (j = (i+1) % 16; j < 16; ++j) {
					printf("   ");
    80006580:	00002917          	auipc	s2,0x2
    80006584:	37890913          	addi	s2,s2,888 # 800088f8 <syscalls+0x4a0>
				for (j = (i+1) % 16; j < 16; ++j) {
    80006588:	44bd                	li	s1,15
					printf("   ");
    8000658a:	854a                	mv	a0,s2
    8000658c:	ffffa097          	auipc	ra,0xffffa
    80006590:	ffe080e7          	jalr	-2(ra) # 8000058a <printf>
				for (j = (i+1) % 16; j < 16; ++j) {
    80006594:	0c85                	addi	s9,s9,1
    80006596:	ff94fae3          	bgeu	s1,s9,8000658a <dump_hex+0xc2>
				}
				printf("|  %s \n", ascii);
    8000659a:	f8840593          	addi	a1,s0,-120
    8000659e:	00002517          	auipc	a0,0x2
    800065a2:	35250513          	addi	a0,a0,850 # 800088f0 <syscalls+0x498>
    800065a6:	ffffa097          	auipc	ra,0xffffa
    800065aa:	fe4080e7          	jalr	-28(ra) # 8000058a <printf>
			}
		}
	}
    800065ae:	70e6                	ld	ra,120(sp)
    800065b0:	7446                	ld	s0,112(sp)
    800065b2:	74a6                	ld	s1,104(sp)
    800065b4:	7906                	ld	s2,96(sp)
    800065b6:	69e6                	ld	s3,88(sp)
    800065b8:	6a46                	ld	s4,80(sp)
    800065ba:	6aa6                	ld	s5,72(sp)
    800065bc:	6b06                	ld	s6,64(sp)
    800065be:	7be2                	ld	s7,56(sp)
    800065c0:	7c42                	ld	s8,48(sp)
    800065c2:	7ca2                	ld	s9,40(sp)
    800065c4:	6109                	addi	sp,sp,128
    800065c6:	8082                	ret
					printf(" ");
    800065c8:	00002517          	auipc	a0,0x2
    800065cc:	32050513          	addi	a0,a0,800 # 800088e8 <syscalls+0x490>
    800065d0:	ffffa097          	auipc	ra,0xffffa
    800065d4:	fba080e7          	jalr	-70(ra) # 8000058a <printf>
    800065d8:	b765                	j	80006580 <dump_hex+0xb8>
			printf(" ");
    800065da:	855e                	mv	a0,s7
    800065dc:	ffffa097          	auipc	ra,0xffffa
    800065e0:	fae080e7          	jalr	-82(ra) # 8000058a <printf>
			if ((i+1) % 16 == 0) {
    800065e4:	00f9fc93          	andi	s9,s3,15
    800065e8:	f80c94e3          	bnez	s9,80006570 <dump_hex+0xa8>
				printf("|  %s \n", ascii);
    800065ec:	f8840593          	addi	a1,s0,-120
    800065f0:	8562                	mv	a0,s8
    800065f2:	ffffa097          	auipc	ra,0xffffa
    800065f6:	f98080e7          	jalr	-104(ra) # 8000058a <printf>
	for (i = 0; i < size; ++i) {
    800065fa:	fb348ae3          	beq	s1,s3,800065ae <dump_hex+0xe6>
    800065fe:	0905                	addi	s2,s2,1
    80006600:	b735                	j	8000652c <dump_hex+0x64>

0000000080006602 <reg_tf_map>:
    [CSR_pmpaddr14]     &vm_state.pmpaddr14,
    [CSR_pmpaddr15]     &vm_state.pmpaddr15,
};

/* Trap Frame Mappings*/
static uint64* reg_tf_map(struct trapframe *tf, uint32 register_val) {
    80006602:	1141                	addi	sp,sp,-16
    80006604:	e422                	sd	s0,8(sp)
    80006606:	0800                	addi	s0,sp,16
    
    switch(register_val) {
    80006608:	47bd                	li	a5,15
    8000660a:	06b7ea63          	bltu	a5,a1,8000667e <reg_tf_map+0x7c>
    8000660e:	058a                	slli	a1,a1,0x2
    80006610:	00002717          	auipc	a4,0x2
    80006614:	2f070713          	addi	a4,a4,752 # 80008900 <syscalls+0x4a8>
    80006618:	95ba                	add	a1,a1,a4
    8000661a:	419c                	lw	a5,0(a1)
    8000661c:	97ba                	add	a5,a5,a4
    8000661e:	8782                	jr	a5

        case REG_ra: return &tf->ra;
    80006620:	02850513          	addi	a0,a0,40
        case REG_a5: return &tf->a5;
        
        default: return &tf->a5;

    }
}
    80006624:	6422                	ld	s0,8(sp)
    80006626:	0141                	addi	sp,sp,16
    80006628:	8082                	ret
        case REG_sp: return &tf->sp;
    8000662a:	03050513          	addi	a0,a0,48
    8000662e:	bfdd                	j	80006624 <reg_tf_map+0x22>
        case REG_gp: return &tf->gp;
    80006630:	03850513          	addi	a0,a0,56
    80006634:	bfc5                	j	80006624 <reg_tf_map+0x22>
        case REG_tp: return &tf->tp;
    80006636:	04050513          	addi	a0,a0,64
    8000663a:	b7ed                	j	80006624 <reg_tf_map+0x22>
        case REG_t0: return &tf->t0;
    8000663c:	04850513          	addi	a0,a0,72
    80006640:	b7d5                	j	80006624 <reg_tf_map+0x22>
        case REG_t1: return &tf->t1;
    80006642:	05050513          	addi	a0,a0,80
    80006646:	bff9                	j	80006624 <reg_tf_map+0x22>
        case REG_t2: return &tf->t2;
    80006648:	05850513          	addi	a0,a0,88
    8000664c:	bfe1                	j	80006624 <reg_tf_map+0x22>
        case REG_s0: return &tf->s0;
    8000664e:	06050513          	addi	a0,a0,96
    80006652:	bfc9                	j	80006624 <reg_tf_map+0x22>
        case REG_s1: return &tf->s1;
    80006654:	06850513          	addi	a0,a0,104
    80006658:	b7f1                	j	80006624 <reg_tf_map+0x22>
        case REG_a0: return &tf->a0;
    8000665a:	07050513          	addi	a0,a0,112
    8000665e:	b7d9                	j	80006624 <reg_tf_map+0x22>
        case REG_a1: return &tf->a1;
    80006660:	07850513          	addi	a0,a0,120
    80006664:	b7c1                	j	80006624 <reg_tf_map+0x22>
        case REG_a2: return &tf->a2;
    80006666:	08050513          	addi	a0,a0,128
    8000666a:	bf6d                	j	80006624 <reg_tf_map+0x22>
        case REG_a3: return &tf->a3;
    8000666c:	08850513          	addi	a0,a0,136
    80006670:	bf55                	j	80006624 <reg_tf_map+0x22>
        case REG_a4: return &tf->a4;
    80006672:	09050513          	addi	a0,a0,144
    80006676:	b77d                	j	80006624 <reg_tf_map+0x22>
        case REG_a5: return &tf->a5;
    80006678:	09850513          	addi	a0,a0,152
    8000667c:	b765                	j	80006624 <reg_tf_map+0x22>
        default: return &tf->a5;
    8000667e:	09850513          	addi	a0,a0,152
    80006682:	b74d                	j	80006624 <reg_tf_map+0x22>

0000000080006684 <trap_and_emulate_init>:
void trap_and_emulate_init(void) {
    80006684:	1141                	addi	sp,sp,-16
    80006686:	e422                	sd	s0,8(sp)
    80006688:	0800                	addi	s0,sp,16
    vm_state.ustatus = 0;
    8000668a:	00023797          	auipc	a5,0x23
    8000668e:	37678793          	addi	a5,a5,886 # 80029a00 <vm_state>
    80006692:	0007b023          	sd	zero,0(a5)
    vm_state.uie = 0;
    80006696:	0007b423          	sd	zero,8(a5)
    vm_state.utvec = 0;
    8000669a:	0007b823          	sd	zero,16(a5)
    vm_state.uscratch = 0;
    8000669e:	0007bc23          	sd	zero,24(a5)
    vm_state.uepc = 0;
    800066a2:	0207b023          	sd	zero,32(a5)
    vm_state.ucause = 0;
    800066a6:	0207b423          	sd	zero,40(a5)
    vm_state.utval = 0;
    800066aa:	0207b823          	sd	zero,48(a5)
    vm_state.uip = 0;
    800066ae:	0207bc23          	sd	zero,56(a5)
    vm_state.sstatus = 0;
    800066b2:	0407b023          	sd	zero,64(a5)
    vm_state.sedeleg = 0;
    800066b6:	0407b423          	sd	zero,72(a5)
    vm_state.sideleg = 0;
    800066ba:	0407b823          	sd	zero,80(a5)
    vm_state.sie = 0;
    800066be:	0407bc23          	sd	zero,88(a5)
    vm_state.stvec = 0;
    800066c2:	0607b023          	sd	zero,96(a5)
    vm_state.scounteren = 0;
    800066c6:	0607b423          	sd	zero,104(a5)
    vm_state.sscratch = 0;
    800066ca:	0607b823          	sd	zero,112(a5)
    vm_state.sepc = 0;
    800066ce:	0607bc23          	sd	zero,120(a5)
    vm_state.scause = 0;
    800066d2:	0807b023          	sd	zero,128(a5)
    vm_state.stval = 0;
    800066d6:	0807b423          	sd	zero,136(a5)
    vm_state.sip = 0;
    800066da:	0807b823          	sd	zero,144(a5)
    vm_state.satp = 0;
    800066de:	0807bc23          	sd	zero,152(a5)
    vm_state.mvendorid = 0x637365353336; // cse536
    800066e2:	00002717          	auipc	a4,0x2
    800066e6:	92673703          	ld	a4,-1754(a4) # 80008008 <etext+0x8>
    800066ea:	f3d8                	sd	a4,160(a5)
    vm_state.marchid = 0;
    800066ec:	0a07b423          	sd	zero,168(a5)
    vm_state.mimpid = 0;
    800066f0:	0a07b823          	sd	zero,176(a5)
    vm_state.mhartid = 0;
    800066f4:	0a07bc23          	sd	zero,184(a5)
    vm_state.mstatus = 0;
    800066f8:	0c07b023          	sd	zero,192(a5)
    vm_state.misa = 0;
    800066fc:	0c07b423          	sd	zero,200(a5)
    vm_state.medeleg = 0;
    80006700:	0c07b823          	sd	zero,208(a5)
    vm_state.mideleg = 0;
    80006704:	0c07bc23          	sd	zero,216(a5)
    vm_state.mie = 0;
    80006708:	0e07b023          	sd	zero,224(a5)
    vm_state.mtvec = 0;
    8000670c:	0e07b423          	sd	zero,232(a5)
    vm_state.mcounteren = 0;
    80006710:	0e07b823          	sd	zero,240(a5)
    vm_state.mstatush = 0;
    80006714:	0e07bc23          	sd	zero,248(a5)
    vm_state.mscratch = 0;
    80006718:	1007b023          	sd	zero,256(a5)
    vm_state.mepc = 0;
    8000671c:	1007b423          	sd	zero,264(a5)
    vm_state.mcause = 0;
    80006720:	1007b823          	sd	zero,272(a5)
    vm_state.mtval = 0;
    80006724:	1007bc23          	sd	zero,280(a5)
    vm_state.mip = 0;
    80006728:	1207b023          	sd	zero,288(a5)
    vm_state.mtinst = 0;
    8000672c:	1207b423          	sd	zero,296(a5)
    vm_state.mtval2 = 0;
    80006730:	1207b823          	sd	zero,304(a5)
    vm_state.pmpcfg0 = 0x0;
    80006734:	1207bc23          	sd	zero,312(a5)
    vm_state.pmpaddr0 = 0x80400000;
    80006738:	20100713          	li	a4,513
    8000673c:	075a                	slli	a4,a4,0x16
    8000673e:	14e7b023          	sd	a4,320(a5)
    vm_state.pmpaddr1 = 0;
    80006742:	1407b423          	sd	zero,328(a5)
    vm_state.pmpaddr2 = 0;
    80006746:	1407b823          	sd	zero,336(a5)
    vm_state.pmpaddr3 = 0;
    8000674a:	1407bc23          	sd	zero,344(a5)
    vm_state.pmpaddr4 = 0;
    8000674e:	1607b023          	sd	zero,352(a5)
    vm_state.pmpaddr5 = 0;
    80006752:	1607b423          	sd	zero,360(a5)
    vm_state.pmpaddr6 = 0;
    80006756:	1607b823          	sd	zero,368(a5)
    vm_state.pmpaddr7 = 0;
    8000675a:	1607bc23          	sd	zero,376(a5)
    vm_state.pmpaddr8 = 0;
    8000675e:	1807b023          	sd	zero,384(a5)
    vm_state.pmpaddr9 = 0;
    80006762:	1807b423          	sd	zero,392(a5)
    vm_state.pmpaddr10 = 0;
    80006766:	1807b823          	sd	zero,400(a5)
    vm_state.pmpaddr11 = 0;
    8000676a:	1807bc23          	sd	zero,408(a5)
    vm_state.pmpaddr12 = 0;
    8000676e:	1a07b023          	sd	zero,416(a5)
    vm_state.pmpaddr13 = 0;
    80006772:	1a07b423          	sd	zero,424(a5)
    vm_state.pmpaddr14 = 0;
    80006776:	1a07b823          	sd	zero,432(a5)
    vm_state.pmpaddr15 = 0;
    8000677a:	1a07bc23          	sd	zero,440(a5)
    vm_state.regs.mode = MACHINE_MODE;
    8000677e:	1c07a223          	sw	zero,452(a5)
}
    80006782:	6422                	ld	s0,8(sp)
    80006784:	0141                	addi	sp,sp,16
    80006786:	8082                	ret

0000000080006788 <mvendroid_check>:

// Allowing read operations on mvendroid
int mvendroid_check(uint32 uimm, uint32 funct3) {
    80006788:	87aa                	mv	a5,a0
    
    if (uimm == 0xf11 && funct3 == 2) {
    8000678a:	6705                	lui	a4,0x1
    8000678c:	f1170713          	addi	a4,a4,-239 # f11 <_entry-0x7ffff0ef>
    80006790:	00e50e63          	beq	a0,a4,800067ac <mvendroid_check+0x24>
        printf("Mvendroid is readable in all Modes\n");
        return 1;
    }

    if ((vm_state.regs.mode == USER_MODE && uimm > 0x45) || (vm_state.regs.mode == SUPERVISOR_MODE && uimm > 0x181))
    80006794:	00023717          	auipc	a4,0x23
    80006798:	43072703          	lw	a4,1072(a4) # 80029bc4 <vm_state+0x1c4>
    8000679c:	4689                	li	a3,2
    8000679e:	04d70463          	beq	a4,a3,800067e6 <mvendroid_check+0x5e>
    800067a2:	4685                	li	a3,1
        return 0;
    // if (vm_state.regs.mode == SUPERVISOR_MODE && uimm > 0x182) 
    //     return 0;
    return 1;
    800067a4:	4505                	li	a0,1
    if ((vm_state.regs.mode == USER_MODE && uimm > 0x45) || (vm_state.regs.mode == SUPERVISOR_MODE && uimm > 0x181))
    800067a6:	04d70363          	beq	a4,a3,800067ec <mvendroid_check+0x64>
}
    800067aa:	8082                	ret
    if (uimm == 0xf11 && funct3 == 2) {
    800067ac:	4709                	li	a4,2
    800067ae:	00e58b63          	beq	a1,a4,800067c4 <mvendroid_check+0x3c>
    if ((vm_state.regs.mode == USER_MODE && uimm > 0x45) || (vm_state.regs.mode == SUPERVISOR_MODE && uimm > 0x181))
    800067b2:	00023717          	auipc	a4,0x23
    800067b6:	41272703          	lw	a4,1042(a4) # 80029bc4 <vm_state+0x1c4>
    800067ba:	4689                	li	a3,2
        return 0;
    800067bc:	4501                	li	a0,0
    if ((vm_state.regs.mode == USER_MODE && uimm > 0x45) || (vm_state.regs.mode == SUPERVISOR_MODE && uimm > 0x181))
    800067be:	fed712e3          	bne	a4,a3,800067a2 <mvendroid_check+0x1a>
    800067c2:	8082                	ret
int mvendroid_check(uint32 uimm, uint32 funct3) {
    800067c4:	1141                	addi	sp,sp,-16
    800067c6:	e406                	sd	ra,8(sp)
    800067c8:	e022                	sd	s0,0(sp)
    800067ca:	0800                	addi	s0,sp,16
        printf("Mvendroid is readable in all Modes\n");
    800067cc:	0000a517          	auipc	a0,0xa
    800067d0:	a1c50513          	addi	a0,a0,-1508 # 800101e8 <csr_vm_map+0x78a8>
    800067d4:	ffffa097          	auipc	ra,0xffffa
    800067d8:	db6080e7          	jalr	-586(ra) # 8000058a <printf>
        return 1;
    800067dc:	4505                	li	a0,1
}
    800067de:	60a2                	ld	ra,8(sp)
    800067e0:	6402                	ld	s0,0(sp)
    800067e2:	0141                	addi	sp,sp,16
    800067e4:	8082                	ret
    if ((vm_state.regs.mode == USER_MODE && uimm > 0x45) || (vm_state.regs.mode == SUPERVISOR_MODE && uimm > 0x181))
    800067e6:	04653513          	sltiu	a0,a0,70
    800067ea:	8082                	ret
    800067ec:	1827b513          	sltiu	a0,a5,386
    800067f0:	8082                	ret

00000000800067f2 <trap_and_emulate_ecall>:

/* Redirecting to Guest */
void trap_and_emulate_ecall() {
    800067f2:	1141                	addi	sp,sp,-16
    800067f4:	e406                	sd	ra,8(sp)
    800067f6:	e022                	sd	s0,0(sp)
    800067f8:	0800                	addi	s0,sp,16
    
    printf("(EC at %p)\n", myproc()->trapframe->epc);
    800067fa:	ffffb097          	auipc	ra,0xffffb
    800067fe:	22a080e7          	jalr	554(ra) # 80001a24 <myproc>
    80006802:	6d3c                	ld	a5,88(a0)
    80006804:	6f8c                	ld	a1,24(a5)
    80006806:	0000a517          	auipc	a0,0xa
    8000680a:	a0a50513          	addi	a0,a0,-1526 # 80010210 <csr_vm_map+0x78d0>
    8000680e:	ffffa097          	auipc	ra,0xffffa
    80006812:	d7c080e7          	jalr	-644(ra) # 8000058a <printf>
    
    struct proc *proc = myproc();
    80006816:	ffffb097          	auipc	ra,0xffffb
    8000681a:	20e080e7          	jalr	526(ra) # 80001a24 <myproc>
    vm_state.sepc = proc->trapframe->epc;
    8000681e:	6d3c                	ld	a5,88(a0)
    80006820:	6f98                	ld	a4,24(a5)
    80006822:	00023797          	auipc	a5,0x23
    80006826:	1de78793          	addi	a5,a5,478 # 80029a00 <vm_state>
    8000682a:	ffb8                	sd	a4,120(a5)
    proc->trapframe->epc = vm_state.stvec;
    8000682c:	6d38                	ld	a4,88(a0)
    8000682e:	73b4                	ld	a3,96(a5)
    80006830:	ef14                	sd	a3,24(a4)

    vm_state.regs.mode = SUPERVISOR_MODE;
    80006832:	4705                	li	a4,1
    80006834:	1ce7a223          	sw	a4,452(a5)
    vm_state.sstatus |= SSTATUS_SPP;
    80006838:	63b8                	ld	a4,64(a5)
    8000683a:	10076713          	ori	a4,a4,256
    8000683e:	e3b8                	sd	a4,64(a5)
    // printf("Successfylly redirecting to the guest");
}
    80006840:	60a2                	ld	ra,8(sp)
    80006842:	6402                	ld	s0,0(sp)
    80006844:	0141                	addi	sp,sp,16
    80006846:	8082                	ret

0000000080006848 <my_uvmcopy>:
{
  pte_t *pte;
  uint64 pa, i;
  uint flags;

  for(i = 0; i < sz; i += PGSIZE){
    80006848:	ce49                	beqz	a2,800068e2 <my_uvmcopy+0x9a>
{
    8000684a:	7179                	addi	sp,sp,-48
    8000684c:	f406                	sd	ra,40(sp)
    8000684e:	f022                	sd	s0,32(sp)
    80006850:	ec26                	sd	s1,24(sp)
    80006852:	e84a                	sd	s2,16(sp)
    80006854:	e44e                	sd	s3,8(sp)
    80006856:	e052                	sd	s4,0(sp)
    80006858:	1800                	addi	s0,sp,48
    8000685a:	8a2a                	mv	s4,a0
    8000685c:	89ae                	mv	s3,a1
    8000685e:	8932                	mv	s2,a2
  for(i = 0; i < sz; i += PGSIZE){
    80006860:	4481                	li	s1,0
    if((pte = walk(old, i, 0)) == 0)
    80006862:	4601                	li	a2,0
    80006864:	85a6                	mv	a1,s1
    80006866:	8552                	mv	a0,s4
    80006868:	ffffa097          	auipc	ra,0xffffa
    8000686c:	7c6080e7          	jalr	1990(ra) # 8000102e <walk>
    80006870:	c51d                	beqz	a0,8000689e <my_uvmcopy+0x56>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80006872:	6118                	ld	a4,0(a0)
    80006874:	00177793          	andi	a5,a4,1
    80006878:	cb9d                	beqz	a5,800068ae <my_uvmcopy+0x66>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000687a:	00a75693          	srli	a3,a4,0xa
    flags = PTE_FLAGS(*pte);
    if(mappages(new, i, PGSIZE, pa, flags) != 0){
    8000687e:	3ff77713          	andi	a4,a4,1023
    80006882:	06b2                	slli	a3,a3,0xc
    80006884:	6605                	lui	a2,0x1
    80006886:	85a6                	mv	a1,s1
    80006888:	854e                	mv	a0,s3
    8000688a:	ffffb097          	auipc	ra,0xffffb
    8000688e:	88c080e7          	jalr	-1908(ra) # 80001116 <mappages>
    80006892:	e515                	bnez	a0,800068be <my_uvmcopy+0x76>
  for(i = 0; i < sz; i += PGSIZE){
    80006894:	6785                	lui	a5,0x1
    80006896:	94be                	add	s1,s1,a5
    80006898:	fd24e5e3          	bltu	s1,s2,80006862 <my_uvmcopy+0x1a>
    8000689c:	a81d                	j	800068d2 <my_uvmcopy+0x8a>
      panic("uvmcopy: pte should exist");
    8000689e:	00002517          	auipc	a0,0x2
    800068a2:	8ea50513          	addi	a0,a0,-1814 # 80008188 <digits+0x148>
    800068a6:	ffffa097          	auipc	ra,0xffffa
    800068aa:	c9a080e7          	jalr	-870(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800068ae:	00002517          	auipc	a0,0x2
    800068b2:	8fa50513          	addi	a0,a0,-1798 # 800081a8 <digits+0x168>
    800068b6:	ffffa097          	auipc	ra,0xffffa
    800068ba:	c8a080e7          	jalr	-886(ra) # 80000540 <panic>
  }
  // printf("Uvmcopy success\n");
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800068be:	4685                	li	a3,1
    800068c0:	00c4d613          	srli	a2,s1,0xc
    800068c4:	4581                	li	a1,0
    800068c6:	854e                	mv	a0,s3
    800068c8:	ffffb097          	auipc	ra,0xffffb
    800068cc:	a14080e7          	jalr	-1516(ra) # 800012dc <uvmunmap>
  // printf("Uvmcopy fail\n");
  return -1;
    800068d0:	557d                	li	a0,-1
}
    800068d2:	70a2                	ld	ra,40(sp)
    800068d4:	7402                	ld	s0,32(sp)
    800068d6:	64e2                	ld	s1,24(sp)
    800068d8:	6942                	ld	s2,16(sp)
    800068da:	69a2                	ld	s3,8(sp)
    800068dc:	6a02                	ld	s4,0(sp)
    800068de:	6145                	addi	sp,sp,48
    800068e0:	8082                	ret
  return 0;
    800068e2:	4501                	li	a0,0
}
    800068e4:	8082                	ret

00000000800068e6 <trap_and_emulate>:

void trap_and_emulate(void) {
    800068e6:	711d                	addi	sp,sp,-96
    800068e8:	ec86                	sd	ra,88(sp)
    800068ea:	e8a2                	sd	s0,80(sp)
    800068ec:	e4a6                	sd	s1,72(sp)
    800068ee:	e0ca                	sd	s2,64(sp)
    800068f0:	fc4e                	sd	s3,56(sp)
    800068f2:	f852                	sd	s4,48(sp)
    800068f4:	f456                	sd	s5,40(sp)
    800068f6:	f05a                	sd	s6,32(sp)
    800068f8:	ec5e                	sd	s7,24(sp)
    800068fa:	e862                	sd	s8,16(sp)
    800068fc:	1080                	addi	s0,sp,96

    /* Comes here when a VM tries to execute a supervisor instruction. */
    struct proc *proc = myproc();
    800068fe:	ffffb097          	auipc	ra,0xffffb
    80006902:	126080e7          	jalr	294(ra) # 80001a24 <myproc>
    80006906:	84aa                	mv	s1,a0
    struct trapframe *tf = proc->trapframe;
    80006908:	05853983          	ld	s3,88(a0)
    uint32 ins;

    if (copyin(proc->pagetable, (char *)&ins, tf->epc, sizeof(ins))) {
    8000690c:	4691                	li	a3,4
    8000690e:	0189b603          	ld	a2,24(s3)
    80006912:	fac40593          	addi	a1,s0,-84
    80006916:	6928                	ld	a0,80(a0)
    80006918:	ffffb097          	auipc	ra,0xffffb
    8000691c:	e58080e7          	jalr	-424(ra) # 80001770 <copyin>
    80006920:	e969                	bnez	a0,800069f2 <trap_and_emulate+0x10c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80006922:	14202773          	csrr	a4,scause
        // printf("Error copying instruction into pagetable\n");
        goto killvm;
    }

    // printf("Current instruction : %proc, scause value %d\n", ins, r_scause());
    if (r_scause() == 12 || r_scause() == 13) {
    80006926:	47b1                	li	a5,12
    80006928:	0cf70563          	beq	a4,a5,800069f2 <trap_and_emulate+0x10c>
    8000692c:	14202773          	csrr	a4,scause
    80006930:	47b5                	li	a5,13
    80006932:	0cf70063          	beq	a4,a5,800069f2 <trap_and_emulate+0x10c>
    80006936:	14202773          	csrr	a4,scause
        goto killvm;
    }
    if(r_scause() == 15){
    8000693a:	47bd                	li	a5,15
    8000693c:	0af70363          	beq	a4,a5,800069e2 <trap_and_emulate+0xfc>
    	goto killvm;
    }

    /* Retrieve all required values from the instruction */
    uint64 addr     = tf->epc;
    uint32 op       = ins & 0x7F;
    80006940:	fac42503          	lw	a0,-84(s0)
    80006944:	07f57b93          	andi	s7,a0,127
    uint32 rd       = (ins >> 7) & 0x1F;
    80006948:	00755b1b          	srliw	s6,a0,0x7
    8000694c:	01fb7b13          	andi	s6,s6,31
    uint32 funct3   = (ins >> 12) & 0x7;
    80006950:	00c55a1b          	srliw	s4,a0,0xc
    80006954:	007a7a13          	andi	s4,s4,7
    uint32 rs1      = (ins >> 15) & 0x1F;
    80006958:	00f55a9b          	srliw	s5,a0,0xf
    8000695c:	01fafa93          	andi	s5,s5,31
    uint32 uimm     = (ins >> 20);
    80006960:	01455c1b          	srliw	s8,a0,0x14
    80006964:	0145591b          	srliw	s2,a0,0x14
    
    printf("(PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", addr, op, rd, funct3, rs1, uimm);
    80006968:	884a                	mv	a6,s2
    8000696a:	87d6                	mv	a5,s5
    8000696c:	8752                	mv	a4,s4
    8000696e:	86da                	mv	a3,s6
    80006970:	865e                	mv	a2,s7
    80006972:	0189b583          	ld	a1,24(s3)
    80006976:	0000a517          	auipc	a0,0xa
    8000697a:	8ca50513          	addi	a0,a0,-1846 # 80010240 <csr_vm_map+0x7900>
    8000697e:	ffffa097          	auipc	ra,0xffffa
    80006982:	c0c080e7          	jalr	-1012(ra) # 8000058a <printf>

    if (!mvendroid_check(uimm, funct3)) {
    80006986:	85d2                	mv	a1,s4
    80006988:	854a                	mv	a0,s2
    8000698a:	00000097          	auipc	ra,0x0
    8000698e:	dfe080e7          	jalr	-514(ra) # 80006788 <mvendroid_check>
    80006992:	c125                	beqz	a0,800069f2 <trap_and_emulate+0x10c>
        // printf("Kill because write on mvendroid \n"); 
        goto killvm;
    }
    
    // Handling csrr, csrw, mret & sret
    if (op == 0x73) {
    80006994:	07300793          	li	a5,115
    80006998:	06fb9c63          	bne	s7,a5,80006a10 <trap_and_emulate+0x12a>
        
        // csrw call
        if (funct3 == 1) {
    8000699c:	4785                	li	a5,1
    8000699e:	08fa0563          	beq	s4,a5,80006a28 <trap_and_emulate+0x142>
                goto killvm;
            }
        }

        // csrr call
        else if (funct3 == 2) { 
    800069a2:	4789                	li	a5,2
    800069a4:	0cfa0063          	beq	s4,a5,80006a64 <trap_and_emulate+0x17e>
        }
         
        else {

            // sret call
            if (uimm == 0x102) {
    800069a8:	10200793          	li	a5,258
    800069ac:	0ef90563          	beq	s2,a5,80006a96 <trap_and_emulate+0x1b0>
                vm_state.regs.mode = USER_MODE;
                proc->trapframe->epc = vm_state.sepc;
            }

            // mret call
            else if (uimm == 0x302) {
    800069b0:	30200793          	li	a5,770
    800069b4:	04f91e63          	bne	s2,a5,80006a10 <trap_and_emulate+0x12a>
                if ((vm_state.mstatus & MSTATUS_MPP_MASK) == MSTATUS_MPP_M) {
    800069b8:	00023717          	auipc	a4,0x23
    800069bc:	10873703          	ld	a4,264(a4) # 80029ac0 <vm_state+0xc0>
    800069c0:	6789                	lui	a5,0x2
    800069c2:	80078793          	addi	a5,a5,-2048 # 1800 <_entry-0x7fffe800>
    800069c6:	00f776b3          	and	a3,a4,a5
    800069ca:	02f68463          	beq	a3,a5,800069f2 <trap_and_emulate+0x10c>
                    // printf("Error MSTATUS_MPP_M\n");
                    goto killvm;
                }
                
                // Changing vm state based on previous modes
                if(vm_state.mstatus == MSTATUS_MPP_S){
    800069ce:	80070793          	addi	a5,a4,-2048
    800069d2:	c7e5                	beqz	a5,80006aba <trap_and_emulate+0x1d4>
                    vm_state.regs.mode = SUPERVISOR_MODE;
                }
                else if(vm_state.mstatus == MSTATUS_MPP_U){
    800069d4:	eb65                	bnez	a4,80006ac4 <trap_and_emulate+0x1de>
                    vm_state.regs.mode = USER_MODE;
    800069d6:	4789                	li	a5,2
    800069d8:	00023717          	auipc	a4,0x23
    800069dc:	1ef72623          	sw	a5,492(a4) # 80029bc4 <vm_state+0x1c4>
    800069e0:	a0d5                	j	80006ac4 <trap_and_emulate+0x1de>
    	printf("PMP Region scause Fault \n");
    800069e2:	0000a517          	auipc	a0,0xa
    800069e6:	83e50513          	addi	a0,a0,-1986 # 80010220 <csr_vm_map+0x78e0>
    800069ea:	ffffa097          	auipc	ra,0xffffa
    800069ee:	ba0080e7          	jalr	-1120(ra) # 8000058a <printf>
    // printf("End\n");
    return;
    
killvm:
   // printf("Killing the VM\n");
   if(pmp_flag){
    800069f2:	0000a797          	auipc	a5,0xa
    800069f6:	9967b783          	ld	a5,-1642(a5) # 80010388 <pmp_flag>
    800069fa:	c791                	beqz	a5,80006a06 <trap_and_emulate+0x120>
      proc->pagetable = tpagetable;
    800069fc:	0000a797          	auipc	a5,0xa
    80006a00:	9847b783          	ld	a5,-1660(a5) # 80010380 <tpagetable>
    80006a04:	e8bc                	sd	a5,80(s1)
   }
   setkilled(proc); // Killing the VM ie process
    80006a06:	8526                	mv	a0,s1
    80006a08:	ffffc097          	auipc	ra,0xffffc
    80006a0c:	97a080e7          	jalr	-1670(ra) # 80002382 <setkilled>
}
    80006a10:	60e6                	ld	ra,88(sp)
    80006a12:	6446                	ld	s0,80(sp)
    80006a14:	64a6                	ld	s1,72(sp)
    80006a16:	6906                	ld	s2,64(sp)
    80006a18:	79e2                	ld	s3,56(sp)
    80006a1a:	7a42                	ld	s4,48(sp)
    80006a1c:	7aa2                	ld	s5,40(sp)
    80006a1e:	7b02                	ld	s6,32(sp)
    80006a20:	6be2                	ld	s7,24(sp)
    80006a22:	6c42                	ld	s8,16(sp)
    80006a24:	6125                	addi	sp,sp,96
    80006a26:	8082                	ret
            *csr_vm_map[uimm] = *reg_tf_map(tf, rs1);
    80006a28:	85d6                	mv	a1,s5
    80006a2a:	854e                	mv	a0,s3
    80006a2c:	00000097          	auipc	ra,0x0
    80006a30:	bd6080e7          	jalr	-1066(ra) # 80006602 <reg_tf_map>
    80006a34:	6118                	ld	a4,0(a0)
    80006a36:	1c02                	slli	s8,s8,0x20
    80006a38:	020c5c13          	srli	s8,s8,0x20
    80006a3c:	0c0e                	slli	s8,s8,0x3
    80006a3e:	00002797          	auipc	a5,0x2
    80006a42:	f0278793          	addi	a5,a5,-254 # 80008940 <csr_vm_map>
    80006a46:	97e2                	add	a5,a5,s8
    80006a48:	639c                	ld	a5,0(a5)
    80006a4a:	e398                	sd	a4,0(a5)
            proc->trapframe->epc += 4;
    80006a4c:	6cb8                	ld	a4,88(s1)
    80006a4e:	6f1c                	ld	a5,24(a4)
    80006a50:	0791                	addi	a5,a5,4
    80006a52:	ef1c                	sd	a5,24(a4)
            if(uimm == CSR_mvendorid && *reg_tf_map(tf, rs1) == 0x0){
    80006a54:	6785                	lui	a5,0x1
    80006a56:	f1178793          	addi	a5,a5,-239 # f11 <_entry-0x7ffff0ef>
    80006a5a:	faf91be3          	bne	s2,a5,80006a10 <trap_and_emulate+0x12a>
    80006a5e:	611c                	ld	a5,0(a0)
    80006a60:	fbc5                	bnez	a5,80006a10 <trap_and_emulate+0x12a>
    80006a62:	bf41                	j	800069f2 <trap_and_emulate+0x10c>
            *reg_tf_map(tf, rd) = *csr_vm_map[uimm];
    80006a64:	1c02                	slli	s8,s8,0x20
    80006a66:	020c5c13          	srli	s8,s8,0x20
    80006a6a:	0c0e                	slli	s8,s8,0x3
    80006a6c:	00002797          	auipc	a5,0x2
    80006a70:	ed478793          	addi	a5,a5,-300 # 80008940 <csr_vm_map>
    80006a74:	97e2                	add	a5,a5,s8
    80006a76:	0007b903          	ld	s2,0(a5)
    80006a7a:	85da                	mv	a1,s6
    80006a7c:	854e                	mv	a0,s3
    80006a7e:	00000097          	auipc	ra,0x0
    80006a82:	b84080e7          	jalr	-1148(ra) # 80006602 <reg_tf_map>
    80006a86:	00093783          	ld	a5,0(s2)
    80006a8a:	e11c                	sd	a5,0(a0)
            proc->trapframe->epc += 4;
    80006a8c:	6cb8                	ld	a4,88(s1)
    80006a8e:	6f1c                	ld	a5,24(a4)
    80006a90:	0791                	addi	a5,a5,4
    80006a92:	ef1c                	sd	a5,24(a4)
    80006a94:	bfb5                	j	80006a10 <trap_and_emulate+0x12a>
                if ((vm_state.sstatus & SSTATUS_SPP) != 0) {
    80006a96:	00023797          	auipc	a5,0x23
    80006a9a:	faa7b783          	ld	a5,-86(a5) # 80029a40 <vm_state+0x40>
    80006a9e:	1007f793          	andi	a5,a5,256
    80006aa2:	fba1                	bnez	a5,800069f2 <trap_and_emulate+0x10c>
                vm_state.regs.mode = USER_MODE;
    80006aa4:	00023797          	auipc	a5,0x23
    80006aa8:	f5c78793          	addi	a5,a5,-164 # 80029a00 <vm_state>
    80006aac:	4709                	li	a4,2
    80006aae:	1ce7a223          	sw	a4,452(a5)
                proc->trapframe->epc = vm_state.sepc;
    80006ab2:	6cb8                	ld	a4,88(s1)
    80006ab4:	7fbc                	ld	a5,120(a5)
    80006ab6:	ef1c                	sd	a5,24(a4)
    80006ab8:	bfa1                	j	80006a10 <trap_and_emulate+0x12a>
                    vm_state.regs.mode = SUPERVISOR_MODE;
    80006aba:	4785                	li	a5,1
    80006abc:	00023717          	auipc	a4,0x23
    80006ac0:	10f72423          	sw	a5,264(a4) # 80029bc4 <vm_state+0x1c4>
                proc->trapframe->epc = vm_state.mepc;
    80006ac4:	6cb8                	ld	a4,88(s1)
    80006ac6:	00023797          	auipc	a5,0x23
    80006aca:	f3a78793          	addi	a5,a5,-198 # 80029a00 <vm_state>
    80006ace:	1087b683          	ld	a3,264(a5)
    80006ad2:	ef14                	sd	a3,24(a4)
                if (vm_state.pmpcfg0 != 0 && pmp_region > 0) { 
    80006ad4:	1387b783          	ld	a5,312(a5)
    80006ad8:	df85                	beqz	a5,80006a10 <trap_and_emulate+0x12a>
                int pmp_region = (0x80400000 - (vm_state.pmpaddr0<<2));
    80006ada:	00023797          	auipc	a5,0x23
    80006ade:	0667b783          	ld	a5,102(a5) # 80029b40 <vm_state+0x140>
    80006ae2:	0027979b          	slliw	a5,a5,0x2
    80006ae6:	80400937          	lui	s2,0x80400
    80006aea:	40f9093b          	subw	s2,s2,a5
    80006aee:	0009071b          	sext.w	a4,s2
                if (vm_state.pmpcfg0 != 0 && pmp_region > 0) { 
    80006af2:	6785                	lui	a5,0x1
    80006af4:	f0f74ee3          	blt	a4,a5,80006a10 <trap_and_emulate+0x12a>
                    pagetable_pmp = proc_pagetable(proc);
    80006af8:	8526                	mv	a0,s1
    80006afa:	ffffb097          	auipc	ra,0xffffb
    80006afe:	fee080e7          	jalr	-18(ra) # 80001ae8 <proc_pagetable>
    80006b02:	0000a717          	auipc	a4,0xa
    80006b06:	86a73b23          	sd	a0,-1930(a4) # 80010378 <pagetable_pmp.0>
                    pmp_flag = 1; // Flag to know it PMP is ever executed
    80006b0a:	4585                	li	a1,1
    80006b0c:	0000a797          	auipc	a5,0xa
    80006b10:	86b7be23          	sd	a1,-1924(a5) # 80010388 <pmp_flag>
                    if((sz1 = uvmalloc(pagetable_pmp, addr, addr + 1024*PGSIZE, PTE_W)) == 0) {
    80006b14:	4691                	li	a3,4
    80006b16:	20100613          	li	a2,513
    80006b1a:	065a                	slli	a2,a2,0x16
    80006b1c:	05fe                	slli	a1,a1,0x1f
    80006b1e:	ffffb097          	auipc	ra,0xffffb
    80006b22:	96a080e7          	jalr	-1686(ra) # 80001488 <uvmalloc>
    80006b26:	0005079b          	sext.w	a5,a0
    80006b2a:	c3bd                	beqz	a5,80006b90 <trap_and_emulate+0x2aa>
                    if(my_uvmcopy(proc->pagetable, pagetable_pmp, proc->sz) < 0) {
    80006b2c:	64b0                	ld	a2,72(s1)
    80006b2e:	0000a597          	auipc	a1,0xa
    80006b32:	84a5b583          	ld	a1,-1974(a1) # 80010378 <pagetable_pmp.0>
    80006b36:	68a8                	ld	a0,80(s1)
    80006b38:	00000097          	auipc	ra,0x0
    80006b3c:	d10080e7          	jalr	-752(ra) # 80006848 <my_uvmcopy>
    80006b40:	06054163          	bltz	a0,80006ba2 <trap_and_emulate+0x2bc>
                pmp_region = pmp_region / PGSIZE;
    80006b44:	6785                	lui	a5,0x1
    80006b46:	02f9493b          	divw	s2,s2,a5
                        uvmunmap(pagetable_pmp, vm_state.pmpaddr0<<2, pmp_region, 0);
    80006b4a:	0000a997          	auipc	s3,0xa
    80006b4e:	82e98993          	addi	s3,s3,-2002 # 80010378 <pagetable_pmp.0>
    80006b52:	4681                	li	a3,0
    80006b54:	864a                	mv	a2,s2
    80006b56:	00023597          	auipc	a1,0x23
    80006b5a:	fea5b583          	ld	a1,-22(a1) # 80029b40 <vm_state+0x140>
    80006b5e:	058a                	slli	a1,a1,0x2
    80006b60:	0009b503          	ld	a0,0(s3)
    80006b64:	ffffa097          	auipc	ra,0xffffa
    80006b68:	778080e7          	jalr	1912(ra) # 800012dc <uvmunmap>
                        tpagetable = proc->pagetable;
    80006b6c:	68bc                	ld	a5,80(s1)
    80006b6e:	0000a717          	auipc	a4,0xa
    80006b72:	80f73923          	sd	a5,-2030(a4) # 80010380 <tpagetable>
                        proc->pagetable = pagetable_pmp;  
    80006b76:	0009b783          	ld	a5,0(s3)
    80006b7a:	e8bc                	sd	a5,80(s1)
                        printf("Pages unmapped are %d\n", pmp_region);
    80006b7c:	85ca                	mv	a1,s2
    80006b7e:	00009517          	auipc	a0,0x9
    80006b82:	75250513          	addi	a0,a0,1874 # 800102d0 <csr_vm_map+0x7990>
    80006b86:	ffffa097          	auipc	ra,0xffffa
    80006b8a:	a04080e7          	jalr	-1532(ra) # 8000058a <printf>
    80006b8e:	b549                	j	80006a10 <trap_and_emulate+0x12a>
                        printf("Failed to allocate memory for PMP\n");
    80006b90:	00009517          	auipc	a0,0x9
    80006b94:	6f050513          	addi	a0,a0,1776 # 80010280 <csr_vm_map+0x7940>
    80006b98:	ffffa097          	auipc	ra,0xffffa
    80006b9c:	9f2080e7          	jalr	-1550(ra) # 8000058a <printf>
    80006ba0:	b771                	j	80006b2c <trap_and_emulate+0x246>
                        printf("Error in copying the page tables\n");
    80006ba2:	00009517          	auipc	a0,0x9
    80006ba6:	70650513          	addi	a0,a0,1798 # 800102a8 <csr_vm_map+0x7968>
    80006baa:	ffffa097          	auipc	ra,0xffffa
    80006bae:	9e0080e7          	jalr	-1568(ra) # 8000058a <printf>
    80006bb2:	bdb9                	j	80006a10 <trap_and_emulate+0x12a>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
