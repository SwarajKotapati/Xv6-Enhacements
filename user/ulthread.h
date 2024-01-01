#ifndef __UTHREAD_H__
#define __UTHREAD_H__
#include <stdbool.h>
#define MAXULTHREADS 100

enum ulthread_state {
  FREE,
  RUNNABLE,
  YIELD,
};

enum Scheduling_algorithm {
  ROUNDROBIN,   
  PRIORITY,     
  FCFS,      
};

struct ulthread_context {
  uint64 ra;
  uint64 sp;
  
  uint64 s0;
  uint64 s1;
  uint64 s2;
  uint64 s3;
  uint64 s4;
  uint64 s5;
  uint64 s6;
  uint64 s7;
  uint64 s8;
  uint64 s9;
  uint64 s10;
  uint64 s11;
  
  uint64 a0;
  uint64 a1;
  uint64 a2;
  uint64 a3;
  uint64 a4;
  uint64 a5;
};

struct ulthread {
  
  int tid;            
  char name[16];               
  int priority;                
  int creation_time;   
  uint64 *start_func;   
  uint64 *stack;                 
  enum ulthread_state current_state;   
  struct ulthread_context context; 
               
};

struct ulthread_list {

  int total;                  
  int current;                
  int yield_tid;              
  struct ulthread threads[MAXULTHREADS]; 
  enum Scheduling_algorithm algo; 
  
};

#endif
