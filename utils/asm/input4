# rw_test vram r/w

.ammem 02 01234567
.ammem 03 0xffffffff

.ammem 065 077051763
.ammem 066 077051764

# create mapping for virt address in fb
.map 077051764 +

.org 0

    alu setz a=0
    alu seta a=65 alu-> ->vma+write
    noop
    alu seta a=65 alu-> ->vma+write
    noop
    alu seta a=65 alu-> ->vma+write
    noop
    alu seta a=65 alu-> ->vma+write
    noop
    alu seta a=66 alu-> ->vma+read
    noop
    alu seta a=66 alu-> ->vma+read
    noop
    alu seta a=66 alu-> ->vma+read
    noop
    alu seta a=66 alu-> ->vma+read
    noop
    alu seta a=65 alu-> ->vma+write
    noop
    alu seta a=65 alu-> ->vma+write
    noop
    alu seta a=65 alu-> ->vma+write
    noop
    alu seta a=65 alu-> ->vma+write
    noop
    noop
    noop
    noop
    .op 10000000000000000
    noop
    noop
    noop
