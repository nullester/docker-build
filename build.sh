#!/bin/bash

if [ $( which docker | wc -l ) -eq 0 ]; then
    echo && echo -e "\033[031merror: \033[032mdocker\033[031m not installed\033[0m"
    exit 1
fi

V_IMAGES=( )
V_MAINTAINER="nullester"
V_CACHE=0
while (( "$#" )); do
    case "$1" in
        --cache)
            V_CACHE=1
            shift
            ;;
        --maintainer|--maintainer=*)
            if [[ "$1" =~ ^[^\=]+\=(.+)$ ]]; then
                V_MAINTAINER="${BASH_REMATCH[1]}"; shift 1
            else
                V_MAINTAINER="$2"; shift 2
            fi
            ;;
        -*|--*=) # unsupported flags
            echo && echo -e "\033[031merror: unsupported flag \033[032m$1\033[0m" >&2
            exit 1
            ;;
        *) # preserve positional arguments
            V_IMAGES+=( "$1" )
            shift
            ;;
    esac
done

V_ROOT=$( dirname $( realpath "$0" ) )

V_NUM_IMAGES=${#V_IMAGES[@]}
if [[ $V_NUM_IMAGES -eq 0 ]]; then
    if [[ -d "${V_ROOT}/ubuntu" ]]; then
        V_IMAGES+=( "ubuntu" )
    fi
    if [[ -d "${V_ROOT}/lap" ]]; then
        V_IMAGES+=( "lap:7.1" )
        V_IMAGES+=( "lap:7.2" )
        V_IMAGES+=( "lap:7.3" )
        V_IMAGES+=( "lap:7.4" )
        V_IMAGES+=( "lap:8.0" )
        V_IMAGES+=( "lap:8.1" )
    fi
    V_NUM_IMAGES=${#V_IMAGES[@]}
fi

echo && echo -e "total images to build: \033[032m${V_NUM_IMAGES}\033[0m"

V_YES_TO_ALL=0
V_NO_TO_ALL=0
for V_IMAGE in "${V_IMAGES[@]}"; do

    if [[ $V_IMAGE =~ ^([^\:]+)\:(.*)$ ]]; then
        V_NAME="${BASH_REMATCH[1],,}"
        V_RELEASE="${BASH_REMATCH[2],,}"
    else
        V_NAME="$V_IMAGE"
        V_RELEASE=""
    fi
    V_RELEASE_NAME="$V_RELEASE"
    [[ "$V_RELEASE_NAME" == "" ]] && V_RELEASE_NAME="latest"

    echo && echo -e "building image \033[032m${V_NAME}\033[0m release \033[032m${V_RELEASE_NAME}\033[0m"

    V_DOCKERFILE="${V_ROOT}/${V_NAME}/Dockerfile"
    echo -e "using Dockerfile \033[032m${V_DOCKERFILE}\033[0m"

    if [ ! -f "$V_DOCKERFILE" ]; then
        echo -e "\033[031merror: Dockerfile \033[032m${V_DOCKERFILE}\033[031m not found\033[0m"
        exit 1
    fi

    F_TAG_EXISTS() {
        local V_TAG="$1"
        if [[ "$(docker images -q "$V_TAG" 2> /dev/null)" != "" ]]; then
            echo -n 1
        else
            echo -n 0
        fi
    }

    if [ "$V_RELEASE" != "" ]; then
        V_TAG="${V_MAINTAINER}/${V_NAME}:${V_RELEASE}"
    else
        V_TAG="${V_MAINTAINER}/${V_NAME}:latest"
    fi
    echo -e "using image tag \033[032m${V_TAG}\033[0m"

    if [[ $( F_TAG_EXISTS "$V_TAG" ) -eq 1 ]]; then
        if [[ $V_NO_TO_ALL -eq 1 ]]; then
            V_CONFIRM="n"
        else
            if [[ $V_YES_TO_ALL -eq 1 ]]; then
                V_CONFIRM="y"
            else
                echo
                echo -e -n "Image tag \033[032m${V_TAG}\033[0m already exists.\nDo you want to rebuild it? "
                echo -e -n "(\033[032my\033[0mes/Yes to \033[032ma\033[0mll/\033[032mN\033[0mo/\033[032ms\033[0mkip all)\033[032m"
                read -p " " V_CONFIRM
                echo -e -n "\033[0m"
                if [[ "${V_CONFIRM,,}" == "a" ]]; then
                    V_YES_TO_ALL=1
                    V_CONFIRM="y"
                else
                    if [[ "${V_CONFIRM,,}" == "s" ]]; then
                        V_NO_TO_ALL=1
                        V_CONFIRM="n"
                    fi
                fi
            fi
        fi
        if [[ "${V_CONFIRM,,}" != "y" ]]; then
            echo -e "\033[031mskipped\033[0m"
            continue
        else
            if [[ $V_CACHE == 0 ]]; then
                V_IMG_ID=$(docker images --filter=reference="${V_TAG}" -q)
                if [ "$V_IMG_ID" != "" ]; then
                    echo
                    echo -e "Removing docker image \033[032m${V_TAG}\033[0m (\033[032m${V_IMG_ID}\033[0m)"
                    echo
                    docker rmi "$V_IMG_ID"
                fi
            fi
        fi
    fi

    V_TIME_START=$( date +%s )

    V_CMD="docker build "
    V_CMD+="--build-arg UID=1000 "
    V_CMD+="--build-arg GID=1000 "
    if [ "$V_RELEASE" != "" ]; then
        V_CMD+="--build-arg RELEASE=\"${V_RELEASE}\" "
    fi
    V_CMD+="--progress=plain "
    if [[ $V_CACHE -eq 0 ]]; then
        V_CMD+="--no-cache "
    fi
    V_CMD+="--tag \"${V_TAG}\" "
    V_CMD+="--file \"${V_DOCKERFILE}\" "
    V_CMD+="$( dirname $V_DOCKERFILE )"

    echo
    echo -e "build command: \033[032m${V_CMD}\033[0m"
    eval "$V_CMD"
    echo

    V_TIME_END=$( date +%s )
    V_TIME_DIFF=$(( V_TIME_END - V_TIME_START))

    if [[ $( F_TAG_EXISTS "$V_TAG" ) -eq 1 ]]; then
        echo -e "Docker image \033[032m${V_TAG}\033[0m created in \033[032m${V_TIME_DIFF}\033[0m seconds!"
    else
        echo -e "\033[031mCreating docker image \033[032m${V_TAG}\033[031m failed!\033[0m"
        exit 1
    fi

done

exit 0