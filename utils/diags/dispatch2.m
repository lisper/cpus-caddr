# dispatch test with bits 8 & 9

.amem 4 000000
.amem 5 020000
.amem 6 040000
.amem 7 060000

# raw packed isn's
.ammem 10 002222222222
.ammem 11 006666644444

.ammem 20 0
.ammem 21 1
.ammem 22 2
.ammem 23 3

# values we should see pop out of the isn machine
.amem 101 11111
.amem 102 22222

# create mapping for virt address 0..60000
.map 000000000 +
.map 000020000 +8
.map 000040000 +9
.map 000060000 +

.org 0
    jump pc=5 !next T
    noop
bad:
    .op 10000000000000077
    jump pc=bad !next T

.org 5
    # write raw isns
    alu seta a=10 alu-> ->md
    alu seta a=20 alu-> ->vma+write
    noop
    alu seta a=11 alu-> ->md
    alu seta a=21 alu-> ->vma+write
    noop

    alu seta a=4 alu-> ->lc
    alu seta a=4 alu-> ->md
    dispatch ISH
    noop
    .op 10000000000000001
    noop
    noop

disp0:
    noop
    alu setm m=md alu-> ->m[2]
    byte ldb pos=0 width=20 misc=3 m=2 ->m[3]
    jump a=102 m=3 pc=bad !next !jump m-src==a-src

    alu seta a=5 alu-> ->md
    dispatch map-18 disp-addr=2
    noop
    .op 10000000000000001

disp3:
    noop
    alu seta a=6 alu-> ->md
    dispatch map-19 disp-addr=4
    noop
    .op 10000000000000003

disp5:
    noop
    alu seta a=7 alu-> ->md
    dispatch map-18 disp-addr=6
    noop
    .op 10000000000000005

disp6:
    noop
    .op 10000000000000000

disp7:
    .op 10000000000000007

disperr:
    .op 10000000000000010

.dmem 0 disp0
.dmem 1 disperr

.dmem 2 disperr
.dmem 3 disp3

.dmem 4 disperr
.dmem 5 disp5

.dmem 6 disp6
.dmem 7 disp7

