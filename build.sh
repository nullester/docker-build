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
if [[ $( which strtolower | wc -l ) -eq 0 ]]; then
    strtolower() {
        local STR="$1"
        if [[ "$SHELL" == "/bin/zsh" ]]; then
            echo -n "${STR:l}"
        else
            echo -n "${STR,,}"
        fi
    }
fi

V_ROOT=$( dirname $( realpath "$0" ) )

echo -e "Docker Build \033[032m$( cat "$V_ROOT/VERSION")\033[0m"

F_TAG_EXISTS() {
    local V_TAG="$1"
    if [[ "$(docker images -q "$V_TAG" 2> /dev/null)" != "" ]]; then
        echo -n 1
    else
        echo -n 0
    fi
}

if [ $( which docker | wc -l ) -eq 0 ]; then
    echo -e "\033[031mError: \033[032mdocker\033[031m not installed\033[0m"
    exit 1
fi

V_IMAGES=( )
V_MAINTAINER="nullester"
V_CACHE=0
V_YES_TO_ALL=0
V_QUIET_BUILD=0
while (( "$#" )); do
    case "$1" in
        -c|--cache)
            V_CACHE=1
            shift
            ;;
        -y|--yes|--yes-to-all)
            V_YES_TO_ALL=1
            shift
            ;;
        -q|--quiet)
            V_QUIET_BUILD=1
            shift
            ;;
        -m|--maintainer|--maintainer=*)
            if [[ "$1" =~ ^[^\=]+\=(.+)$ ]]; then
                V_MAINTAINER="${BASH_REMATCH[1]}"; shift 1
            else
                V_MAINTAINER="$2"; shift 2
            fi
            ;;
        -*|--*=) # unsupported flags
            echo && echo -e "\033[031mError: unsupported flag \033[032m$1\033[0m" >&2
            exit 1
            ;;
        *) # preserve positional arguments
            V_IMAGES+=( "$1" )
            shift
            ;;
    esac
done

if [[ $V_CACHE -eq 1 || $V_YES_TO_ALL -eq 1 || $V_QUIET_BUILD -eq 1 ]]; then
    echo
    [[ $V_CACHE -eq 1 ]] && echo -e "\033[032mWith cache mode\033[0m enabled"
    [[ $V_YES_TO_ALL -eq 1  ]] && echo -e "\033[032mAnswer yes-to-all mode\033[0m enabled"
    [[ $V_QUIET_BUILD -eq 1 ]] && echo -e "\033[032mQuiet build mode\033[0m enabled"
fi

