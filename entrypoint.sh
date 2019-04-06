#!/bin/sh -eux

# inject config.json parameters to env
# only if not already defined in env
export DUMP_EACH_NBMINUTES="${DUMP_EACH_NBMINUTES:="$(jq -r -M .DUMP_EACH_NBMINUTES /config.json | grep -v null)"}"
export GITHUB_ORGANIZATIONS="${GITHUB_ORGANIZATIONS:="$(jq -r -M '.GITHUB_ORGANIZATIONS | .[]' /config.json | grep -v null)"}"
export GITHUB_OAUTH_TOKEN="${GITHUB_OAUTH_TOKEN:="$(jq -r -M '.GITHUB_OAUTH_TOKEN | .[]' /config.json | grep -v null)"}"

/dump-github.periodically.sh &

# exec the CMD (see Dockerfile)
exec "$@"