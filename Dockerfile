FROM ubuntu:21.04 as base

ENV DEBIAN_FRONTEND="noninteractive"
ENV TZ="Europe/London"

RUN apt-get update && apt-get -y upgrade && apt-get install -y git-core gnupg flex bison \
    build-essential zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 \
	lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z1-dev \
	python python3 python3-pip python3-pexpect \
	libgl1-mesa-dev libxml2-utils xsltproc unzip fontconfig libncurses5 procps \
	libssl-dev bc fdisk eject locales && \
	apt-get install -y gcc-aarch64-linux-gnu

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
RUN mkdir -p $USER_FOLDER/build

# Download the "repo" tool:
RUN curl https://storage.googleapis.com/git-repo-downloads/repo > $USER_FOLDER/bin/repo
RUN chmod a+x $USER_FOLDER/bin/repo
ENV PATH="$USER_FOLDER/bin:${PATH}"

# Configures image's linux git config:
RUN git config --global user.email "$GIT_USER_NAME"
RUN git config --global user.name "$GIT_EMAIL"
RUN git config --global color.ui false
WORKDIR $USER_FOLDER/build

FROM base as fetch

WORKDIR $USER_FOLDER/build
RUN repo init -u https://android.googlesource.com/platform/manifest -b android11-qpr2-release && \
    git clone https://github.com/snappautomotive/firmware_rpi-local_manifests.git .repo/local_manifests -b sa-main && \
	repo sync
	
FROM fetch as patch

FROM patch as buildkernel
RUN cd kernel/arpi && \
    ARCH=arm64 scripts/kconfig/merge_config.sh arch/arm64/configs/bcm2711_defconfig kernel/configs/android-base.config kernel/configs/android-recommended.config && \
    ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- make Image.gz && \
    ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- DTC_FLAGS=”-@” make broadcom/bcm2711-rpi-4-b.dtb && \
    ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- DTC_FLAGS=”-@” make overlays/vc4-kms-v3d-pi4.dtbo && \
    cd ../..

FROM buildkernel as build
RUN source build/envsetup.sh && \
    lunch snapp_car_rpi4-userdebug && \
    make -j ramdisk systemimage vendorimage
