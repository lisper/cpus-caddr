#!/bin/sh

(while read line; do
  echo $line
done) <<EOF
[size] 1000 600
[pos] 67 -22
*-5.707018 260 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1
[treeopen] test.
EOF

# check for iverilog
iverilog=0

if  head caddr.vcd | grep -q Icarus ; then
    iverilog=1
fi

(while read -r signalname format; do
#
#iverilog
   if [ $iverilog == "1" ]; then
     if [ "${signalname:0:1}" == "\\" ]; then
        signalname=${signalname:1}
     fi
  fi
  if [ "$signalname" == "---" ]; then
      echo '@30'
  else
      signalname="test.cpu.$signalname"
#      echo $signalname' mode="oct" rjustified="yes"'
      echo $signalname
  fi
done) <<EOF
clk
reset
state[4:0]
state_decode
state_write
state_fetch
--- {New Divider}
machrun
srun
run
boot
reset
halt
waiting
--- {New Divider}
needfetch
have_wrong_word
last_byte_in_word
lc0b
newlc
destlc
lc[25:0] octal
--- {New Divider}
lpc[13:0] octal
npc[13:0] octal
pc[13:0] octal
dpc[13:0] hex
ipc[13:0] octal
ir[48:0] hex
ob[31:0] hex
iob[47:0]
destimod0
destimod1
irbyte
irdisp
irjump
iralu
clk
--- Jump
jcond
jfalse
conds[2:0]
aluf[3:0]
alumode
cin0_n
aluadd
alusub
pcs0
pcs1
--- 
n
trap
iwrited
nop
nopa
inop
nop11
--- Shift
r[31:0] hex
sa[31:0] hex
s0
s1
s2
s3
s4
--- {M & A bus}
alu[32:0] hex
q[31:0] hex
aeqm_bits[7:0]
a[31:0] hex
m[31:0] hex
mmem_latched[31:0] hex
mpassm
pdldrive
spcdrive
mfdrive
--- {M & A mem}
clk
wadr[9:0] hex
madr[4:0] hex
mmem[31:0] hex
mwp
aadr[9:0] hex
amem[31:0] hex
awp
l[31:0] hex
--- {New Divider}
mf[31:0] hex
lcdrive
opcdrive
dcdrive
ppdrive
pidrive
qdrive
mddrive
mpassl
vmadrive
--- {New Divider}
q[31:0] hex
qs1
qs0
ob[31:0] hex
osel[1:0]
mskl[4:0] hex
mskr[4:0] hex
msk[31:0] octal
r[31:0] octal
a[31:0] octal
clk
--- SPC
spcptr[4:0] hex
swp
spcnt
spush
spop
spcw[18:0] hex
spco[18:0] hex
spco_latched[18:0] hex
spcdrive
spc[18:0] hex
--- PDL
pdlidx[9:0] hex
pdlptr[9:0] hex
pdla[9:0] hex
pwp
pdlwrite
pdlwrited
destpdltop
destpdl_x
destpdl_p
destm
--- {VMA memory}
md[31:0] hex
mdclk
mds[31:0] hex
vm0wp
mapi[23:8] hex
vm1wp
wmap
wmapd
vma[31:0] hex
vmas[31:0] hex
ob[31:0] hex
--- IRAM
pc[13:0] octal
iwr[48:0] hex
iwe
iwrite
--- {Dispatch mem}
md[31:0] hex
dwe
dadr[10:0] hex
dmask[6:0] hex
r[31:0] hex
lpc octal
--- {New Divider}
pgf_or_int
pgf_or_int_or_sb
pfr
pfw
lvmo_23
lvmo_22
pma[21:8] hex
vmem1_adr[9:0] hex
vmo[23:0] hex
vmaok
sint
sintr
int
--- {Bus Interface}
wmap
memrd
memwr
destmem
memop
memstart
memrq
memprepare
memack
mfinish
mfinishd
waiting
memgrant
mbusy
use_md
wmap
wmapd
rdcyc
wrcyc
vmo hex
pma hex
--- {Bus}
loadmd
mdclk
mdsel
memdrive
mds[31:0] hex
md[31:0] hex
busint_bus[31:0] hex
EOF

exit 0
