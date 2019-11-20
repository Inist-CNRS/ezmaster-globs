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
  if [ "$GITHUB_PERSONAL_ACCESS_TOKEN" != "" ]; then
    CURL_HEADER_GITHUB_AUTH="Authorization: token ${GITHUB_PERSONAL_ACCESS_TOKEN}"
  fi
  GITHUB_ORGA_PAGE=$(curl -s -S -H "${CURL_HEADER_GITHUB_AUTH}" -H "Accept: application/vnd.github.v3+json" https://api.github.com/orgs/${GITHUB_ORGANIZATION})
  #echo $GITHUB_ORGA_PAGE | jq .
  GITHUB_ORGA_NAME=$(echo $GITHUB_ORGA_PAGE | jq -r '.name')
  GITHUB_ORGA_DESC=$(echo $GITHUB_ORGA_PAGE | jq -r '.description')
  GITHUB_ORGA_URL=$(echo $GITHUB_ORGA_PAGE | jq -r '.html_url')
  GITHUB_ORGA_AVATAR_URL=$(echo $GITHUB_ORGA_PAGE | jq -r '.avatar_url')
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
    if [ "$GITHUB_PERSONAL_ACCESS_TOKEN" != "" ]; then
      CURL_HEADER_GITHUB_AUTH="Authorization: token ${GITHUB_PERSONAL_ACCESS_TOKEN}"
    fi
    GITHUB_INFO_PAGE=$(curl -s -S -H "${CURL_HEADER_GITHUB_AUTH}" -H "Accept: application/vnd.github.v3+json" https://api.github.com/orgs/${GITHUB_ORGANIZATION}/repos?page=${PAGE})
    GITHUB_NAME_PAGE=$(echo $GITHUB_INFO_PAGE | jq -r '.[].name')
    for GITHUB_NAME in $GITHUB_NAME_PAGE
    do
      #echo $GITHUB_INFO_PAGE | jq -r ".[] | select(.name == \"$GITHUB_NAME\")"
      GITHUB_REPOS_NAMES="$GITHUB_REPOS_NAMES $GITHUB_NAME"
      GITHUB_CU=$(echo $GITHUB_INFO_PAGE | jq -r ".[] | select(.name == \"$GITHUB_NAME\") | .clone_url")
      GITHUB_DESC=$(echo $GITHUB_INFO_PAGE | jq -r ".[] | select(.name == \"$GITHUB_NAME\") | .description")
      GITHUB_HOME=$(echo $GITHUB_INFO_PAGE | jq -r ".[] | select(.name == \"$GITHUB_NAME\") | .homepage")
      GITHUB_URL=$(echo $GITHUB_INFO_PAGE | jq -r ".[] | select(.name == \"$GITHUB_NAME\") | .html_url")

      # fill the GITHUB_HAS_WIKI parameter
      # Notice: the following "has_wiki" attribute comming from the GitHub API is not reliable
      #         because the wiki feature is enabled or disabled from the Github parameters and is enabled by default
      #         So this attribute is "true" event if the wiki is empty.
      # GITHUB_HAS_WIKI=$(echo $GITHUB_INFO_PAGE | jq -r ".[] | select(.name == \"$GITHUB_NAME\") | .has_wiki")
      GITHUB_CLONE_WIKI_URL=$(echo $GITHUB_CU | sed 's#.git$#.wiki.git#g')
      TMP_GIT_CLONE=$(mktemp -u -d)
      git clone --quiet --depth 1 $GITHUB_CLONE_WIKI_URL $TMP_GIT_CLONE 2>/dev/null
      GITHUB_HAS_WIKI=$([[ $? != 0 ]] && echo "false" || echo "true")
      rm -rf $TMP_GIT_CLONE

      echo $GITHUB_CU   > /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/$GITHUB_NAME.cu.txt
      echo $GITHUB_DESC > /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/$GITHUB_NAME.desc.txt
      echo $GITHUB_HOME > /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/$GITHUB_NAME.home.txt
      echo $GITHUB_URL > /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/$GITHUB_NAME.url.txt
      echo $GITHUB_HAS_WIKI > /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/$GITHUB_NAME.has_wiki.txt
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


function do_local_mirrors() {


  # we now have all the github repositories to clone/fetch locally so do it now!
  for GITHUB_REPOS_NAME in $GITHUB_REPOS_NAMES
  do

    # clone the github repository
    cd /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/
    GITHUB_CLONE_URL=$(cat $GITHUB_REPOS_NAME.cu.txt)
    GITHUB_HAS_WIKI=$(cat $GITHUB_REPOS_NAME.has_wiki.txt)
    LOCAL_CLONE_FOLDER=$(basename $GITHUB_CLONE_URL)
    if [ ! -d $LOCAL_CLONE_FOLDER ]; then
      echo "-> Dumping a new github repository: $GITHUB_CLONE_URL"
      git clone -q --mirror $GITHUB_CLONE_URL
      cd $LOCAL_CLONE_FOLDER
      git update-server-info
    else
      echo "-> Fetching new data from github repository: $GITHUB_CLONE_URL"
      cd $LOCAL_CLONE_FOLDER
      git fetch --all
      git update-server-info
    fi
    # update the repository size 
    du -sh /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/$LOCAL_CLONE_FOLDER | awk '{ print $1 }' > /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/$LOCAL_CLONE_FOLDER/GITHUB_CLONE_SIZE.txt

    # clone the wiki repository if necessary
    cd /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/
    if [ $GITHUB_HAS_WIKI == "true" ]; then
      GITHUB_CLONE_WIKI_URL=$(echo $GITHUB_CLONE_URL | sed 's#.git$#.wiki.git#g')
      LOCAL_CLONE_WIKI_FOLDER=$(basename $GITHUB_CLONE_WIKI_URL)
      if [ ! -d $LOCAL_CLONE_WIKI_FOLDER ]; then
        echo "-> Dumping a new github wiki repository: $GITHUB_CLONE_WIKI_URL"
        git clone -q --mirror $GITHUB_CLONE_WIKI_URL
        cd $LOCAL_CLONE_WIKI_FOLDER
        git update-server-info
      else
        echo "-> Fetching new data from github wiki repository: $GITHUB_CLONE_WIKI_URL"
        cd $LOCAL_CLONE_WIKI_FOLDER
        git fetch --all
        git update-server-info
      fi
      cd /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/
      # update the repository size (wiki included)
      du -csh /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/$LOCAL_CLONE_FOLDER /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/$LOCAL_CLONE_WIKI_FOLDER | tail -1 | awk '{ print $1 }' > /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/$LOCAL_CLONE_WIKI_FOLDER/GITHUB_CLONE_SIZE.txt
    fi

  done # GITHUB_REPOS_NAMES loop


}