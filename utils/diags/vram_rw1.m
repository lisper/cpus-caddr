# patch_rw_test vram

.ammem 0 0
.ammem 1 1
.ammem 2 2
.ammem 3 0

.amem 65 077050000
.amem 66 077050001
.amem 67 0

.amem 70 0
.amem 71 1
.amem 72 2

# create mapping for vram
.map 077050000 +

.org 0

    alu setz a=3 ->md
    alu seta a=65 alu-> ->vma+write
    noop
    noop
    alu setz a=1 ->md
    alu seta a=65 alu-> ->vma+write
    noop
    noop
    alu setz a=1 ->md
    alu seta a=65 alu-> ->vma
    alu m+a a=2 m=vma alu-> ->vma+write
    noop
    noop
    alu seta a=66 m=0 alu-> ->vma
    alu m+a a=70 m=vma alu-> ->vma+read
    noop
    noop
    alu seta a=65 alu-> ->vma
    alu m+a a=70 m=vma alu-> ->vma+read
    noop
    noop
    alu seta a=66 alu-> ->vma
    alu m+a a=70 m=vma alu-> ->vma+read
    noop
    noop
    alu seta a=65 alu-> ->vma
    alu m+a a=70 m=vma alu-> ->vma+read
    noop
    noop
    noop
    noop
    noop

    .op 10000000000000000
