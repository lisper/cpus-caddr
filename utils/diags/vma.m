# read back vma[md]

.ammem 0 0
.ammem 1 0
.ammem 2 0
.ammem 3 37777777777

.ammem 10 000002
.ammem 11 020404
.ammem 12 112345
.ammem 13 077050000

.ammem 20 10060000000
.ammem 21 10160000041
.ammem 22 30000000000
.ammem 23 10260036120

# create mapping for virt address 0
.map 000000000 +
.map 000020400 +
.map 077050000 +

.org 0
    jump pc=5 !next T
    noop
bad:
    .op 10000000000000001
    jump pc=bad !next T

.org 5
    # vma[md]
    alu setm m=10 alu-> ->md
    alu setm m=10 alu-> ->vma+write
    noop
    alu setm m=map alu-> ->m[4]
    alu setm m=4 alu-> ->md
    jump a=20 m=md pc=bad !next !jump m-src==a-src
    noop
#
    alu setm m=11 alu-> ->md
    alu setm m=11 alu-> ->vma+write
    noop
    alu setm m=map alu-> ->m[5]
    alu setm m=5 alu-> ->md
    jump a=21 m=md pc=bad !next !jump m-src==a-src
    noop
#
    alu setm m=12 alu-> ->md
    alu setm m=12 alu-> ->vma+write
    noop
    alu setm m=map alu-> ->m[6]
    alu setm m=6 alu-> ->md
    jump a=22 m=md pc=bad !next !jump m-src==a-src
    noop
#
    alu setm m=13 alu-> ->md
    alu setm m=13 alu-> ->vma+write
    noop
    alu setm m=map alu-> ->m[7]
    alu setm m=7 alu-> ->md
    jump a=23 m=md pc=bad !next !jump m-src==a-src
    noop

    .op 10000000000000000
