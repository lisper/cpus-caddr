# patch_rw_test dram

.ammem 10 1
.ammem 21 1234

.amem 436 2

# create mapping for virt address 0
.map 0 +

.org 0

    byte a=21 m=21 ->md
    alu seta a=436 m=0 alu-> ->vma+write
    noop
    noop	
    alu seta a=436 m=0 alu-> ->vma+read
    noop
    noop
    byte a=20 m=21 ->md
#    alu seta a=2 alu-> ->vma+write
#    noop
#    noop
#    noop
#    alu seta a=4 alu-> ->vma+write
#    noop
#    noop
#    noop
#    alu seta a=6 alu-> ->vma+write
#    noop
#    noop
#    noop
    alu seta a=10 alu-> ->vma+write
    noop
    noop
    alu seta a=10 alu-> ->vma+read
    noop
    noop
    alu seta a=436 alu-> ->vma+read
    noop
    noop
    alu seta a=10 alu-> ->vma+read
    noop
    noop
    alu seta a=436 alu-> ->vma+read
    noop
    noop
    alu seta a=10 alu-> ->vma+read
    noop
    noop
#    alu seta a=436 alu-> ->vma+write
#    noop
#    noop
#    noop
#    alu m+a a=2 alu-> ->vma+read
#    noop
#    noop
#    noop
#    alu m+a a=4 alu-> ->vma+read
#    noop
#    noop
#    noop
#    alu m+a a=6 alu-> ->vma+read
#    noop
#    noop
#    noop
#    alu m+a a=10 alu-> ->vma+read
#    noop
#    noop
#    noop
#    alu m+a a=436 alu-> ->vma+read
#    noop	
#    noop	
#    alu seta a=436 alu-> ->vma+write
#    noop
#    alu m+a a=40 m=50 alu-> ->vma+read
    noop
    noop
    noop
    noop
    noop
    .op 10000000000000000

