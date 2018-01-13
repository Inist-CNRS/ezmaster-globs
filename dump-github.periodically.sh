#!/bin/bash
# script looping indefinitly and doing each X hours
# a github backup into /usr/local/apache2/htdocs/ folder

while true
do


  # cleanup the dereferenced (config.json) github organizations
  rm -f /tmp/GITHUB_ORGANIZATION_NEW && touch /tmp/GITHUB_ORGANIZATION_NEW
  rm -f /tmp/GITHUB_ORGANIZATION_OLD && touch /tmp/GITHUB_ORGANIZATION_OLD
  for GITHUB_ORGANIZATION in $GITHUB_ORGANIZATIONS
  do
    echo $GITHUB_ORGANIZATION >> /tmp/GITHUB_ORGANIZATION_NEW
  done
  for GITHUB_ORGANIZATION in $(ls /usr/local/apache2/htdocs/)
  do
    echo $GITHUB_ORGANIZATION >> /tmp/GITHUB_ORGANIZATION_OLD
  done
  # to understand comm -23
  # see https://stackoverflow.com/questions/11165182/bash-difference-between-two-lists
  for GITHUB_ORGANIZATION_TOCLEAN in $(comm -23 <(sort /tmp/GITHUB_ORGANIZATION_OLD) <(sort /tmp/GITHUB_ORGANIZATION_NEW))
  do
    echo "-> Cleaning old github organization $GITHUB_ORGANIZATION_TOCLEAN [taille = $(du -sh /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION_TOCLEAN | awk '{ print $1 }')]"
    rm -rf /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION_TOCLEAN
  done




  # loop over all the organization repo list 
  # and clone its repositories locally
  for GITHUB_ORGANIZATION in $GITHUB_ORGANIZATIONS
  do

    echo "-> Dumping the $GITHUB_ORGANIZATION github organization"
    mkdir -p /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/

    GITHUB_CLONE_URLS=$(curl -s -H "Accept: application/vnd.github.v3+json" https://api.github.com/orgs/${GITHUB_ORGANIZATION}/repos | jq -r '.[].clone_url')
    if [ "$GITHUB_CLONE_URLS" == "[]" ]; then
      GITHUB_CLONE_URLS=$(cat /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/GITHUB_CLONE_URLS.cache)
    else
      echo $GITHUB_CLONE_URLS > /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/GITHUB_CLONE_URLS.cache
    fi

    for GITHUB_CLONE_URL in $GITHUB_CLONE_URLS
    do
      

      cd /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/
      GITHUB_CLONE_FOLDER=$(basename $GITHUB_CLONE_URL)    
      if [ ! -d $GITHUB_CLONE_FOLDER ]; then
        echo "-> Dumping a new github repository: $GITHUB_CLONE_URL"
        git clone -q --bare $GITHUB_CLONE_URL
      fi
      cd $GITHUB_CLONE_FOLDER
      git fetch --all
      git update-server-info
  
      # update the repository size 
      du -sh /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/$GITHUB_CLONE_FOLDER | awk '{ print $1 }' > /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/$GITHUB_CLONE_FOLDER/GITHUB_CLONE_SIZE.txt

    done # GITHUB_CLONE_URLS loop

    # update the full organization size
    du -sh /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION | awk '{ print $1 }' > /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/GITHUB_ORGANIZATION_SIZE.txt
    # update the organization repositories list
    cd /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/ && ls -d */ > /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/GITHUB_ORGANIZATION_CONTENT.txt*

  done # GITHUB_ORGANIZATIONS loop

  echo "Waiting $DUMP_EACH_NBMINUTES minutes before next dump."
  sleep ${DUMP_EACH_NBMINUTES}m
done
