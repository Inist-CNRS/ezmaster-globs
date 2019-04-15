#!/bin/sh

# inject config.json parameters to env
# only if not already defined in env
export DUMP_EACH_NBMINUTES="${DUMP_EACH_NBMINUTES:="$(jq -r -M '.DUMP_EACH_NBMINUTES | select (.!=null)' /config.json)"}"
export DUMP_TO="${DUMP_TO:="$(jq -r -M '.DUMP_TO | .[] | select (.!=null)' /config.json)"}"
export GITHUB_ORGANIZATIONS="${GITHUB_ORGANIZATIONS:="$(jq -r -M '.GITHUB_ORGANIZATIONS | .[] | select (.!=null)' /config.json)"}"
export GITHUB_PERSONAL_ACCESS_TOKEN="${GITHUB_PERSONAL_ACCESS_TOKEN:="$(jq -r -M '.GITHUB_PERSONAL_ACCESS_TOKEN | select (.!=null)' /config.json)"}"
export GITLAB_HTTP_BASEURL="${GITLAB_HTTP_BASEURL:="$(jq -r -M '.GITLAB_HTTP_BASEURL | select (.!=null)' /config.json)"}"
export GITLAB_SSH_BASEURL="${GITLAB_SSH_BASEURL:="$(jq -r -M '.GITLAB_SSH_BASEURL | select (.!=null)' /config.json)"}"
export GITLAB_PERSONAL_ACCESS_TOKEN="${GITLAB_PERSONAL_ACCESS_TOKEN:="$(jq -r -M '.GITLAB_PERSONAL_ACCESS_TOKEN | select (.!=null)' /config.json)"}"
export GITLAB_GROUP_PREFIX="${GITLAB_GROUP_PREFIX:="$(jq -r -M '.GITLAB_GROUP_PREFIX | select (.!=null)' /config.json)"}"

echo "Used parameters:"
echo "----------------"
env | grep -E "DUMP|GITHUB|GITLAB" \
    | sed 's#GITHUB_PERSONAL_ACCESS_TOKEN=\(.*\)#GITHUB_PERSONAL_ACCESS_TOKEN=xxx#g' \
    | sed 's#GITLAB_PERSONAL_ACCESS_TOKEN=\(.*\)#GITLAB_PERSONAL_ACCESS_TOKEN=yyy#g'
echo "----------------"

/dump-github.periodically.sh &

# exec the CMD (see Dockerfile)
exec "$@"