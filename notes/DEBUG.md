## Notes on debugging

### Useful debug configs

This list comes from the webinar [Dynamic Program Analysis for Fun and Profit](https://events.linuxfoundation.org/mentorship-session-dynamic-program-analysis/) by Dmitry Vyukov.

- DEBUG_LIST
- DEBUG_PLIST
- FORTIFY_SOURCE
- DEBUG_KOBJECT
- SCHED_STACK_END_CHECK
- HARDENED_USERCOPY
- HARDENED_USERCOPY_FALLBACK
- LOCKUP_DETECTOR
- SOFTLOCKUP_DETECTOR
- DETECT_HUNG_TASK
- WQ_WATCHDOG
- HARDLOCKUP_DETECTOR
- DEBUG_SG
- LOCKDEP
- PROVE_LOCKING
- DEBUG_ATOMIC_SLEEP
- PROVE_RCU
- RCU_EQS_DEBUG
- DEBUG_LOCK_ALLOC
- DEBUG_RT_MUTEXES
- DEBUG_SPINLOCK
- DEBUG_MUTEXES
- DEBUG_WW_MUTEX_SLOWPATH
- DEBUG_RWSEMS
- SND_DEBUG
- SND_PCM_XRUN_DEBUG
- DEBUG_OBJECTS
- DEBUG_OBJECTS_ENABLE_DEFAULT
- DEBUG_OBJECTS_FREE
- DEBUG_OBJECTS_PERCPU_COUNTER
- DEBUG_OBJECTS_RCU_HEAD
- DEBUG_OBJECTS_TIMERS
- DEBUG_OBJECTS_WORK
- DEBUG_PREEMPT
- DEBUG_DEVRES
- DEBUG_NOTIFIERS
- DEBUG_CREDENTIALS
- UBSAN_BOUNDS
- UBSAN_SHIFT
- DEBUG_VM
- DEBUG_VM_RB
- DEBUG_VM_VMACACHE
- DEBUG_VM_PGFLAGS
- DEBUG_VM_PGTABLE
- DEBUG_VIRTUAL
- DEBUG_KMAP_LOCAL_FORCE_MAP
- DEBUG_MEMORY_INIT
- PAGE_POISONING
- RING_BUFFER_VALIDATE_TIME_DELTAS
- DYNAMIC_DEBUG
- SND_CTL_VALIDATION
- DEBUG_PER_CPU_MAPS
- DEBUG_KMEMLEAK
- FAULT_INJECTION
- FAILSLAB
- FAIL_PAGE_ALLOC
- FAIL_MAKE_REQUEST
- FAIL_IO_TIMEOUT
- FAIL_FUTEX
- FAULT_INJECTION_DEBUG_FS
- FAULT_INJECTION_USERCOPY
- DEBUG_INFO
- DEBUG_BUGVERBOSE
- PRINTK_CALLER
- PANIC_ON_OOPS
- BUG_ON_DATA_CORRUPTION
- BOOTPARAM_HARDLOCKUP_PANIC
- BOOTPARAM_HUNG_TASK_PANIC
- BOOTPARAM_SOFTLOCKUP_PANIC
- panic_on_warn (command line)