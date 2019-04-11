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

  # TODO check the $GITLAB_GROUP_NAME exists or not
  # create it if necessary and update its description

  echo $GITLAB_GROUP_NAME
  echo $GITLAB_GROUP_DESC

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