# rw_test sdram

.ammem 02 01234567
.ammem 03 0xffffffff
.ammem 04 04444
.ammem 05 05555

.ammem 010 0
.ammem 011 1
.ammem 012 2
.ammem 013 3
.ammem 020 01234

# create mapping for virt address 0
.map 0 +

.org 0
    alu setz a=0 ->md
    alu seta a=10 alu-> ->vma+write
    noop
    alu setm m=2 alu-> ->md
    alu seta a=11 alu-> ->vma+write
    noop
    alu setm m=4 alu-> ->md
    alu seta a=12 alu-> ->vma+write
    noop
    alu setm m=5 alu-> ->md
    alu seta a=13 alu-> ->vma+write
    noop
    alu seta a=10 alu-> ->vma+read
    noop
    alu seta a=11 alu-> ->vma+read
    noop
    alu seta a=12 alu-> ->vma+read
    noop
    alu seta a=13 alu-> ->vma+read
    noop
    noop
    noop
    .op 10000000000000000
