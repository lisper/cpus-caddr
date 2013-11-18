# dispatch test with 16 bit isn fetch

# raw packed isn's
.ammem 10 002222222222
.ammem 11 006666644444
.ammem 12 013333266666
.ammem 13 017777612345

.ammem 20 0
.ammem 21 1
.ammem 22 2
.ammem 23 3

# values we should see pop out of the isn machine
.amem 101 11111
.amem 102 22222
.amem 103 33333
.amem 104 44444
.amem 105 55555
.amem 106 66666
.amem 107 77777
.amem 110 12345

# create mapping for virt address 0
.map 0 +

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
    alu seta a=12 alu-> ->md
    alu seta a=22 alu-> ->vma+write
    noop
    alu seta a=13 alu-> ->md
    alu seta a=23 alu-> ->vma+write
    noop

    dispatch ISH
    noop
    .op 10000000000000001
    noop
    noop
    noop
disp0:
    noop
    alu setm m=md alu-> ->m[2]
    byte ldb pos=0 width=20 misc=3 m=2 ->m[3]
    jump a=102 m=3 pc=bad !next !jump m-src==a-src

    dispatch ISH disp-addr=1
    noop
    .op 10000000000000002
disp1:
    noop
    alu setm m=md alu-> ->m[2]
    byte ldb pos=0 width=20 misc=3 m=2 ->m[3]
    jump a=101 m=3 pc=bad !next !jump m-src==a-src

    dispatch ISH disp-addr=2
    noop
    .op 10000000000000003
disp2:
    noop
    alu setm m=md alu-> ->m[2]
    byte ldb pos=0 width=20 misc=3 m=2 ->m[3]
    jump a=104 m=3 pc=bad !next !jump m-src==a-src

    dispatch ISH disp-addr=3
    noop
    .op 10000000000000004
disp3:
    noop
    alu setm m=md alu-> ->m[2]
    byte ldb pos=0 width=20 misc=3 m=2 ->m[3]
    jump a=103 m=3 pc=bad !next !jump m-src==a-src

    dispatch ISH disp-addr=4
    noop
    .op 10000000000000005
disp4:
    noop
    alu setm m=md alu-> ->m[2]
    byte ldb pos=0 width=20 misc=3 m=2 ->m[3]
    jump a=106 m=3 pc=bad !next !jump m-src==a-src

    dispatch ISH disp-addr=5
    noop
    .op 10000000000000006
disp5:
    noop
    alu setm m=md alu-> ->m[2]
    byte ldb pos=0 width=20 misc=3 m=2 ->m[3]
    jump a=105 m=3 pc=bad !next !jump m-src==a-src

    dispatch ISH disp-addr=6
    noop
    .op 10000000000000007
disp6:
    noop
    alu setm m=md alu-> ->m[2]
    byte ldb pos=0 width=20 misc=3 m=2 ->m[3]
    jump a=110 m=3 pc=bad !next !jump m-src==a-src

    dispatch ISH disp-addr=7
    noop
    .op 10000000000000008
disp7:
    noop
    alu setm m=md alu-> ->m[2]
    byte ldb pos=0 width=20 misc=3 m=2 ->m[3]
    jump a=107 m=3 pc=bad !next !jump m-src==a-src
    noop
    .op 10000000000000000

.dmem 0 disp0
.dmem 1 disp1
.dmem 2 disp2
.dmem 3 disp3
.dmem 4 disp4
.dmem 5 disp5
.dmem 6 disp6
.dmem 7 disp7

