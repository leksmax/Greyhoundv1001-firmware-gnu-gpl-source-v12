#!/bin/sh

TYPE=$1


case "$TYPE" in
'0')
echo "*** Set to Normal Mode ****"
OPMODE=0
    ;;
'1')
echo "*** Set to Developer Mode 1 ****"
OPMODE=1
    ;;
'2')
echo "*** Set to Developer Mode 2 ****"
OPMODE=2
    ;;
'3')
echo "*** Set to Factory Mode  ****"
OPMODE=3
    ;;
'r')
echo "*** Read Operation Mode  ****"
DO_READ=1
    ;;
*)
echo "Usage $0 type"
echo "type :"
echo "     0:Set to Normal Mode"
echo "     1:Set to Normal Operation with Debug Messages"
echo "     2:Set to Developer Mode 2"
echo "     3:Set to Factory Mode"
echo "     r:Read Operation Mode"
exit 1;
    ;;
esac


if test $TYPE = "r" ; then
setconfig -g 5;
exit 1;
fi


setconfig -a 1
setconfig -a 2 -s 5 -d $OPMODE;
setconfig -a 5;
rm -rf /var/uboot_config
echo "Finished."
