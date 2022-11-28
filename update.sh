#!/bin/bash

echo && echo -e "Updating \033[032mbuild\033[0m"
git pull

V_ROOT=$( dirname $( realpath "$0" ) )
V_PWD="$( pwd )"

_IFS=$IFS
IFS=$'\n'
for V_DIR in $V_ROOT/*; do
    if [[ -f "$V_DIR/Dockerfile" && -d "$V_DIR/.git" ]]; then
        cd "$VDIR"
        echo && echo -e "Updating \033[032m$( basename "$V_DIR" )\033[0m"
        git pull
        cd "$V_PWD"
    fi
done
IFS=$_IFS
