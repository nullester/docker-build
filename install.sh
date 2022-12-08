#!/usr/bin/env bash

if [[ -d ~/.docker/.build ]]; then
    echo -e "\033[031mAborting, Docker Build already installed\033[0m"
    exit 1
fi
if [[ -d ~/.docker && ! -w ~/.docker ]]; then
    echo -e "Directory ~/.docker exists but is not writable\033[0m"
    exit 1
fi

if [[ $( which git | wc -l) -eq 0 ]]; then
    echo -e "\033[031mAborting, the \033[032mgit\033[0m command is required to install this package\033[0m"
    exit 1
fi

echo -e "Cloning \033[032mnullester/docker-build\033[0m into \033[032m~/.docker/.build\033[032m"
git clone git@github.com:nullester/docker-build.git ~/.docker/.build

if [[ -f ~/.docker/.build/build.sh ]]; then
    echo -e "\033[032mDocker Build\033[0m successfully installed!"
    cd ~/.docker/.build
    ./update.sh
else
    echo -e "\033[031mInstalling \033[032mDocker Build\033[031m failed!\033[0m"
    exit 1
fi

exit 0