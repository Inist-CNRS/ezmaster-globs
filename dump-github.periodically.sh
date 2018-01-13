#!/bin/bash
# script looping indefinitly and doing each X hours
# a github backup into /usr/local/apache2/htdocs/ folder

while true
do

  # loop over all the organization repo list
  for GITHUB_ORGANIZATION in $GITHUB_ORGANIZATIONS
  do

    echo "-> Dumping the $GITHUB_ORGANIZATION github organization"
    mkdir -p /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/

    GITHUB_CLONE_URLS=$(curl -s -H "Accept: application/vnd.github.v3+json" https://api.github.com/orgs/${GITHUB_ORGANIZATION}/repos | jq -r '.[].clone_url')
    for GITHUB_CLONE_URL in $GITHUB_CLONE_URLS
    do
      

      cd /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/
      GITHUB_CLONE_FOLDER=$(basename $GITHUB_CLONE_URL)    
      if [ ! -d $GITHUB_CLONE_FOLDER ]; then
        echo "-> Dumping a new github repository: $GITHUB_CLONE_URL"
        git clone --bare $GITHUB_CLONE_URL
      fi
      cd $GITHUB_CLONE_FOLDER
      git fetch -v --all
      git update-server-info


    done # GITHUB_CLONE_URLS loop
  

  done # GITHUB_ORGANIZATIONS loop

  echo "Waiting $DUMP_EACH_NBMINUTES minutes before next dump."
  sleep ${DUMP_EACH_NBMINUTES}m
done
