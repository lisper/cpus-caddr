transcript on
if {[file exists rtl_work]} {
  vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

#
transcript file "log"

#
vlog ../rtl/fast_ram_controller.v
vlog test_fast.v

noview wave

#vsim -novopt test
#vsim -voptargs="+acc=rnp" -pli ../pli/rk/pli_rk.dll test
vsim -voptargs="+acc=rnp" test
do wave.do

run 1000ns
