#
# rw_test sdram with long loop (1000) and data checking
#

.ammem 0 0
.ammem 1 0
.ammem 2 0
.ammem 3 37777777777
.ammem 4 1000
.ammem 6 12345678

.ammem 10 0
.ammem 11 1
.ammem 12 2
.ammem 13 3
.ammem 14 4

.ammem 20 07777
.ammem 21 01111
.ammem 22 02222
.ammem 23 03333
.ammem 24 04444
.ammem 25 05555

# create mapping for virt address 0
.map 0 +

.org 0
    jump pc=5 !next T
    noop
bad:
    .op 10000000000000001
    jump pc=bad !next T

.org 5
start:
    alu setz a=0
    alu seta a=4 m=0 m[0] C=0 alu-> ->m[5]         # m[5] <- m[4]
    alu setm m=6 alu-> ->vma
loop:
    alu setm m=25 alu-> ->md
    alu seta a=10 alu-> ->vma+write
    noop
    alu seta a=11 alu-> ->vma+write
    noop
    alu seta a=12 alu-> ->vma+write
    noop
    alu seta a=13 alu-> ->vma+write
    noop
    alu seta a=14 alu-> ->vma+write
    noop
#
    alu setm m=20 alu-> ->md
    alu seta a=10 alu-> ->vma+write
    noop

    alu seta a=10 alu-> ->vma+read
    noop
    jump a=20 m=md pc=bad !next !jump m-src==a-src

    alu setm m=21 alu-> ->md
    alu seta a=11 alu-> ->vma+write
    noop

    alu seta a=11 alu-> ->vma+read
    noop
    jump a=21 m=md pc=bad !next !jump m-src==a-src

    alu setm m=22 alu-> ->md
    alu seta a=12 alu-> ->vma+write
    noop

    alu seta a=12 alu-> ->vma+read
    noop
    jump a=22 m=md pc=bad !next !jump m-src==a-src

    alu setm m=23 alu-> ->md
    alu seta a=13 alu-> ->vma+write
    noop

    alu seta a=13 alu-> ->vma+read
    noop
    jump a=23 m=md pc=bad !next !jump m-src==a-src

    alu setm m=24 alu-> ->md
    alu seta a=14 alu-> ->vma+write
    noop

    alu seta a=14 alu-> ->vma+read
    noop
    jump a=24 m=md pc=bad !next !jump m-src==a-src

#
    alu seta a=10 alu-> ->vma+read
    noop
    jump a=20 m=md pc=bad !next !jump m-src==a-src

    alu seta a=11 alu-> ->vma+read
    noop
    jump a=21 m=md pc=bad !next !jump m-src==a-src

    alu seta a=12 alu-> ->vma+read
    noop
    jump a=22 m=md pc=bad !next !jump m-src==a-src

    alu seta a=13 alu-> ->vma+read
    noop
    jump a=23 m=md pc=bad !next !jump m-src==a-src

    alu seta a=14 alu-> ->vma+read
    noop
    jump a=24 m=md pc=bad !next !jump m-src==a-src

    alu m+a add a=3 m=5 C=0 alu-> ->m[5]           # m[5]--
    jump a=2 m=5 pc=loop !next !jump m-src==a-src  # loop if m[5] != 0
    noop
    noop
    noop
    noop
    .op 10000000000000000
