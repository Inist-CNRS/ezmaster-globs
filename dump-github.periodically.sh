#!/bin/bash
# script looping indefinitly and doing each X hours
# a github backup into /usr/local/apache2/htdocs/ folder


if [ "$GITHUB_OAUTH_TOKEN" != "" ]; then
  CURL_HEADER_GITHUB_AUTH="Authorization: token ${GITHUB_OAUTH_TOKEN}"
fi

echo $CURL_HEADER_GITHUB_AUTH

while true
do


  # cleanup the dereferenced github organizations
  # since this latest script execution (example: when a docker restart is done) 
  rm -f /tmp/GITHUB_ORGANIZATION_NEW && touch /tmp/GITHUB_ORGANIZATION_NEW
  rm -f /tmp/GITHUB_ORGANIZATION_OLD && touch /tmp/GITHUB_ORGANIZATION_OLD
  for GITHUB_ORGANIZATION in $GITHUB_ORGANIZATIONS
  do
    echo $GITHUB_ORGANIZATION >> /tmp/GITHUB_ORGANIZATION_NEW
  done
  cd /usr/local/apache2/htdocs/
  for GITHUB_ORGANIZATION in $(ls -d */ | sed 's#.$##g' | grep -v node_modules)
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


  # create the organization list for the index.html 
  rm -f /usr/local/apache2/htdocs/GITHUB_ORGANIZATIONS.txt && touch /usr/local/apache2/htdocs/GITHUB_ORGANIZATIONS.txt
  for GITHUB_ORGANIZATION in $GITHUB_ORGANIZATIONS
  do
    echo $GITHUB_ORGANIZATION >> /usr/local/apache2/htdocs/GITHUB_ORGANIZATIONS.txt
    mkdir -p /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/
    cp -f /usr/local/apache2/htdocs/index2.html /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/index.html
  done

  # loop over all the organization repo list 
  # and clone its repositories locally
  for GITHUB_ORGANIZATION in $GITHUB_ORGANIZATIONS
  do

    echo "-> Dumping the $GITHUB_ORGANIZATION github organization"

    # loop over all the github organization pages to be sure to have all the
    # repositories of this organization.
    # this loop uses the github v3 API
    GITHUB_CLONE_URLS=""
    PAGE=1
    GITHUB_CU_PAGE="."
    while [ "$GITHUB_CU_PAGE" != "" ]
    do
      GITHUB_CU_PAGE=$(curl -s -H "${CURL_HEADER_GITHUB_AUTH}" -H "Accept: application/vnd.github.v3+json" https://api.github.com/orgs/${GITHUB_ORGANIZATION}/repos?page=${PAGE} | jq -r '.[].clone_url')
      curl -s -H "${CURL_HEADER_GITHUB_AUTH}" -H "Accept: application/vnd.github.v3+json" https://api.github.com/orgs/${GITHUB_ORGANIZATION}/repos?page=${PAGE}
      echo "KKKKKKKKKKKKKKKKKK $GITHUB_CU_PAGE"
      if [ "$GITHUB_CU_PAGE" != "" ] && [ "$GITHUB_CU_PAGE" != "[]" ]; then
        GITHUB_CLONE_URLS="$GITHUB_CLONE_URLS $GITHUB_CU_PAGE"
        PAGE=$(($PAGE + 1))
      else
        # stop looping over pages
        GITHUB_CU_PAGE=""
      fi
    done
    if [ "$GITHUB_CLONE_URLS" == "" ]; then
      GITHUB_CLONE_URLS=$(cat /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/GITHUB_CLONE_URLS.txt)
    else
      echo $GITHUB_CLONE_URLS > /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/GITHUB_CLONE_URLS.txt
    fi



    # we now have all the github repositories to clone/fetch locally so do it now!
    for GITHUB_CLONE_URL in $GITHUB_CLONE_URLS
    do

      cd /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/
      GITHUB_CLONE_FOLDER=$(basename $GITHUB_CLONE_URL)    
      if [ ! -d $GITHUB_CLONE_FOLDER ]; then
        echo "-> Dumping a new github repository: $GITHUB_CLONE_URL"
        git clone -q --bare $GITHUB_CLONE_URL
      else
        echo "-> Fetching new data from github: $GITHUB_CLONE_URL"
        cd $GITHUB_CLONE_FOLDER
        git fetch --all
      fi
      git update-server-info
  
      # update the repository size 
      du -sh /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/$GITHUB_CLONE_FOLDER | awk '{ print $1 }' > /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/$GITHUB_CLONE_FOLDER/GITHUB_CLONE_SIZE.txt

    done # GITHUB_CLONE_URLS loop



    # update the full organization size for the HTML view
    du -sh /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION | awk '{ print $1 }' > /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/GITHUB_ORGANIZATION_SIZE.txt
    # update the organization repositories list for the HTML view
    cd /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/ && ls -d */ > /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/GITHUB_ORGANIZATION_CONTENT.txt


  done # GITHUB_ORGANIZATIONS loop

  echo "-> Waiting $DUMP_EACH_NBMINUTES minutes before next dump."
  sleep ${DUMP_EACH_NBMINUTES}m
done
