#!/bin/bash


function get_github_clone_urls() {
  # loop over all the github organization pages to be sure to have all the
  # repositories of this organization.
  # this loop uses the github v3 API
  GITHUB_CLONE_URLS=""
  PAGE=1
  GITHUB_CU_PAGE="."
  while [ "$GITHUB_CU_PAGE" != "" ]
  do
    if [ "$GITHUB_OAUTH_TOKEN" != "" ]; then
      CURL_HEADER_GITHUB_AUTH="Authorization: token ${GITHUB_OAUTH_TOKEN}"
    fi
    GITHUB_CU_PAGE=$(curl -s -H "${CURL_HEADER_GITHUB_AUTH}" -H "Accept: application/vnd.github.v3+json" https://api.github.com/orgs/${GITHUB_ORGANIZATION}/repos?page=${PAGE} | jq -r '.[].clone_url')
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

}


function do_github_clones() {


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


}