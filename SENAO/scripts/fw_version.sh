#!/bin/bash

TOP="$1"
TARGET="$2"
VERSION_CONFIG="$TOP/SENAO/configs/version_config"

if [ ! -e $VERSION_CONFIG ]; then
	echo ""
	echo ""
	echo "$VERSION_CONFIG not exist !!"
	echo ""
	echo ""
	exit
fi

MAJOR_VERSION="$(cat $VERSION_CONFIG | grep MAJOR_VERSION | sed 's/^.*=//g')"
MINOR_VERSION="$(cat $VERSION_CONFIG | grep MINOR_VERSION | sed 's/^.*=//g')"
RELEASE_VERSION="$(cat $VERSION_CONFIG | grep RELEASE_VERSION | sed 's/^.*=//g')"
BUILD_VERSION="$(cat $VERSION_CONFIG | grep BUILD_VERSION | sed 's/^.*=//g')"

BUILD_DATE="$(date +"%Y-%m-%d")"
BANNER="************************************************************************"

echo -e "$MAJOR_VERSION.$MINOR_VERSION.$RELEASE_VERSION \n$BANNER\nFirmware Version : $MAJOR_VERSION.$MINOR_VERSION.$RELEASE_VERSION.$BUILD_VERSION		Build Date : ${BUILD_DATE}\n$BANNER\n" > $TARGET
