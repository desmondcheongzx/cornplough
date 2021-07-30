# cornplough
Tools, notes, and logs for Linux kernel development.

## Linux Kernel Mentorship Program

I'm currently participating in the summer 2021 cycle of the [Linux Kernel Mentorship Program]. Here are some of my notes:

### Evaluation reports
- [First report](/notes/report1.md): summary of weeks 1-3 of the program
- [Second report](/notes/report2.md): summary of weeks 4-6 of the program

## Scripts

Some helpful utility scripts (under [scripts/](scripts/)):
- prepmail: when sending patches to subsystems, one gets uses the kernel's `scripts/get_maintainer.pl`. Piping the output of this script to `prepmail` will format it appropriately for `git format-patch`:
```
$ scripts/get_maintainer.pl <filepath> | prepmail
--to=maintainer1@email.com --to=maintainer2@email.com --to=maintainer3@email.com --cc=mailinglist@site.com
```
