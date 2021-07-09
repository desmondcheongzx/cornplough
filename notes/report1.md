# First evaluation report
## Accepted patches
c336a5ee984708db4826ef9e47d184e638e29717 drm: Lock pointer access in drm_master_release()

b436acd1cf7fac0ba987abd22955d98025c80c2b drm: Fix use-after-free read in drm_getunique()

7240cd200541543008a7ce4fcaf2ba5a5556128f Remove link to nonexistent rocket driver docs

## Patches undergoing review
[PATCH v2 1/2] drm: Add a locked version of drm_is_current_master
https://lore.kernel.org/lkml/20210615023645.6535-2-desmondcheongzx@gmail.com/

[PATCH v2 2/2] drm: Protect drm_master pointers in drm_lease.c
https://lore.kernel.org/lkml/20210615023645.6535-3-desmondcheongzx@gmail.com/

[PATCH] ntfs: Fix validity check for file name attribute
https://lore.kernel.org/lkml/20210614050540.289494-1-desmondcheongzx@gmail.com/

[PATCH v2] mtd: break circular locks in register_mtd_blktrans
https://lore.kernel.org/lkml/20210617160904.570111-1-desmondcheongzx@gmail.com/

## Bugs reviewed, but no patch produced

### KASAN: use-after-free Read in bcm_rx_handler
Link to Syzbot report: https://syzkaller.appspot.com/bug?id=93543616b7ac6b9ae258aa04cfe9ff814e7d578d

This was actually the first bug I looked at and reproduced. However, I was hitting a road block with the repro script, and decided to work on a different bug.

The issue was that I tried to remove seemingly unnecessary function calls like `clock_gettime(0x0, 0x0)`. However, because it was a race condition involving three different processes, removing any line of the repro meant that the bug wouldn't trigger. Due to the nature of this repro script, and my skill level at the time, I decided to tackle other bugs because my patch might have a false positive pass on the repro test.

### KASAN: use-after-free Read in snd_seq_timer_interrupt (2)
Link to Syzbot report: https://syzkaller.appspot.com/bug?id=f381deedf1e8d44b545a5ab112c1747f75fb57d6

I spent quite awhile on this bug, convinced that there was a race happening with one process freeing a timer instance and setting flags accordingly, and another process accessing the timer instance concurrently. I added additional spin locks and flag checks to fix this bug, but to no avail.

Then, Takashi Iwai committed a fix for this bug, which was completely different from the solution I had in mind. The issue was that there could be concurrent assignments of timer instances. An overwritten timer instance would not be able to be freed, and can continue running after its associated queue gets closed.

From this, I learned that the true root cause of a problem might not be where I expect it to be. And I should improve my mental model of the subsystem that I'm working with in order to determine the root cause of a bug.

I also learned that there's a lot to be learned from reading other peoples' bug fixes to see how they approached the problem.

## Bug analysis

### KASAN: use-after-free Read in drm_getunique
Link to Syzbot report: https://syzkaller.appspot.com/bug?id=148d2f1dfac64af52ffd27b661981a540724f803

I first reproduced this bug on the latest kernel with Qemu. Then, I translated the crash report with `scripts/decode_stacktrace.sh`. The decoded log showed me that the error occurred at in `drm_getunique` at `drivers/gpu/drm/drm_ioctl.c:124`:

```
	if (u->unique_len >= master->unique_len) {
```

Since the buggy memory was allocated in `drm_master_create` at `drivers/gpu/drm/drm_auth.c:108`:

```
	master = kzalloc(sizeof(*master), GFP_KERNEL);
```

I concluded that the `master` pointer was being freed then dereferenced. 

Following the stacktrace that freed the pointer, I inspected `drm_new_set_master` and `drm_setmaster_ioctl`. However, at this point I felt uncomfortable going further and realized I couldn't make sense of the code. So I went on a detour to read up about the DRM subsystem. The [Linux GPU Driver Developer’s Guide section on DRM Internals](https://www.kernel.org/doc/html/latest/gpu/drm-internals.html) was particularly helpful for this.

Once I better understood the DRM internals, I dove back in and noticed that for `drm_new_set_master` to free the `master` pointer, it first had to hold the appropriate lock due to a lockdep check.

