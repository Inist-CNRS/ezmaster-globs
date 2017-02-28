#!/usr/bin/env bash
################################################################################
#
# GLoBS / install / git.conf.sh
# 
# Configuration du service GIT pour GLoBS
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

GIT_SHELL=$(which git-shell)

# ------------------------------------------------------------------------------
# Création de l'utilisateur GIT
# ------------------------------------------------------------------------------
adduser --disabled-password --shell "$GIT_SHELL" --gecos "" --quiet git
su git
cd /home/git
mkdir .ssh

# Ajout des clefs publiques disponibles pour permettre l'accès via SSH
find "$INSTALLDIR" -type f -name "*.pub" -exec cat "{}" >> /home/git/.ssh/authorized_keys \;

