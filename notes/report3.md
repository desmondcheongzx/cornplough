# Third evaluation report
## Accepted patches
b2a616676839e2a6b02c8e40be7f886f882ed194 btrfs: fix rw device counting in __btrfs_free_extra_devids

b3b2177a2d795e35dc11597b2609eb1e7e57e570 hfs: add lock nesting notation to hfs_find_init

54a5ead6f5e2b47131a7385d0c0af18e7b89cb02 hfs: fix high memory mapping in hfs_bnode_read

16ee572eaf0d09daa4c8a755fdb71e40dbf8562d hfs: add missing clean-up in hfs_fill_super

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

[PATCH v2] Bluetooth: skip invalid hci_sync_conn_complete_evt
https://lore.kernel.org/lkml/20210728075105.415214-1-desmondcheongzx@gmail.com/

[PATCH v8 0/5] drm: address potential UAF bugs with drm_master ptrs
https://lore.kernel.org/lkml/20210712043508.11584-1-desmondcheongzx@gmail.com/

## Bug analyses

### BUG: corrupted list in kobject_add_internal (3)
Link to Syzbot report: https://syzkaller.appspot.com/bug?extid=66264bf2fd0476be7e6c

This bug turned out to be relatively straight-forward to fix, but tricky to verify. From the stack trace, it was clear that kernel memory was being corrupted by the same device being added multiple times in `hci_sync_conn_complete_evt`. To fix this, we simply had to detect if the device had been added before, then skip the invalid event.

However, when testing this fix with Syzbot, we hit an unrelated issue "Inconsistent lock state in sco" (that appears later in this report). So we first needed to find a fix that could clear this error message before verifying the fix for `hci_sync_conn_complete_evt`.

After submitting the patch, the maintainer Marcel Holtmann suggested that I needed to elaborate on the fix in the comments, because this bug is triggered by illegal behavior from a device (https://lore.kernel.org/lkml/A47B24AE-C807-4ADA-B0F7-8283ACC83BF7@holtmann.org/). To write this up, I first went back to read through parts of the Bluetooth specification to understand what was expected behavior, and what was illegal.

### WARNING in close_fs_devices (3)
Link to Syzbot report: https://syzkaller.appspot.com/bug?id=113d9a01cbe0af3e291633ba7a7a3e983b86c3c0

From the cause of the warning: `WARN_ON(fs_devices->rw_devices);` in `close_fs_devices`, it was clear that this bug involved incorrect counting for writable devices when mounting a btrfs file system.

The biggest aid for tackling this bug was an old friend: extensive print debugging. I added debugging statements each time the r/w device count was incremented and decremented in order to get a better picture of how the device count changed during program execution. Then, using these debugging statements with the reproducer, I figured out the call trace that resulted in the incorrect device count. Following the call trace, I found the point where a writable device was removed without a corresponding decrement to the r/w device count, and the fix was straight-forward from there.

However, after proposing this fix, the maintainer David Sterba pointed out that the decrement used to be guarded by a condition (https://lore.kernel.org/lkml/20210721175938.GP19710@twin.jikos.cz/), and we needed a clearer picture of the system's state machine of device bits and counters before we could decide if the proposed fix was correct.

To do this, I dug into the history of patches for device counting (with extensive usage of git log) and summarized the history of changes as well as the current state of the codebase. We concluded that the fix was correct and the patch was merged.

### Inconsistent lock state in sco
Link to Syzbot report: https://syzkaller.appspot.com/bug?id=9089d89de0502e120f234ca0fc8a703f7368b31e

This is the second report that this bug has appeared in. Each time I thought we had a good fix for it, either through further studying or discussion with the maintainers, we changed directions to an even more suitable solution.

Although I'm certain that our present fix works, this bug will take awhile more before it's resolved. After spending so much time studying the Bluetooth stack, I started to notice that the locking and socket killing schemes have races, deadlocks, and other execution bugs in them. The blessing is that many of these can be hit by the same reproducer, and so this is a good chance to eliminate all the errors at the same time.

The main tools used here are a combination of tools I've been using for other bugs: code comprehension tools like cscope and etags, git log, git blame, and good old-fashioned discussions.

## Summary

The weeks really go by fast. For the past 3 weeks, I browsed less bugs than I did during the first half of the program. Instead, I've been opting to dive deeper into bugs that I might not have chosen to tackle before, even if it feels like I have no idea what the solution might look like.

I feel that, thanks to the problems becoming more involved, I've also learned how to work better with complexity. And due to exposure to a variety of issues that come from trying to unravel a complicated bug, a lot of other bugs are starting to seem more tractable to me.
