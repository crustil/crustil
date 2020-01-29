#!/usr/bin/env bash

pom_path="./"
pom_name="pom.xml"
git_path_output="../"
ssh_prefix="ssh://git@gitlab.cloudvector.fr:10022"
git_repository_path="micro-service/rx"

if [[ " $@ " =~ --pom-path=([^' ']+) ]]; then
  echo "+ set pom path"
  pom_path=${BASH_REMATCH[1]}
fi

if [[ " $@ " =~ --pom-name=([^' ']+) ]]; then
  echo "+ set pom name"
  pom_name=${BASH_REMATCH[1]}
fi

if [[ " $@ " =~ --git-output=([^' ']+) ]]; then
  echo "+ set git output"
  # todo check if pom path parent exist !
  git_path_output=${BASH_REMATCH[1]}
fi

modules=$(grep -oP '.*\K(?<=>).*(?=<\/module)' pom.xml)
modules=${modules//..\//}

cmd() {
  for item in $modules; do
    echo "-> git $1 on $item"
    # check if item exist before action
    cd $git_path_output/$item
    git $1
  done
}

clone() {
  cd $git_path_output
  for item in $modules; do
    echo "-> git clone on $item"
    git clone ${ssh_prefix}/${git_repository_path}/${item}.git
  done
}

if [[ " $@ " == *" --clone "* ]]; then
  clone
fi

if [[ " $@ " == *" --pull "* ]]; then
  cmd pull
fi

# grep -oP '.*\K(?<=>).*(?=<\/)' pom.xml
