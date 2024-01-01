/* CSE 536: User-Level Threading Library */
#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/fcntl.h"
#include "user/user.h"
#include "user/ulthread.h"
#include "kernel/riscv.h"

/* Standard definitions */
#include <stdbool.h>
#include <stddef.h> 

static struct ulthread_list thread_list;
extern void ulthread_schedule(void);

/* Get thread ID*/
int get_current_tid() {
    return thread_list.current;
}

/* Thread initialization */
void ulthread_init(int schedalgo) {

    struct ulthread *scheduler_thread = &thread_list.threads[0];
    scheduler_thread->tid = 0;
    scheduler_thread->start_func = (uint64)ulthread_schedule;
    scheduler_thread->context.sp = scheduler_thread->stack + PGSIZE;
    scheduler_thread->context.ra = (uint64)ulthread_schedule;
    
    thread_list.total = 1;
    thread_list.current = 0;
    thread_list.algo = schedalgo;
}

/* Thread creation */
bool ulthread_create(uint64 start, uint64 stack, uint64 args[], int priority) {
    
    int free_tid = FindFree_Thread(); // Finding a free thread
    if (free_tid == -1) {
       // printf("Found no Free Threads \n"));
        return false;
    }

    printf("[*] ultcreate(tid: %d, ra: %p, sp: %p)\n",free_tid, start, stack);
    struct ulthread *free_thread = &thread_list.threads[free_tid];
    
    free_thread->tid = free_tid;
    free_thread->current_state = RUNNABLE;
    free_thread->stack = stack;
    free_thread->start_func = start;
    free_thread->priority = priority;
    free_thread->creation_time = ctime();
    
    free_thread->context.sp = stack;
    free_thread->context.ra = start;
    free_thread->context.a0 = args[0];
    free_thread->context.a1 = args[1];
    free_thread->context.a2 = args[2];
    free_thread->context.a3 = args[3];
    free_thread->context.a4 = args[4];
    free_thread->context.a5 = args[5];
    
    thread_list.total++;
    
    return true;
}

/* Thread scheduler */
void ulthread_schedule(void) {
    
    struct ulthread *scheduler_thread = &thread_list.threads[0];
    
    while (true){
        int next_tid = 0;    
        switch(thread_list.algo) {
		    
	    case ROUNDROBIN:
	         next_tid = RoundRobin_Scheduling();
	         break;
	    case PRIORITY:
	         next_tid = Priority_Scheduling();
	         break;
	    default:
	        next_tid = FCFS_Scheduling();
	}
		
        if (next_tid == 0){
            if (thread_list.threads[thread_list.yield_tid].current_state == YIELD) {
                next_tid = thread_list.yield_tid;
            }
            else{
                return;
            }
        }
	
	// Making the thread that YIELDED runnable
        if (thread_list.threads[thread_list.yield_tid].current_state == YIELD) {
            thread_list.threads[thread_list.yield_tid].current_state = RUNNABLE;
        }

        /* Add this statement to denote which thread-id is being scheduled next */
        printf("[*] ultschedule (next tid: %d)\n", next_tid);
        struct ulthread *next_thread = &thread_list.threads[next_tid];
        thread_list.current = next_tid;
        
        // Save and Load thread contexts
        ulthread_context_switch(&scheduler_thread->context, &next_thread->context);
    }
}

/* Get Next Free Thread ID */
int FindFree_Thread(void) {
    
    int free_thread_id = -1;
    for (int i=1; i<MAXULTHREADS; i++) {
        if(thread_list.threads[i].current_state == FREE)
            return i;
    }
    
    return -1;
}

/* Scheduling Algorithms */

int RoundRobin_Scheduling(void) {
    
    int itr = thread_list.current + 1;
    int counter = 0;
    
    while (counter < MAXULTHREADS) {
        if (itr != 0 && thread_list.threads[itr].current_state == RUNNABLE){
            return itr;
        }
        itr = (itr + 1) % MAXULTHREADS;  // Bouding the itr value
        counter++;
    }
    
    return 0;
}

int Priority_Scheduling(void) {
    
    int priority_thread = 0;
    int highest_priority = -1;
    
    for (int i = 1; i < MAXULTHREADS; i++) {
    
        if (thread_list.threads[i].current_state == RUNNABLE) {
            if (thread_list.threads[i].priority > highest_priority) {
 
                priority_thread = i;
                highest_priority = thread_list.threads[i].priority;
            }
        }
    }
    return priority_thread;
}

int FCFS_Scheduling(void) {
    
    int fcfs_thread = 0;
    int current_time = ctime();
    
    for (int i = 1; i < MAXULTHREADS; i++) {
        if (thread_list.threads[i].current_state == RUNNABLE) {
            
            if (thread_list.threads[i].creation_time < current_time) {
                fcfs_thread = i;
                current_time = thread_list.threads[i].creation_time;
            }
        }
    }
    
    return fcfs_thread;
}


/* Yield CPU time to some other thread. */
void ulthread_yield(void) {
    
    printf("[*] ultyield(tid: %d)\n", thread_list.current);
    struct ulthread *current_thread = &thread_list.threads[thread_list.current];
    current_thread->current_state = YIELD;
    thread_list.yield_tid = thread_list.current;
    
    struct ulthread *scheduler_thread = &thread_list.threads[0];
    ulthread_context_switch(&current_thread->context, &scheduler_thread->context);
}

/* Destroy thread */
void ulthread_destroy(void) {
    
    printf("[*] ultdestroy(tid: %d)\n", thread_list.current);
    struct ulthread *current_thread = &thread_list.threads[thread_list.current];
    current_thread->current_state = FREE;
    
    thread_list.total--;
    struct ulthread *scheduler_thread = &thread_list.threads[0];
    ulthread_context_switch(&current_thread->context, &scheduler_thread->context);
}
