#!/bin/bash



function create_or_update_gitlab_group() {

  GITLAB_GROUP_NAME=$GITLAB_GROUP_PREFIX$GITHUB_ORGANIZATION
  GITLAB_GROUP_DESC=$GITHUB_ORGA_DESC
  GITLAB_GROUP_AVATAR_URL=$GITHUB_ORGA_AVATAR_URL # gitlab API does not support it yet

  # check the $GITLAB_GROUP_NAME exists or not
  # create it if necessary and update its description
  # https://docs.gitlab.com/ee/api/groups.html#details-of-a-group
  GITLAB_GROUP_EXISTS=$(curl -s -H "Private-Token: $GITLAB_PERSONAL_ACCESS_TOKEN" -o /dev/null -s -w "%{http_code}\n" -X GET $GITLAB_HTTP_BASEURL/api/v4/groups/$GITLAB_GROUP_NAME)
  if [ "$GITLAB_GROUP_EXISTS" == "404" ]; then
    echo "-> Gitlab $GITLAB_GROUP_NAME group does not exists, create it !"
    # https://docs.gitlab.com/ee/api/groups.html#new-group
    curl -s --header "Private-Token: $GITLAB_PERSONAL_ACCESS_TOKEN" -X POST \
       --form "name=$GITLAB_GROUP_NAME" \
       --form "path=$GITLAB_GROUP_NAME" \
       --form "description=$GITLAB_GROUP_DESC (backup de $GITHUB_ORGA_URL)" \
       --form "visibility=public" \
       --form "avatar_url=$GITLAB_GROUP_AVATAR_URL" \
       $GITLAB_HTTP_BASEURL/api/v4/groups
  fi
  # update the gitlab group properties (name, description, visibility...)
  # https://docs.gitlab.com/ee/api/groups.html#update-group
  curl -s --header "Private-Token: $GITLAB_PERSONAL_ACCESS_TOKEN" -X PUT \
     --form "name=$GITLAB_GROUP_NAME" \
     --form "description=$GITLAB_GROUP_DESC (backup de $GITHUB_ORGA_URL)" \
     --form "visibility=public" \
     --form "avatar_url=$GITLAB_GROUP_AVATAR_URL" \
     $GITLAB_HTTP_BASEURLapi/v4/groups/$GITLAB_GROUP_NAME \
     >/usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/GITLAB_GROUP_INFO.json
  GITLAB_GROUP_ID=$(jq -r .id /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/GITLAB_GROUP_INFO.json)
}

function create_or_update_gitlab_projects() {


  for GITLAB_PROJECT_NAME in $GITHUB_REPOS_NAMES
  do

    GITHUB_CU=$(cat /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/$GITLAB_PROJECT_NAME.cu.txt)
    GITHUB_DESC=$(cat /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/$GITLAB_PROJECT_NAME.desc.txt)
    GITHUB_DESC=$([ "$GITHUB_DESC" = "null" ] && echo "" || echo $GITHUB_DESC)
    GITHUB_HOME=$(cat /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/$GITLAB_PROJECT_NAME.home.txt)
    GITHUB_HOME=$([ "$GITHUB_HOME" = "null" ] && echo "" || echo $GITHUB_HOME)
    GITHUB_URL=$(cat /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/$GITLAB_PROJECT_NAME.url.txt)
    GITHUB_URL=$([ "$GITHUB_URL" = "null" ] && echo "" || echo $GITHUB_URL)

    # check the $GITLAB_PROJECT_NAME exists or not
    # create it if necessary and update its description 
    # https://docs.gitlab.com/ee/api/projects.html#create-project
    GITLAB_PROJECT_EXISTS=$(curl -s -H "Private-Token: $GITLAB_PERSONAL_ACCESS_TOKEN" -o /dev/null -s -w "%{http_code}\n" -X GET $GITLAB_HTTP_BASEURL/api/v4/projects/${GITLAB_GROUP_NAME}%2F${GITLAB_PROJECT_NAME})
    if [ "$GITLAB_PROJECT_EXISTS" == "404" ]; then
      echo "-> Gitlab $GITLAB_GROUP_NAME/$GITLAB_PROJECT_NAME project does not exists, create it !"
      curl -s --header "Private-Token: $GITLAB_PERSONAL_ACCESS_TOKEN" -X POST \
           --form "namespace_id=$GITLAB_GROUP_ID" \
           --form "name=$GITLAB_PROJECT_NAME" \
           --form "path=$GITLAB_PROJECT_NAME" \
           --form "description=$GITHUB_DESC $GITHUB_HOME (backup de $GITHUB_URL)" \
           --form "visibility=public" \
           --form "archived=true" \
           --form "merge_requests_enabled=false" \
           --form "issues_enabled=false" \
           --form "wiki_enabled=false" \
           --form "snippets_enabled=false" \
           --form "jobs_enabled=false" \
           $GITLAB_HTTP_BASEURL/api/v4/projects
    fi
    # update the gitlab project properties
    LOCAL_CLONE_FOLDER=$(basename $GITHUB_CU)
    curl -s --header "Private-Token: $GITLAB_PERSONAL_ACCESS_TOKEN" -X PUT \
         --form "namespace_id=$GITLAB_GROUP_ID" \
         --form "name=$GITLAB_PROJECT_NAME" \
         --form "description=$GITHUB_DESC $GITHUB_HOME (backup de $GITHUB_URL)" \
         --form "visibility=public" \
         --form "archived=true" \
         --form "merge_requests_enabled=false" \
         --form "issues_enabled=false" \
         --form "wiki_enabled=false" \
         --form "snippets_enabled=false" \
         --form "jobs_enabled=false" \
         $GITLAB_HTTP_BASEURL/api/v4/projects/${GITLAB_GROUP_NAME}%2F${GITLAB_PROJECT_NAME} \
         >/usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/$LOCAL_CLONE_FOLDER/GITLAB_PROJECT_INFO.json

    # archive the gitlab project (make it readonly)
    curl -s --header "Private-Token: $GITLAB_PERSONAL_ACCESS_TOKEN" -X POST \
      $GITLAB_HTTP_BASEURL/api/v4/projects/${GITLAB_GROUP_NAME}%2F${GITLAB_PROJECT_NAME}/archive >/dev/null

  done # $GITHUB_REPOS_NAMES loop

}