`drm_setmaster_ioctl`, which calls `drm_new_set_master` and eventually frees our pointer, acquires this mutex. However, the mutex is also acquired at the start of `drm_getunique`. This led me to think that perhaps the structure that the mutex protects (i.e. `file_priv->master`) wasn't actually being protected.

True enough, above the mutex lock in `drm_getunique`, we read the value of `file_priv->master`. However, this value can be overwritten and freed in `drm_new_set_master` and so has to be protected.

From there, I made the patch to get the value of `file_priv->master` only after acquiring the mutex. Since this meant that I had to change references from `&master->dev->master_mutex` to `&dev->master_mutex`, I also included a `BUG_ON(dev != master->dev)` assertion during my tests to ensure that they were the same pointer. Then, I cleaned up the patch and tested it on Syzbot. After passing the Syzbot repro test as well, I submitted my patch to the appropriate maintainers.

Shortly after, my first bug-fix was accepted into the kernel :)

#### Follow up 1

In the syzkaller-bugs google group, Dan Carpenter replied to my patch test because his Smatch check found a similar warning in drm_master_release(). Although there was no corresponding Syzbot error, the warning belonged to the same class of bugs, so I prepared another patch and included Dan in a Suggested-by: tag.

I also went to watch the LF mentorship webinar on Smatch (https://events.linuxfoundation.org/mentorship-session-smatch/) to understand Smatch better.

Link to conversation: https://groups.google.com/g/syzkaller-bugs/c/kZM-uxltyUc

#### Follow up 2

After these two patches, Daniel Vetter carried out an audit of the relevant code, and noticed potential errors in drm_auth.c and drm_lease.c that are related to this bug. Discussions are currently ongoing to fix these bugs.

### KASAN: use-after-free Read in ntfs_iget (2)
Link to Syzbot report: https://syzkaller.appspot.com/bug?id=a1a1e379b225812688566745c3e2f7242bffc246

After my experience struggling with a bug before someone else fixed it, I decided to spend more time reading documentation and logs to build more context around a problem. This turned out to be very fruitful, because I found that a similar ntfs bug had been fixed. Reading the email thread for the patch (https://lore.kernel.org/lkml/20210217155930.1506815-1-rkovhaev@gmail.com/) I gained a better understanding of the ntfs subsystem, and realized that the method to fix the related bug directly applied to this bug. So I wrote up a patch, tested it, and sent it for review: https://lore.kernel.org/lkml/20210614050540.289494-1-desmondcheongzx@gmail.com/

### possible deadlock in loop_probe
Link to Syzbot report: https://syzkaller.appspot.com/bug?id=7bd106c28e846d1023d4ca915718b1a0905444cb

I had a false start with this bug, because I identified a circular lock dependency that was different from the one in the crash report, but which I thought was the true root cause of the problem. However, my fix only seemed to make the problem worse.

I then went through the four lock dependencies in the crash log to understand where and why they happened. After closer analysis, it seemed to me that 3/4 of them could not be broken. So I sent in a patch to break the last dependency. However, Christoph Hellwig quickly corrected me by pointing out why this patch would introduce more problems: https://lore.kernel.org/lkml/YMs3O%2Fcg4V7ywlVq@infradead.org/

Based on the analysis, he suggested breaking a different dependency instead. I had initially thought that this lock dependency was necessary, but on closer inspection I realised I has misunderstood the purpose of the locks, and the dependency could indeed be broken. I then tested the co-developed patch and sent it for review.

### possible deadlock in brd_probe
Link to Syzbot report: https://syzkaller.appspot.com/bug?id=cbf5fe846f14a90f05e10df200b08c57941dc750

After analyzing the previous bug, I noticed that another bug report of a possible deadlock involved the lock dependency that we broke in our patch. As such, the patch for the previous bug should also resolve this bug. This was confirmed by Syzbot.

## Summary

The past 3 weeks were definitely a game-changing experience. Initially, during the application period, I had looked at some of the Syzbot bugs, but had no idea how to approach them. But now I have the confidence to see a crash report and think: "I can do something about this."

I've also had a great experience getting acquainted with the Linux kernel development community. Everyone has been very nurturing, giving comments and suggestions, and even pointing the direction towards further work to be done. Even when my work is being criticized, I've learned that everyone is simply trying to offer help to make the kernel as good as it can be. We're all on the same team.
