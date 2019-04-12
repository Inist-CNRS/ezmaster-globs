#!/bin/bash


# function do_gitlab_cleanup_for_old_github_organizations() {
# 
# # TODO
#   for repository_to_cleanup in $*
#   do
#     echo "COUCOUCOU $repository_to_cleanup"
#   done
# 
#   for GITHUB_ORGANIZATION_TOCLEAN in $*
#   do
#     # TODO : tester si le group gitlab existe
#     echo "-> Cleaning old gitlab group $GITHUB_ORGANIZATION_TOCLEAN"
#     # TODO appel api pour supprimer
#   done
# 
# }

function create_or_update_gitlab_group() {

  GITLAB_GROUP_NAME=$GITHUB_ORGANIZATION
  GITLAB_GROUP_DESC=$GITHUB_ORGA_DESC
  GITLAB_GROUP_AVATAR_URL=$GITHUB_ORGA_AVATAR_URL # gitlab API does not support it yet

  # check the $GITLAB_GROUP_NAME exists or not
  # create it if necessary and update its description
  # https://docs.gitlab.com/ee/api/groups.html#details-of-a-group
  GITLAB_GROUP_EXISTS=$(curl -s -H "Private-Token: $GITLAB_PERSONAL_ACCESS_TOKEN" -o /dev/null -s -w "%{http_code}\n" -X GET https://git.abes.fr/api/v4/groups/$GITLAB_GROUP_PREFIX$GITLAB_GROUP_NAME)
  if [ "$GITLAB_GROUP_EXISTS" == "404" ]; then
    echo "-> Gitlab $GITLAB_GROUP_NAME group does not exists, create it !"
    # https://docs.gitlab.com/ee/api/groups.html#new-group
    curl -s --header "Private-Token: $GITLAB_PERSONAL_ACCESS_TOKEN" -X POST \
       --form "name=$GITLAB_GROUP_PREFIX$GITLAB_GROUP_NAME" \
       --form "path=$GITLAB_GROUP_PREFIX$GITLAB_GROUP_NAME" \
       --form "description=$GITLAB_GROUP_DESC (backup de $GITHUB_ORGA_URL)" \
       --form "visibility=public" \
       --form "avatar_url=$GITLAB_GROUP_AVATAR_URL" \
       "https://git.abes.fr/api/v4/groups"
  fi
  # update the gitlab group properties (name, description, visibility)
  # https://docs.gitlab.com/ee/api/groups.html#update-group
  curl -s --header "Private-Token: $GITLAB_PERSONAL_ACCESS_TOKEN" -X PUT \
     --form "name=$GITLAB_GROUP_PREFIX$GITLAB_GROUP_NAME" \
     --form "description=$GITLAB_GROUP_DESC (backup de $GITHUB_ORGA_URL)" \
     --form "visibility=public" \
     --form "avatar_url=$GITLAB_GROUP_AVATAR_URL" \
     "https://git.abes.fr/api/v4/groups/$GITLAB_GROUP_PREFIX$GITLAB_GROUP_NAME" >/dev/null

}

function create_or_update_gitlab_projects() {

  for GITLAB_PROJECT_NAME in $GITHUB_REPOS_NAMES
  do

    echo $GITLAB_PROJECT_NAME 
    # TODO check the $GITLAB_PROJECT_NAME exists or not
    # create it if necessary and update its description 

  done # $GITHUB_REPOS_NAMES loop


}

function do_gitlab_mirrors() {

  # all the repositories are clonned locally
  # we have to add remote gitlab repository
  # and push/mirror to it
  for GITLAB_PROJECT_NAME in $GITHUB_REPOS_NAMES
  do

    echo $GITLAB_PROJECT_NAME 

  done # $GITHUB_REPOS_NAMES loop


}