function create_ssh_key_for_gitlab_push() {

  echo -n "-> Creating or updating deploy keys on gitlab projects"

  # generate a totally new ssh key
  # this key will be used to push/mirror on the gitlab repositories
  # thanks to the git command
  rm -f ~/.ssh/*
  ssh-keygen -t rsa -f ~/.ssh/id_rsa -q -P ""
  echo "StrictHostKeyChecking no" > ~/.ssh/config
  echo -n "."

  for GITLAB_PROJECT_NAME in $GITHUB_REPOS_NAMES
  do

    # delete the old deploy key
    GITLAB_DEPLOY_KEY_ID=$(curl -s --header "Private-Token: $GITLAB_PERSONAL_ACCESS_TOKEN" -X GET \
      $GITLAB_HTTP_BASEURL/api/v4/projects/$GITLAB_GROUP_NAME%2F$GITLAB_PROJECT_NAME/deploy_keys/ \
      | jq -r ".[] | select(.title == \"$GITLAB_GROUP_NAME\") | .id | select (.!=null)")
    if [ "$GITLAB_DEPLOY_KEY_ID" != "" ]; then
      curl -s --header "Private-Token: $GITLAB_PERSONAL_ACCESS_TOKEN" -X DELETE \
        $GITLAB_HTTP_BASEURL/api/v4/projects/$GITLAB_GROUP_NAME%2F$GITLAB_PROJECT_NAME/deploy_keys/$GITLAB_DEPLOY_KEY_ID
    fi
    echo -n "."

    # and create a totally new deploy key 
    curl -s --header "Private-Token: $GITLAB_PERSONAL_ACCESS_TOKEN" -X POST \
      --form "can_push=true" \
      --form "key=$(cat ~/.ssh/id_rsa.pub)" \
      --form "title=$GITLAB_GROUP_NAME" \
      $GITLAB_HTTP_BASEURL/api/v4/projects/$GITLAB_GROUP_NAME%2F$GITLAB_PROJECT_NAME/deploy_keys/ >/dev/null
    echo -n "."

  done
  echo ""
}

function do_gitlab_mirrors() {

  # all the repositories are clonned locally
  # we have to add remote gitlab repository
  # and push/mirror to it
  for GITLAB_PROJECT_NAME in $GITHUB_REPOS_NAMES
  do
    echo "-> Mirror $GITHUB_CU to $GITLAB_SSH_BASEURL:$GITLAB_GROUP_NAME/$LOCAL_CLONE_FOLDER"
    
    GITHUB_CU=$(cat /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/$GITLAB_PROJECT_NAME.cu.txt)
    LOCAL_CLONE_FOLDER=$(basename $GITHUB_CU)
    cd /usr/local/apache2/htdocs/$GITHUB_ORGANIZATION/$LOCAL_CLONE_FOLDER
    git push --mirror $GITLAB_SSH_BASEURL:$GITLAB_GROUP_NAME/$LOCAL_CLONE_FOLDER

  done # $GITHUB_REPOS_NAMES loop

}