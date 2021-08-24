FROM ubuntu:21.04

ENV DEBIAN_FRONTEND="noninteractive"
ENV TZ="Europe/London"

RUN apt-get update && apt-get -y upgrade && apt-get -y install apt-utils && \
    apt-get -y install gawk wget git-core \
    diffstat unzip texinfo gcc-multilib build-essential \
    chrpath socat cpio python python3 python3-pip \
    python3-pexpect xz-utils debianutils iputils-ping \
    libncurses5-dev libsdl1.2-dev xterm tar locales curl nano \
    tmux curl dosfstools mtools parted syslinux tree zip

# Set locales:
RUN locale-gen en_US.UTF-8 && update-locale LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# User settings. Should be passed using --build-arg when building the image. Otherwise, you can expect access errors.
ARG USER_NAME=yocto
ARG HOST_UID=1000
ARG HOST_GID=1000
ARG GIT_USER_NAME="dummyName"
ARG GIT_EMAIL="dummy@email.com"

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
ENV PATH="$USER_FOLDER/bin:${PATH}"

# Configures image's linux git config:
RUN git config --global user.email "$GIT_USER_NAME"
RUN git config --global user.name "$GIT_EMAIL"
WORKDIR $USER_FOLDER/agl
