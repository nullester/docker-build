#!/usr/bin/env bash

if [[ $( which realpath | wc -l ) -eq 0 ]]; then
    realpath() {
        local _FILE="$1"
        if [[ "$_FILE" == "" ]]; then
            echo "realpath: missing operand"
            exit 1
        fi
        echo "$( pwd )/${_FILE}"
    }
fi

echo -e "Updating \033[032mbuild\033[0m..."
git checkout master && git pull
echo -e "\033[032mdone\033[0m"

V_ROOT=$( dirname $( realpath "$0" ) )
V_PWD="$( pwd )"

_IFS=$IFS
IFS=$'\n'
for V_DIR in $V_ROOT/*; do
    if [[ -f "$V_DIR/Dockerfile" && -d "$V_DIR/.git" ]]; then
        cd "$VDIR"
        echo -e "Updating \033[032m$( basename "$V_DIR" )\033[0m..."
        git checkout master && git pull
        echo -e "\033[032mdone\033[0m"
        cd "$V_PWD"
    fi
done
IFS=$_IFS