V_NUM_IMAGES=${#V_IMAGES[@]}
if [[ $V_NUM_IMAGES -eq 0 ]]; then
    if [[ -d "${V_ROOT}/ubuntu" ]]; then
        cd "$V_ROOT/ubuntu"
        echo && echo -e "Updating \033[032mubuntu\033[0m"
        git pull
        cd "$V_PWD"
        V_IMAGES+=( "ubuntu" )
    fi
    if [[ -d "${V_ROOT}/lap" ]]; then
        cd "$V_ROOT/lap"
        echo && echo -e "Updating \033[032mlap\033[0m"
        git pull
        cd "$V_PWD"
        V_IMAGES+=( "lap:7.1" )
        V_IMAGES+=( "lap:7.2" )
        V_IMAGES+=( "lap:7.3" )
        V_IMAGES+=( "lap:7.4" )
        V_IMAGES+=( "lap:8.0" )
        V_IMAGES+=( "lap:8.1" )
    fi
    for V_DIR in $V_ROOT/*; do
        V_BASENAME=$( basename "$V_DIR" )
        if [[ $V_BASENAME == "ubuntu" || $V_BASENAME == "lap" ]]; then
            continue
        fi
        if [[ -f "$V_DIR/Dockerfile" && -d "$V_DIR/.git" ]]; then
            cd "$VDIR"
            echo && echo -e "Updating \033[032m${V_BASENAME}\033[0m"
            git pull
            V_IMAGES+=( "${V_BASENAME}" )
            cd "$V_PWD"
        fi
    done
    V_NUM_IMAGES=${#V_IMAGES[@]}
fi

if [[ $V_NUM_IMAGES -eq 0 ]]; then
    echo && echo -e "\033[0mNo images found to build, exiting\033[0m"
    exit 0
fi

echo && echo -e "Total images to build: \033[032m${V_NUM_IMAGES}\033[0m"
V_I=1
for V_IMAGE in "${V_IMAGES[@]}"; do
    echo -e "\033[033m${V_I}\033[0m \033[032m${V_MAINTAINER}/${V_IMAGE}\033[0m"
    V_I=$(( V_I + 1 ))
done
if [[ $V_YES_TO_ALL -eq 0 ]]; then
    echo
    echo -e -n "Do you want to (re)build all these Docker images? "
    echo -e -n "(\033[032my\033[0mes/\033[032mN\033[0mo)\033[032m"
    read -p " " V_CONFIRM
    echo -e -n "\033[0m"
    V_CONFIRM=$( strtolower "$V_CONFIRM" )
    if [[ "${V_CONFIRM}" != "y" && "${V_CONFIRM}" != "yes" ]]; then
        echo && echo -e "\033[031maborted\033[0m"
        exit 0
    fi
fi

V_NO_TO_ALL=0
for V_IMAGE in "${V_IMAGES[@]}"; do

    if [[ $V_IMAGE =~ ^([^\:]+)\:(.*)$ ]]; then
        V_NAME="${BASH_REMATCH[1]}"
        V_RELEASE="${BASH_REMATCH[2]}"
    else
        V_NAME="$V_IMAGE"
        V_RELEASE=""
    fi
    V_NAME=$( strtolower "$V_NAME" )
    V_RELEASE=$( strtolower "$V_RELEASE" )
    V_RELEASE_NAME="$V_RELEASE"
    [[ "$V_RELEASE_NAME" == "" ]] && V_RELEASE_NAME="latest"

    echo && echo -e "Building image \033[032m${V_NAME}\033[0m release \033[032m${V_RELEASE_NAME}\033[0m"

    V_DOCKERFILE="${V_ROOT}/${V_NAME}/Dockerfile"
    echo -e "Using Dockerfile \033[032m${V_DOCKERFILE}\033[0m"

    if [ ! -f "$V_DOCKERFILE" ]; then
        echo && echo -e "\033[031mError: Dockerfile \033[032m${V_DOCKERFILE}\033[031m not found\033[0m"
        exit 1
    fi

    if [ "$V_RELEASE" != "" ]; then
        V_TAG="${V_MAINTAINER}/${V_NAME}:${V_RELEASE}"
    else
        V_TAG="${V_MAINTAINER}/${V_NAME}:latest"
    fi
    echo -e "Using image tag \033[032m${V_TAG}\033[0m"

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
                echo -e "\033[0m"
                V_CONFIRM=$( strtolower "$V_CONFIRM" )
                if [[ "${V_CONFIRM}" == "a" ]]; then
                    V_YES_TO_ALL=1
                    V_CONFIRM="y"
                else
                    if [[ "${V_CONFIRM}" == "s" ]]; then
                        V_NO_TO_ALL=1
                        V_CONFIRM="n"
                    fi
                fi
            fi
        fi
        if [[ "${V_CONFIRM}" != "y" ]]; then
            echo -e "\033[031mskipped\033[0m"
            continue
        else
            if [[ $V_CACHE == 0 ]]; then
                V_IMG_ID=$(docker images --filter=reference="${V_TAG}" -q)
                if [ "$V_IMG_ID" != "" ]; then
                    echo -e "Removing docker image \033[032m${V_TAG}\033[0m (\033[032m${V_IMG_ID}\033[0m)"
                    docker rmi "$V_IMG_ID" > /dev/null 2>&1
                fi
            fi
        fi
    fi

    V_TIME_START=$( date +%s )

    V_CMD="docker build "
    V_CMD+="--build-arg UID=1000 "
    V_CMD+="--build-arg GID=1000 "
    V_CMD+="--build-arg MAINTAINER=\"${V_MAINTAINER}\" "
    if [ "$V_RELEASE" != "" ]; then
        V_CMD+="--build-arg RELEASE=\"${V_RELEASE}\" "
    fi
    V_CMD+="--progress=plain "
    if [[ $V_CACHE -eq 0 ]]; then
        V_CMD+="--no-cache "
    fi
    if [[ $V_QUIET_BUILD -eq 1 ]]; then
        V_CMD+="-q "
    fi
    V_CMD+="--tag \"${V_TAG}\" "
    V_CMD+="--file \"${V_DOCKERFILE}\" "
    V_CMD+="$( dirname $V_DOCKERFILE )"

    echo -e "Build command: \033[032m${V_CMD}\033[0m"
    if [[ $V_QUIET_BUILD -eq 1 ]]; then
        echo -e -n "Building \033[032m${V_TAG}\033[0m..."
    fi
    eval "$V_CMD"
    if [[ $V_QUIET_BUILD -eq 1 ]]; then
        echo -e "\033[032mdone\033[0m"
    fi

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