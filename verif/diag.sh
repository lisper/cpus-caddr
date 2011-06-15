#!/bin/sh

#
# run all the mini microcode diags in ../utils/diags
#
# this (should) make a reasonable regression test before
# attempting to boot
#

#CLOCK_ARG="+c1"
CLOCK_ARG="+c0"

function run_test
{
    tmp/Vtest +p +f +w $CLOCK_ARG +l $1 2>&1 >/dev/null 
    return $?
}

ls ../utils/diags/*.o | \
(while read f; do
    if run_test $f; then
	echo $f - OK;
    else
	if [ `basename $f` == "failure.o" ]; then
	    echo "$f - (ok; should fail)"
	else
	    echo $f - FAILED;
	    exit 1
	fi
    fi
done)

err=$?

if [ "$err" == "0" ]; then
    echo SUCCESS
    exit 0
else
    echo FAILURE!
    exit 1
fi





