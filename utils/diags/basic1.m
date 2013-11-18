# simple tests which diplicate what the prom does
# 
# test rotator, basic alu paths, basic a/m rw
# basic alu functions, carry, PDL buffer
#

.org 0
    jump pc=10 !next T
    noop

error-bad-bit:
    .op 10000000000000001
error-a-mem:
    .op 10000000000000002
error-m-mem:
    .op 10000000000000003
error-add-looses:
    .op 10000000000000004
error-pdl-buffer:
    .op 10000000000000005

   noop

go:
    noop
# make all zeros.  Result to Q-R, not to depend on M mem
    alu setz alu-> q-r ->m[2] 
    jumpm=q pc=error-bad-bit !next m-rot<<=0
    jump m=q pc=error-bad-bit !next m-rot<<=31
    jump m=q pc=error-bad-bit !next m-rot<<=30
    jump m=q pc=error-bad-bit !next m-rot<<=29
    jump m=q pc=error-bad-bit !next m-rot<<=28
    jump m=q pc=error-bad-bit !next m-rot<<=27
    jump m=q pc=error-bad-bit !next m-rot<<=26
    jump m=q pc=error-bad-bit !next m-rot<<=25
    jump m=q pc=error-bad-bit !next m-rot<<=24
    jump m=q pc=error-bad-bit !next m-rot<<=23
    jump m=q pc=error-bad-bit !next m-rot<<=22
    jump m=q pc=error-bad-bit !next m-rot<<=21
    jump m=q pc=error-bad-bit !next m-rot<<=20
    jump m=q pc=error-bad-bit !next m-rot<<=19
    jump m=q pc=error-bad-bit !next m-rot<<=18
    jump m=q pc=error-bad-bit !next m-rot<<=17
    jump m=q pc=error-bad-bit !next m-rot<<=16
    jump m=q pc=error-bad-bit !next m-rot<<=15
    jump m=q pc=error-bad-bit !next m-rot<<=14
    jump m=q pc=error-bad-bit !next m-rot<<=13
    jump m=q pc=error-bad-bit !next m-rot<<=12
    jump m=q pc=error-bad-bit !next m-rot<<=11
    jump m=q pc=error-bad-bit !next m-rot<<=10
    jump m=q pc=error-bad-bit !next m-rot<<=9
    jump m=q pc=error-bad-bit !next m-rot<<=8
    jump m=q pc=error-bad-bit !next m-rot<<=7
    jump m=q pc=error-bad-bit !next m-rot<<=6
    jump m=q pc=error-bad-bit !next m-rot<<=5
    jump m=q pc=error-bad-bit !next m-rot<<=4
    jump m=q pc=error-bad-bit !next m-rot<<=3
    jump m=q pc=error-bad-bit !next m-rot<<=2
    jump m=q pc=error-bad-bit !next m-rot<<=1

# make all ones, in Q-R not to trust M Mem
    alu seto alu-> q-r ->m[3] 
    jump m=q pc=error-bad-bit !next !jump m-rot<<=0
    jump m=q pc=error-bad-bit !next !jump m-rot<<=31
    jump m=q pc=error-bad-bit !next !jump m-rot<<=30
    jump m=q pc=error-bad-bit !next !jump m-rot<<=29
    jump m=q pc=error-bad-bit !next !jump m-rot<<=28
    jump m=q pc=error-bad-bit !next !jump m-rot<<=27
    jump m=q pc=error-bad-bit !next !jump m-rot<<=26
    jump m=q pc=error-bad-bit !next !jump m-rot<<=25
    jump m=q pc=error-bad-bit !next !jump m-rot<<=24
    jump m=q pc=error-bad-bit !next !jump m-rot<<=23
    jump m=q pc=error-bad-bit !next !jump m-rot<<=22
    jump m=q pc=error-bad-bit !next !jump m-rot<<=21
    jump m=q pc=error-bad-bit !next !jump m-rot<<=20
    jump m=q pc=error-bad-bit !next !jump m-rot<<=19
    jump m=q pc=error-bad-bit !next !jump m-rot<<=18
    jump m=q pc=error-bad-bit !next !jump m-rot<<=17
    jump m=q pc=error-bad-bit !next !jump m-rot<<=16
    jump m=q pc=error-bad-bit !next !jump m-rot<<=15
    jump m=q pc=error-bad-bit !next !jump m-rot<<=14
    jump m=q pc=error-bad-bit !next !jump m-rot<<=13
    jump m=q pc=error-bad-bit !next !jump m-rot<<=12
    jump m=q pc=error-bad-bit !next !jump m-rot<<=11
    jump m=q pc=error-bad-bit !next !jump m-rot<<=10
    jump m=q pc=error-bad-bit !next !jump m-rot<<=9
    jump m=q pc=error-bad-bit !next !jump m-rot<<=8
    jump m=q pc=error-bad-bit !next !jump m-rot<<=7
    jump m=q pc=error-bad-bit !next !jump m-rot<<=6
    jump m=q pc=error-bad-bit !next !jump m-rot<<=5
    jump m=q pc=error-bad-bit !next !jump m-rot<<=4
    jump m=q pc=error-bad-bit !next !jump m-rot<<=3
    jump m=q pc=error-bad-bit !next !jump m-rot<<=2
    jump m=q pc=error-bad-bit !next !jump m-rot<<=1
# ALU and Shifter do not drop or pick bits
# Test M-mem, A-mem, and M=A logic
    jump a=3 m=q pc=error-a-mem !next !jump m-src==a-src 
    jump a=3 m=3 pc=error-m-mem !next !jump m-src==a-src 
    alu setz alu-> q-r ->m[0] 
    jump a=2 m=q pc=error-a-mem !next !jump m-src==a-src 
    jump a=2 m=2 pc=error-m-mem !next !jump m-src==a-src 
# See if all carries in ALU really carry.
    alu m+a a=2 m=3 c=1 alu-> q-r ->m[0] 
    jump a=2 m=q pc=error-add-looses !next !jump m-src==a-src 
# Another simple carry test
    alu m+a a=3 m=3 c=0 alu-> q-r ->m[0] 
    jump m=q pc=error-add-looses !next m-rot<<=0
    jump m=q pc=error-add-looses !next !jump m-rot<<=31
    jump m=q pc=error-add-looses !next !jump m-rot<<=1
# Prepare to test pdl buffer.  Care required since no pass-around path.
    alu setm m=2 alu-> ->pdl[ptr]+push
    alu setm m=3 alu-> ->pdl[ptr]+push
# This verifies that -1 + -1 is -2 and also tests the byte hardware a little
    byte ldb pos=37 width=37 a=3 m=q ->md
    jump a=3 m=md pc=error-add-looses !next !jump m-src==a-src 
# Foo, the byte hardware could be tested a little bit better than that!
    jump a=3 m=pdl[ptr]+pop pc=error-pdl-buffer !next !jump m-src==a-src 
    jump a=2 m=pdl[ptr]+pop pc=error-pdl-buffer !next !jump m-src==a-src 
    byte dpb pos=5 width=1 a=2 m=3 ->m[1] 
    byte dpb pos=2 width=1 a=2 m=3 ->md
    noop

    .op 10000000000000000
