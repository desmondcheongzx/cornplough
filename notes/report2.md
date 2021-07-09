# Second evaluation report
## Accepted patches
d98e4d95411bbde2220a7afa38dcc9c14d71acbe ntfs: fix validity check for file name attribute

__(Reverted)__ 1815d9c86e3090477fbde066ff314a7e9721ee0f drm: add a locked version of drm_is\_current\_master

c336a5ee984708db4826ef9e47d184e638e29717 drm: Lock pointer access in drm_master_release()

b436acd1cf7fac0ba987abd22955d98025c80c2b drm: Fix use-after-free read in drm_getunique()

0c21b72a7f1983346fcb47eec2e0dd7fa0ad4391 Staging: rtl8723bs: remove dead code in HalBtc8723b1Ant.c

f7d21f444a41e1d2998fe18f940d74395a441ee1 Staging: rtl8723bs: fix line continuations in HalBtc8723b1Ant.c

557c2325364afb57c447ee144a661c9fda47798b Staging: rtl8723bs: add missing blank line in HalBtc8723b1Ant.c

aa62018944a86af6eb51b57aa9593370d604ca3b Staging: rtl8723bs: fix comparison formatting in HalBtc8723b1Ant.c

3750ae9e79b601b47920ca642de96bef96a45388 Staging: rtl8723bs: fix indentation in HalBtc8723b1Ant.c

426ddc5298771dd3fc2298508ed132ae2b180ee2 Staging: rtl8723bs: fix spaces in HalBtc8723b1Ant.c

83e9f677a4efee5200ae3deec0a1f582851173d2 Staging: rtl8723bs: remove unnecessary braces in HalBtc8723b1Ant.c

7240cd200541543008a7ce4fcaf2ba5a5556128f Remove link to nonexistent rocket driver docs

## Patches waiting for merge
[PATCH 1/2] fcntl: fix potential deadlocks for &fown\_struct.lock
https://lore.kernel.org/lkml/20210702091831.615042-2-desmondcheongzx@gmail.com/

[PATCH 2/2] fcntl: fix potential deadlock for &fasync\_struct.fa\_lock
https://lore.kernel.org/lkml/20210702091831.615042-3-desmondcheongzx@gmail.com/

[PATCH v2] mtd: break circular locks in register\_mtd\_blktrans
https://lore.kernel.org/lkml/20210617160904.570111-1-desmondcheongzx@gmail.com/

## Patches undergoing review
[PATCH v2 1/3] hfs: add missing clean-up in hfs\_fill\_super
https://lore.kernel.org/lkml/20210701030756.58760-2-desmondcheongzx@gmail.com/

[PATCH v2 2/3] hfs: fix high memory mapping in hfs\_bnode\_read
https://lore.kernel.org/lkml/20210701030756.58760-3-desmondcheongzx@gmail.com/

[PATCH v2 3/3] hfs: add lock nesting notation to hfs\_find\_init
https://lore.kernel.org/lkml/20210701030756.58760-4-desmondcheongzx@gmail.com/

[PATCH] Bluetooth: fix inconsistent lock state in sco
https://lore.kernel.org/lkml/20210628074834.161640-1-desmondcheongzx@gmail.com/

(to be updated in v8) [PATCH v7 1/5] drm: avoid circular locks in drm_mode\_getconnector
https://lore.kernel.org/lkml/20210701165358.19053-2-desmondcheongzx@gmail.com/

(to be updated in v8) [PATCH v7 3/5] drm: add a locked version of drm\_is\_current_master
https://lore.kernel.org/lkml/20210701165358.19053-4-desmondcheongzx@gmail.com/

(to be updated in v8) [PATCH v7 4/5] drm: serialize drm_file.master with a master lock
https://lore.kernel.org/lkml/20210701165358.19053-5-desmondcheongzx@gmail.com/

(to be updated in v8) [PATCH v7 5/5] drm: protect drm_master pointers in drm_lease.c
https://lore.kernel.org/lkml/20210701165358.19053-6-desmondcheongzx@gmail.com/

## Bug analyses

### Bugs in hfs
Link to Syzbot report: https://syzkaller.appspot.com/bug?id=f007ef1d7a31a469e3be7aeb0fde0769b18585db

Syzbot reported a possible deadlock in hfs. From my initial investigation, it indeed seemed that the same lock was being called recursively in the code. However, this also seemed intentional. Printing the Catalog Node IDs (CNID) of the trees involved in the recursive locks, I discovered that the recursive locks always involved different CNIDs.

At this point I was stumped and went to read up about the design of the Hierarchical File System, as well as lock nesting notation. Then, coming back to the bug, I understood that the order of locking involved was from catalog btree -> extents btree, and since this is done intentionally, the appropriate fix was to add lock nesting notation. At this point, I also discovered that there was a HFS+ filesystem in the kernel that had already addressed this problem, so I adapted it for HFS.

#### Follow-up
While investigating this bug, I noticed that there was a missing clean-up call on an error path in hfs\_fill\_super (I had initially thought this was the cause of the bug). I added the clean-up code in a separate patch in the series.

Also, after applying my proposed patch, running the Syzkaller repro test resulted in an invalid memory access error. Reading the relevant code, it was clear that high memory was being mapped improperly into kernel address space. So I fixed the logic of hfs\_bnode\_read in another patch.

