# dispatch test with bits N & P

.amem 4 000000
.amem 5 020000
.amem 6 040000
.amem 7 060000

.ammem 20 0
.ammem 21 1
.ammem 22 2
.ammem 23 3

# values we should see pop out of the isn machine
.amem 101 11111
.amem 102 22222

# create mapping for virt address 0..60000
.map 000000000 +
.map 000020000 9
.map 000040000
.map 000060000 +

.org 0
    jump pc=5 !next T
    noop
bad:
    .op 10000000000000077
    jump pc=bad !next T

.org 5
    alu seta a=4 alu-> ->lc
    alu seta a=4 alu-> ->md
    noop

disp0:
    noop
    alu seta a=5 alu-> ->md
    dispatch !N+1 map-19 disp-addr=2 m=map
    noop
    .op 10000000000000001

disp3:
    noop
    alu seta a=6 alu-> ->md
    dispatch !N+1 map-19 disp-addr=4 m=map
    noop
    .op 10000000000000003

disp5:
    noop
    alu seta a=7 alu-> ->md
    dispatch disp-addr=6 m=map
    noop
    .op 10000000000000005

disp6:
    noop
    dispatch disp-addr=10
    .op 10000000000000000

disp7:
    .op 10000000000000007

disperr:
    .op 10000000000000010

.dmem 0 disp0
.dmem 1 disperr

.dmem 2 disperr
.dmem 3 disp3 NP

.dmem 4 disp5 NP
.dmem 5 disperr

.dmem 6 disp6
.dmem 7 disperr

.dmem 10 disp7
.dmem 11 disperr

