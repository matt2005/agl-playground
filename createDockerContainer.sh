#!/bin/bash
TARGET_BRANCH="koi"


FOLDER=$PWD/agl
SHOULD_REBUILD_IMAGE=n
if [ -d "$FOLDER" ]
then
    echo "$FOLDER is an existing directory. Continuing will erase the folder's content. Should we continue? (y/n)"
    read SHOULD_REBUILD_IMAGE
else
    echo "$FOLDER does not exist. Proceeding"
    SHOULD_REBUILD_IMAGE=y
fi

if [ $SHOULD_REBUILD_IMAGE = y ]
then
    rm -rf $PWD/agl
    mkdir -p $PWD/agl
    echo "Running..."
    wget -N https://github.com/pauloasherring/agl-playground/raw/main/Dockerfile
    sudo docker build \
    --build-arg USER_NAME=$USER \
    --build-arg HOST_UID=`id -u` \
    --build-arg HOST_GID=`id -g` \
    --build-arg GIT_USER_NAME=paulo \
    --build-arg GIT_EMAIL=pauloasherring@gmail \
    -t agl:latest \
    . 
    mkdir -p $PWD/agl/out
    mkdir -p $PWD/agl/out/meta
    echo "cd meta && repo init -b koi -u https://gerrit.automotivelinux.org/gerrit/AGL/AGL-repo && repo sync && cd ..
cd meta 
repo init -b $TARGET_BRANCH -u https://gerrit.automotivelinux.org/gerrit/AGL/AGL-repo
repo sync 
cd ..
source meta/meta-agl/scripts/aglsetup.sh -m raspberrypi4 agl-demo agl-appfw-smack
bitbake agl-demo-platform" > $PWD/agl/out/sourceress
    echo "Done."
else
    echo "Ok. Bye."
fi

echo "Should I run the docker container? (y/n)"
read
if [ $REPLY = y ]
then
    echo "Running..."
    sudo docker run -it -v $PWD/agl/out:/home/$USER/agl agl:latest
fi
echo "Ok. Bye."
