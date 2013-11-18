# rw_test sdram

.ammem 0 0
.ammem 1 0
.ammem 2 0
.ammem 3 37777777777
.ammem 4 5

.ammem 010 0
.ammem 011 1
.ammem 012 2
.ammem 013 3
.ammem 014 4

.ammem 20 07777
.ammem 21 01111
.ammem 22 02222
.ammem 23 03333
.ammem 24 04444

# create mapping for virt address 0
.map 0 +

.org 0
    alu setz a=0
    alu seta a=4 m=0 m[0] C=0 alu-> ->m[5]         # m[5] <- m[4]

    alu setm m=4 alu-> ->md
    alu seta a=3 alu-> ->vma+write
    noop
loop:
    alu setm m=20 alu-> ->md
    alu seta a=10 alu-> ->vma+write
    noop
    alu setm m=21 alu-> ->md
    alu seta a=11 alu-> ->vma+write
    noop
    alu setm m=22 alu-> ->md
    alu seta a=12 alu-> ->vma+write
    noop
    alu setm m=23 alu-> ->md
    alu seta a=13 alu-> ->vma+write
    noop
    alu setm m=24 alu-> ->md
    alu seta a=14 alu-> ->vma+write
    noop
    alu seta a=10 alu-> ->vma+read
    noop
    alu seta a=11 alu-> ->vma+read
    noop
    alu seta a=12 alu-> ->vma+read
    noop
    alu seta a=13 alu-> ->vma+read
    noop
    alu seta a=14 alu-> ->vma+read
    noop
    alu m+a add a=3 m=5 C=0 alu-> ->m[5]           # m[5]--
    jump a=2 m=5 pc=loop !next !jump m-src==a-src  # loop if m[5] != 0
    noop
    noop
    noop
    noop
    .op 10000000000000000