### Inconsistent lock state in sco
Link to Syzbot report: https://syzkaller.appspot.com/bug?id=9089d89de0502e120f234ca0fc8a703f7368b31e

Syzbot reported an inconsistent {SOFTIRQ-ON-W} -> {IN-SOFTIRQ-W} lock usage in sco_conn_del and sco_sock_timeout that could lead to deadlocks. After reading up about SOFTIRQ lock safety and bottom halves, it seemed that the issue was a result of interrupts not being disabled when locking slock-AF_BLUETOOTH-BTPROTO_SCO, because slock-AF_BLUETOOTH-BTPROTO_SCO can also be grabbed during a software interrupt.

This initially confused me because the locks were grabbed using bh_lock_sock, which should disable software interrupts. But upon investigation, I learned that bh_lock_sock simply calls spin_lock. I considered altering the code for bh_lock_sock, however since this lock was used throughout the codebase, and my fix might inadvertently break something, I decided to simply change the calls from bh_lock_sock to spin_lock_bh.

However, after making this change, a new lock hierarchy was inverted. To avoid this, I pulled the clean-up code that inverted the lock hierarchy out of the protected section.

#### Follow-up
I haven't gotten feedback on this patch, probably because everyone's busy during the merge window. However, after studying more about lockdep for another bug, I'm half-convinced that my original solution to pull out the clean-up code to avoid inverting the lock hierarchy was the wrong decision. So I may be revising this patch in the coming week.

### Deadlocks in fcntl
Link to one of the Syzbot reports: https://syzkaller.appspot.com/bug?id=923cfc6c6348963f99886a0176ef11dcc429547b

There are a number of Syzbot bugs related to the file locking subsystem. The issues all stem from an irq lock inversion dependency. This bug became possible to tackle only after studying the design of lockdep. In particular, understanding what was meant by HARDIRQ/SOFTIRQ-safe/unsafe. Once I understood this, the bugs in do\_fcntl were clearly the result of not disabling interrupts for locks that are dependent on another lock that's taken during interrupts. Fixing this bug then became a matter of using the appropriate irq/irqsave locks.

### Deadlocks in mm/page_alloc
Link to one of the Syzbot reports: https://syzkaller.appspot.com/bug?id=b7f57a105abec9e5033221954c5ae7f9147d0627

In early July, a slew of circular lock dependencies were reported by Syzbot. On closer inspection, I discovered that they all involved the same &pagesets.lock in mm/page\_alloc. &pagesets.lock was observed in each lockdep splat, and this lock seemed to be used as both an inner and outer lock. Additionally, the lockdep splats all seemed to involve a call to local_lock_irqsave(&pagesets.lock, flags) inside \_\_alloc\_pages\_bulk. Writing out the call traces, it became obvious that &pagesets.lock becomes an outer lock if it's held during the call to prep\_new\_page in \_\_alloc\_pages\_bulk.

My main debugging tool this time was `git blame`, because I needed to understand the use of &pagesets.lock so that I could disentangle it. The lock was introduced in commit dbbee9d5cd83 ("mm/page_alloc: convert per-cpu list protection to local\_lock"), and it was clear from the commit message that the local lock is used to protect the per-cpu pageset structure. Using this information, I adjusted the locking in \_\_alloc\_pages\_bulk so that only the necessary structures are protected, and submitted a patch accordingly: https://lore.kernel.org/lkml/20210707111245.625374-1-desmondcheongzx@gmail.com/

#### Outcome
After submitting my patch, Mel Gorman pointed out that it imposed a performance penalty on the batch allocator, and proposed a different patch that would also avoid the recursive call that makes &pagesets.lock an outer lock. I tested this alternative patch on Syzbot and it passed.

In this case, the patch I proposed wasn't accepted, but it was a good lesson to consider the performance impact of my patches, and not just their correctness. But it was also educating to see how someone more experienced used my analysis to propose a better fix. And at the end of the day, my investigation helped improve the kernel, and that's what matters.

### Use-after-free bugs in DRM
Following a previous bug fix, Daniel Vetter identified some areas in the DRM subsystem that needed auditing. On closer inspection, we concluded that there were potential use-after-free bugs that could result from concurrent calls to DRM SETMASTER ioctl. Although the cause has been identified, we're still working on a solution to avoid inverting various lock hierarchies with DRM device's master mutex.

Additionally, there may be additional time-of-check-to-time-of-use bugs involving DRM DROPMASTER ioctl and DRM REVOKE_LEASE ioctl that we are currently investigating.

## Summary
I'm surprised at how quickly three weeks go by. Now that I've worked with more bugs and subsystems, I feel like my research and investigation skills have improved, and I've gotten better at studying the codebase.

It's still daunting sometimes to see a bug report or a mechanism that I don't understand, and sometimes there's the doubt that comes with spending days on a bug and not knowing if I'm spending my time well. But time and again, the time I put aside to dig deep into a mechanism or subsystem (for example, reading about lockdep and the different flavors of locks, or reading about the RCU mechanism) often "unlocks" bugs and makes it possible for me to tackle them. The knowledge I gain also carries over to other bugs and subsystems. It may be frustrating, but I think that as a new kernel developer, it's unavoidable to have to invest in studying at the start, so that I can be a productive developer in the future.
