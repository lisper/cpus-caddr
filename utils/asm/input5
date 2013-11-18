# basic loop test

.amem 0 0
.amem 1 0
.amem 2 0
.amem 3 37777777777
.amem 4 5

.amem 010 0
.org 0
    alu setz a=1
    alu seta a=4 m=0 m[0] C=0 alu-> ->m[5]         # m[5] <- m[4]
loop:
    noop
    alu m+a a=3 m=5 C=0 alu-> ->m[5]           # m[5]--
    jump a=2 m=5 pc=loop !next !jump m-src==a-src  # loop if m[5] != 0
    noop

    .op 10000000000000000
