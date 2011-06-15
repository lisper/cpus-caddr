#!/bin/sh
#tmp/Vtest +p +f +w +ca
if [ "$1" == "" ]; then
    f="output";
else
    f=$1;
fi
echo "file /$f/"
tmp/Vtest +p +f +w +c1 +l $f

