#!/usr/bin/env bash
################################################################################
#
# GLoBS / install / globs.cron.sh
# 
# Tâche de récupération des dépôts git lancée par le cron.
# À installer dans le cron du user « globs »
#
# @author : INIST-CNRS/DPI
#
################################################################################

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
HOME_GIT="/home/git"
LISTE_DEPOTS="/home/globs/bin/repositopries.list"

# ------------------------------------------------------------------------------
# On change le séparateur par défaut pour pouvoir parcourir la liste des dépôts
# qui est écrite "un dépôt par ligne"
# ------------------------------------------------------------------------------
# OLDIFS=$IFS
# IFS=$'\n'

# ------------------------------------------------------------------------------
# Pull global de tous les dépots de la liste...
# ------------------------------------------------------------------------------
find "$HOME_GIT" -maxdepth=1 -type d | parallel --gnu "cd {} && git pull"

# ------------------------------------------------------------------------------
# Clone des dépôts qui ne sont pas encore sur le serveur GLoBS
# ------------------------------------------------------------------------------
while read depot
do
  projectName=$(echo $depot | rev | cut -d "/" -f1 | rev | cut -d "." -f 1)
  if ! find "$HOME_GIT" -type d -name "$projectName" ; then
    cd "$HOME_GIT"
    git clone "$depot"
  fi
done < "$LISTE_DEPOTS"

# ------------------------------------------------------------------------------
# Fin !
# ------------------------------------------------------------------------------
exit 0
