#!/bin/sh

# debug, for cosim
#tmp/Vtest +c0 +p +d +r +w 

# waves
#tmp/Vtest +w +b37000000

# fpga clocks
#tmp/Vtest +p +c1

# quick test
tmp/Vtest +p +c0
