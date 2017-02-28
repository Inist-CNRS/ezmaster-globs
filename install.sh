#!/usr/bin/env bash
################################################################################
#
# GLoBS - Git LOcal Backup Server / installation
# 
# Proto d'installeur "câblé" pour GLoBS
#
# /!\ Doit être executé en tant que root
#
# @author : INIST-CNRS/DPI
#
#
################################################################################


# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
GLoBS_INSTALL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$GLoBS_INSTALL_DIR/libs/ansicolors.rc"
source "$GLoBS_INSTALL_DIR/libs/std.rc"

# ------------------------------------------------------------------------------
# Environnement inist
# ------------------------------------------------------------------------------
export http_proxy="$INIST_HTTP_PROXY"
export HTTP_PROXY="$INIST_HTTP_PROXY"
export https_proxy="$INIST_HTTPS_PROXY"
export HTTPS_PROXY="$INIST_HTTPS_PROXY"

# ------------------------------------------------------------------------------
# Màj système
# ------------------------------------------------------------------------------
apt-get update -y
apt-get dist-upgrade -y

# ------------------------------------------------------------------------------
# Installer les dépendances
# ------------------------------------------------------------------------------
for dep in GLoBS_dependencies
do
  if ! apt-get install -y "$dep" ; then
    _globs_std_consoleMessage "ERROR" "Impossible d'installer « $dep ». Fin du script."
    exit $FALSE
  fi
done

# ------------------------------------------------------------------------------
# INIST-TOOLS (ça peut servir)
# ------------------------------------------------------------------------------
wget --output-document=/tmp/inist-tools_latest.deb https://github.com/Inist-CNRS/inist-tools/raw/master/releases/inist-tools_latest.deb 
dpkg -i /tmp/inist-tools_latest.deb
echo -e "\n## INIST-TOOLS ##\nsource /opt/inist-tools/inistrc" >> ~/.bashrc
# Le compte "user" du serveur est « globs »
echo -e "\n## INIST-TOOLS ##\nsource /opt/inist-tools/inistrc" >> /home/globs/.bashrc

# ------------------------------------------------------------------------------
# Configuration des applis
# ------------------------------------------------------------------------------
## SSH
"$GLoBS_INSTALL_DIR/install/ssh.conf.sh"
## GIT
"$GLoBS_INSTALL_DIR/install/git.conf.sh"
## HTTP
"$GLoBS_INSTALL_DIR/install/http.conf.sh"
## CRON
"$GLoBS_INSTALL_DIR/install/cron.conf.sh"

# ------------------------------------------------------------------------------
# FIN !
# ------------------------------------------------------------------------------
exit $TRUE
