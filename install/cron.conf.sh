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

# Répertoire des scripts du user "globs"
mkdir -p "$GLoBS_BINS"

# Les jobs cron du user "globs" et du root
cp "$INSTALLDIR/globs.cron.sh" "$GLoBS_BINS"
chmod +x "GLoBS_BINS/globs.cron.sh"
cp "$INSTALLDIR/root.cron.sh" "$GLoBS_BINS"
chmod +x "GLoBS_BINS/root.cron.sh"

# Le fichier aved la liste des repositories
cp "$INSTALLDIR/repositories.list" "$GLoBS_BINS"

# Redonner la propriété au user "globs"
chown globs:globs "GLoBS_BINS/"


