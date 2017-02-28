#!/usr/bin/env bash
################################################################################
#
# GLoBS / install / cron.conf.sh
# 
# Configuration du CRON pour GLoBS
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

GLoBS_HOME="/home/globs"
GLoBS_BINS="/home/globs/bin"

mkdir -p "$GLoBS_BINS"
cp "$INSTALLDIR/globs.cron.sh" "$GLoBS_BINS"
chmod +x "GLoBS_BINS/globs.cron.sh"
chown globs:globs "GLoBS_BINS/globs.cron.sh"


