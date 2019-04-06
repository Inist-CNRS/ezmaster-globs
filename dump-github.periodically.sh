#!/bin/bash
# script looping indefinitly and doing each X hours
# a github backup into /usr/local/apache2/htdocs/ folder

. /github-functions.sh

# loop forever but wait $DUMP_EACH_NBMINUTES between each loops 
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
    get_github_clone_urls
    do_github_clones


    # update the full organization size for the HTML view
    du -sh /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION | awk '{ print $1 }' > /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/GITHUB_ORGANIZATION_SIZE.txt
    # update the organization repositories list for the HTML view
    cd /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/ && ls -d */ > /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/GITHUB_ORGANIZATION_CONTENT.txt


  done # GITHUB_ORGANIZATIONS loop

  echo "-> Waiting $DUMP_EACH_NBMINUTES minutes before next dump."
  sleep ${DUMP_EACH_NBMINUTES}m
done
