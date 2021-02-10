FROM ubuntu:16.04
RUN apt-get update && apt-get -y install gawk wget git-core \
    diffstat unzip texinfo gcc-multilib build-essential \
    chrpath socat cpio python python3 python3-pip \
    python3-pexpect xz-utils debianutils iputils-ping \
    libsdl1.2-dev xterm tar locales curl nano

# Python3.7 or newer is required by AGL but is not available on ubuntu 16.04 repos
# Get from alternative repo:
RUN apt-get -y install software-properties-common
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt-get update
RUN apt-get -y install python3.7
# Replace current python link with python3.7:
RUN rm -f /usr/bin/python3
RUN ln -s /usr/bin/python3.7 /usr/bin/python3
RUN rm /bin/sh && ln -s bash /bin/sh    

# Set locales:
RUN locale-gen en_US.UTF-8 && update-locale LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# User settings. Should be passed using --build-arg when building the image. Otherwise, you can expect accesss errors.
ARG USER_NAME=yob
ARG HOST_UID=1000
ARG HOST_GID=1000

# Add the user to the image's linux:
#RUN echo -e "Runing with:\n * USER_NAME: ${USER_NAME}\n * HOST_GID: ${HOST_GID}\n * HOST_UID: ${HOST_UID}\n"
RUN groupadd -g $HOST_GID $USER_NAME && \
    useradd -g $HOST_GID -m -s /bin/bash -u $HOST_UID $USER_NAME
USER $USER_NAME
ENV USER_FOLDER /home/$USER_NAME

# Setup folders:
RUN mkdir -p $USER_FOLDER/bin
RUN mkdir -p $USER_FOLDER/agl

# Download the agl's "repo" tool:
RUN curl https://storage.googleapis.com/git-repo-downloads/repo > $USER_FOLDER/bin/repo
RUN chmod a+x $USER_FOLDER/bin/repo

# Configures image's linux git config:
# TODO: could be passed also by ARGs during the build.
RUN git config --global user.email "email"
RUN git config --global user.name "name"

WORKDIR $USER_FOLDER/agl


## To build image:
#sudo docker build \
#--build-arg USER_NAME=$USER \
#--build-arg HOST_UID=`id -u` \
#--build-arg HOST_GID=`id -g` \
#-t agl:latest .

## To run container:
#rm -rf out && \
#mkdir out && \
#sudo docker run -it \
#-v /home/$USER/docker2/out:/home/$USER/agl \
#agl:latest

## To run the build (from inside the container):
#./../bin/repo init -b icefish -u https://gerrit.automotivelinux.org/gerrit/AGL/AGL-repo && \
#./../bin/repo sync && \
#source meta-agl/scripts/aglsetup.sh -m raspberrypi4 agl-demo agl-appfw-smack && \
#bitbake agl-demo-platform
