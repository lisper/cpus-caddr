# patch_rw_test vram

.ammem 0 1234

.ammem 010 077377700

# create mapping for disk
.map 077377700 +

.org 0

    alu setz a=0 ->md
    alu seta a=10 alu-> ->vma+write
    noop
    alu seta a=10 alu-> ->vma+read
    noop
    alu seta a=10 alu-> ->vma+read
    noop
    alu seta a=10 alu-> ->vma+read
    noop
    alu seta a=10 alu-> ->vma+read
    noop
    noop
    noop
    noop
    noop

    .op 10000000000000000
