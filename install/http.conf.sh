#!/usr/bin/env bash
################################################################################
#
# GLoBS / install / http.conf.sh
# 
# Configuration du service HTTP pour GLoBS
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

HTTP_CONF_FILE="/etc/lighttpd/lighttpd.conf"

if [ -f "$HTTP_CONF_FILE" ]; then
  mv "$HTTP_CONF_FILE" "$HTTP_CONF_FILE.backup"
fi

echo "server.document-root = \"/home/globs/git/\"" > "$HTTP_CONF_FILE"
echo "server.port = 800" >> "$HTTP_CONF_FILE"
echo "dir-listing.activate = \"enable\"" >> "$HTTP_CONF_FILE"
echo -e "mimetype.assign = (\n\".html\" => \"text/html\",\n\".txt\" => \"text/plain\",\n\".jpg\" => \"image/jpeg\",\n\".png\" => \"image/png\"\n)" >> "$HTTP_CONF_FILE"

