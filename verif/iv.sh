#!/bin/sh

iverilog -I../rtl run.v
#vvp -M../pli/ide -mpli_ide ./a.out >xx2 &

