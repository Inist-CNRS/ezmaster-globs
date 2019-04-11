#!/bin/bash


function do_local_cleanup_for_old_github_organizations() {

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

}

function get_github_organization_info() {
  if [ "$GITHUB_OAUTH_TOKEN" != "" ]; then
    CURL_HEADER_GITHUB_AUTH="Authorization: token ${GITHUB_OAUTH_TOKEN}"
  fi
  GITHUB_ORGA_PAGE=$(curl -s -H "${CURL_HEADER_GITHUB_AUTH}" -H "Accept: application/vnd.github.v3+json" https://api.github.com/orgs/${GITHUB_ORGANIZATION})
  GITHUB_ORGA_NAME=$(echo $GITHUB_ORGA_PAGE | jq -r '.name')
  GITHUB_ORGA_DESC=$(echo $GITHUB_ORGA_PAGE | jq -r '.description')
}

function get_github_repositories_info() {
  # loop over all the github organization pages to be sure to have all the
  # repositories of this organization.
  # this loop uses the github v3 API
  GITHUB_REPOS_NAMES=""
  PAGE=1
  GITHUB_NAME_PAGE="."
  while [ "$GITHUB_NAME_PAGE" != "" ]
  do
    if [ "$GITHUB_OAUTH_TOKEN" != "" ]; then
      CURL_HEADER_GITHUB_AUTH="Authorization: token ${GITHUB_OAUTH_TOKEN}"
    fi
    GITHUB_INFO_PAGE=$(curl -s -H "${CURL_HEADER_GITHUB_AUTH}" -H "Accept: application/vnd.github.v3+json" https://api.github.com/orgs/${GITHUB_ORGANIZATION}/repos?page=${PAGE})
    GITHUB_NAME_PAGE=$(echo $GITHUB_INFO_PAGE | jq -r '.[].name')
    for GITHUB_NAME in $GITHUB_NAME_PAGE
    do
      GITHUB_REPOS_NAMES="$GITHUB_REPOS_NAMES $GITHUB_NAME"
      GITHUB_CU=$(echo $GITHUB_INFO_PAGE | jq -r ".[] | select(.name == \"$GITHUB_NAME\") | .clone_url")
      GITHUB_DESC=$(echo $GITHUB_INFO_PAGE | jq -r ".[] | select(.name == \"$GITHUB_NAME\") | .description")
      echo $GITHUB_CU   > /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/$GITHUB_NAME.cu.txt
      echo $GITHUB_DESC > /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/$GITHUB_NAME.desc.txt
    done
    if [ "$GITHUB_NAME_PAGE" != "" ] && [ "$GITHUB_NAME_PAGE" != "[]" ]; then
      PAGE=$(($PAGE + 1))
    else
      # stop looping over pages
      GITHUB_NAME_PAGE=""
    fi
  done

  if [ "$GITHUB_REPOS_NAMES" == "" ]; then
    GITHUB_REPOS_NAMES=$(cat /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/GITHUB_REPOS_NAMES.txt)
  else
    echo $GITHUB_REPOS_NAMES > /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/GITHUB_REPOS_NAMES.txt
  fi

}


function do_github_clones() {


  # we now have all the github repositories to clone/fetch locally so do it now!
  for GITHUB_REPOS_NAME in $GITHUB_REPOS_NAMES
  do

    cd /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/
    GITHUB_CLONE_URL=$(cat $GITHUB_REPOS_NAME.cu.txt)
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

  done # GITHUB_REPOS_NAMES loop


}