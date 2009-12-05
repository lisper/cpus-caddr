#!/bin/sh

(while read line; do
  echo $line
done) <<EOF
<?xml version="1.0"?>
<!-- GTKWave saved traces, version 2.0.0pre5 -->
<!-- at Fri Oct 29 08:33:19 2004 -->

<config>
 <decors>
  <decor name="default">
   <trace-state-colors>
    <named-color name="font" color="#00ff00"/>
    <named-color name="low" color="#00ff00"/>
    <named-color name="high" color="#00ff00"/>
    <named-color name="x" color="#00ff00"/>
    <named-color name="xfill" color="#008000"/>
    <named-color name="trans" color="#00ff00"/>
    <named-color name="mid" color="#00ff00"/>
    <named-color name="vtrans" color="#00ff00"/>
    <named-color name="vbox" color="#00ff00"/>
    <named-color name="unloaded" color="#800000"/>
    <named-color name="analog" color="#00ff00"/>
    <named-color name="clip" color="#ff0000"/>
    <named-color name="req" color="#ff0000"/>
    <named-color name="ack" color="#008000"/>
    <named-color name="hbox" color="#ffffff"/>
   </trace-state-colors>
  </decor>
 </decors>

 <trace-groups>
  <trace-group name="default" decor="default">
  </trace-group>
 </trace-groups>

 <pane-colors>
  <named-color name="back" color="#181818"/>
  <named-color name="grid" color="#808080"/>
  <named-color name="mark" color="#0000ff"/>
  <named-color name="umark" color="#ffff00"/>
  <named-color name="pfont" color="#ffffff"/>
 </pane-colors>

 <markers>
  <marker name="primary" time="0 s"/>
 </markers>

 <traces>
EOF

# check for iverilog
iverilog=0

if  head cadr.vcd | grep -q Icarus ; then
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
      echo '  <separator name="">'
      echo '  </separator>'
  else
      signalname="test.cpu.$signalname"
      echo '  <trace name="'$signalname'" mode="oct" rjustified="yes">'
      echo '    <signal name="'$signalname'"/>'
      echo '  </trace>'
  fi
done) <<EOF
CLK
CLK
tpw1
tpw2
wp
--- {New Divider}
needfetch
have_wrong_word
last_byte_in_word
lc0b
newlc_n
destlc_n
lc[25:0] octal
--- {New Divider}
machrun
srun
run
boot_n
boot2_n
boot1_n
power_reset_n
clock_reset_n
--- {New Divider}
lpc[13:0] octal
npc[13:0] octal
pc[13:0] octal
dpc[13:0] hex
ipc[13:0] octal
ir[48:0] hex
ob[31:0] hex
iob[47:0]
destimod0_n
destimod1_n
irbyte_n
irdisp_n
irjump_n
iralu_n
CLK
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
mpassm_n
pdldrive_n
spcdrive_n
mfdrive_n
--- {M & A mem}
CLK
wadr[9:0] hex
madr[4:0] hex
mmem[31:0] hex
mwp_n
aadr[9:0] hex
amem[31:0] hex
awp_n
l[31:0] hex
--- {New Divider}
mf[31:0] hex
lcdrive_n
opcdrive_n
dcdrive
ppdrive_n
pidrive
qdrive
mddrive_n
mpassl_n
vmadrive_n
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
CLK
--- SPC
spcptr[4:0] hex
swp_n
spcnt_n
spush_n
spop_n
spcw[18:0] hex
spco[18:0] hex
spco_latched[18:0] hex
spcdrive_n
spc[18:0] hex
--- PDL
pdlidx[9:0] hex
pdlptr[9:0] hex
pdla[9:0] hex
pwp_n
pdlwrite
pdlwrited
destpdltop_n
destpdl_x_n
destpdl_p_n
destm
--- {VMA memory}
md[31:0] hex
mdclk
mds[31:0] hex
vm0wp_n
mapi[23:8] hex
vm1wp_n
wmap
wmapd
vma[31:0] hex
vmas[31:0] hex
ob[31:0] hex
--- IRAM
pc[13:0] octal
iwr[48:0] hex
iwe_n
--- {Dispatch mem}
md[31:0] hex
dwe_n
dadr_n[10:0] hex
dmask[6:0] hex
r[31:0] hex
lpc octal
--- {New Divider}
pgf_or_int
pgf_or_int_or_sb
pfr_n
pfw_n
lvmo_n
pma hex
vmem1_adr hex
vmo hex
vmaok_n
sint
sintr
int
--- {Bus Interface}
wmap_n
memrd_n
memwr_n
destmem_n
memop_n
memstart
memrq
memprepare
memack_n
mfinish_n
mfinishd_n
rdfinish_n
wait_n
memgrant_n
mbusy
use_md
wmap
wmapd
rdcyc
wrcyc
vmo hex
pma hex
loadmd
mdsel
memdrive_n
md[31:0] hex
EOF

echo " </traces>"
echo "</config>"
exit 0
