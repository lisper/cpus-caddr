#!/bin/sh

iverilog run.v
vvp -M../pli/ide -mpli_ide ./a.out >xx2 &

