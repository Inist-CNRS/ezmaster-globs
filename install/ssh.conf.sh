#!/usr/bin/env bash
################################################################################
#
# GLoBS / install / ssh.conf.sh
# 
# Configuration du service SSH pour GLoBS
#
# @author : INIST-CNRS/DPI
#
################################################################################

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
CURDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LIBSDIR="$(readlink -f "$CURDIR/../libs")"
INSTALLDIR="$(readlink -f "$CURDIR/../install")"

source "$LIBSDIR/ansicolors.rc"
source "$LIBSDIR/libs/std.rc"

