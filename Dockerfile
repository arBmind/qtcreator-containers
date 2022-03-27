ARG DISTRO=focal
ARG USER=user
ARG UID=1000
ARG GID=1000
ARG CLANG_MAJOR=13
ARG GCC_MAJOR=11
ARG QTCREATOR_URL="https://github.com/arBmind/qt-creator/releases/download/v7.0.0-patched-snapshot-2022-03-19/qtcreator-Linux-2011964361.7z"
ARG QTCREATOR_VERSION="7.0.0-patched"
ARG QT_ARCH=gcc_64
ARG QT_VERSION=6.2.4
ARG QT_MODULES=qtshadertools
ARG RUNTIME_APT="libicu66 libglib2.0-0 libdbus-1-3 libpcre2-16-0"
# ARG RUNTIME_XENIAL="libicu55 libglib2.0-0"

FROM python:3.10-slim as qt_base
ARG QT_ARCH
ARG QT_VERSION
ARG QT_MODULES
ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1
ARG DEBIAN_FRONTEND=noninteractive

RUN pip install aqtinstall

RUN \
  apt update --quiet \
  && apt-get install --yes --quiet --no-install-recommends \
    p7zip-full \
    libglib2.0-0 \
  && apt-get --yes autoremove \
  && apt-get clean autoclean \
  && rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*

RUN \
  mkdir /qt && cd /qt \
  && aqt install-qt linux desktop ${QT_VERSION} ${QT_ARCH} -m ${QT_MODULES} --external "7z"


FROM ubuntu:${DISTRO} AS qtcreator_base
ARG DISTRO
ARG USER
ARG UID
ARG GID
ARG QTCREATOR_URL
ARG RUNTIME_APT
ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1
ARG DEBIAN_FRONTEND=noninteractive

ENV \
  LANG=C.UTF-8 \
  LC_ALL=C.UTF-8

# install prerequisites to run qtcreator, tools and Qt
RUN \
  apt-get update --quiet \
  && apt-get upgrade \
  && apt-get install --yes --quiet --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    gnupg \
    wget \
  && apt-get update --quiet \
  && apt-get install --yes --quiet --no-install-recommends \
    ${RUNTIME_APT} \
    sudo \
    git \
    vim \
    patch \
    ssh \
    make \
    p7zip-full \
    xterm \
    xdg-utils \
    libdbus-1-3 \
    libgl1-mesa-dri \
    libgl1-mesa-glx \
    libxcb-keysyms1 \
    libxcb-render-util0 \
    libxcb-xfixes0 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-randr0 \
    libxcb-shape0 \
    libgssapi-krb5-2 \
    libxcb-xinerama0 \
    libxcb-xkb1 \
    libxkbcommon-x11-0 \
    libharfbuzz-icu0 \
    libegl1-mesa-dev \
    libglu1-mesa-dev  \
  && apt-get --yes autoremove \
  && apt-get clean autoclean \
  && rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*

# install qtcreator from CI build
RUN \
  wget --progress=bar:force:noscroll -O qtcreator.7z ${QTCREATOR_URL} \
  && mkdir /opt/qtcreator \
  && 7z x -o/opt/qtcreator qtcreator.7z \
  && rm qtcreator.7z \
  && ln -s /opt/qtcreator/bin/qtcreator /usr/bin/qtcreator

# preconfigure qtcreator
COPY config/qtversion.xml /home/${USER}/.config/QtProject/qtcreator/qtversion.xml
COPY config/QtCreator.ini /home/${USER}/.config/QtProject/QtCreator.ini

# add user for development
RUN \
  mkdir -p /home/${USER} \
  && mkdir -p /build \
  && groupadd -g ${GID} ${USER} \
  && useradd -d /home/${USER} -s /bin/bash -m ${USER} -u ${UID} -g ${GID} \
  && echo "${USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USER} \
  && chmod 0440 /etc/sudoers.d/${USER} \
  && chown ${UID}:${GID} -R /home/${USER} /build

WORKDIR /build


FROM qtcreator_base AS qtcreator_clang_base
ARG DISTRO
ARG CLANG_MAJOR
ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1
ARG DEBIAN_FRONTEND=noninteractive

# install Clang (https://apt.llvm.org/) with format and debugger
RUN \
  wget -qO - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - \
  && echo "deb http://apt.llvm.org/${DISTRO}/ llvm-toolchain-${DISTRO}-${CLANG_MAJOR} main" > /etc/apt/sources.list.d/llvm.list \
  && apt-get update --quiet \
  && apt-get install --yes --quiet --no-install-recommends \
    clang-${CLANG_MAJOR} \
    clang-format-${CLANG_MAJOR} \
    lldb-${CLANG_MAJOR} \
    lld-${CLANG_MAJOR} \
    libc++abi-${CLANG_MAJOR}-dev \
    libc++-${CLANG_MAJOR}-dev \
  && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-${CLANG_MAJOR} 100 \
  && update-alternatives --install /usr/bin/clang clang /usr/bin/clang-${CLANG_MAJOR} 100 \
  && update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-${CLANG_MAJOR} 100 \
  && update-alternatives --install /usr/bin/ld ld /usr/bin/ld.lld-${CLANG_MAJOR} 10 \
  && update-alternatives --install /usr/bin/ld ld /usr/bin/ld.gold 20 \
  && update-alternatives --install /usr/bin/ld ld /usr/bin/ld.bfd 30 \
  && apt-get --yes autoremove \
  && apt-get clean autoclean \
  && rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*


FROM qtcreator_clang_base AS qtcreator-clang
ARG USER
ARG DISTRO
ARG CLANG_MAJOR
ARG QTCREATOR_VERSION

LABEL Description="Ubuntu ${DISTRO} - Clang-${CLANG_MAJOR} + QtCreator-${QTCREATOR_VERSION}"

USER ${USER}
ENV \
  HOME=/home/${USER} \
  XDG_RUNTIME_DIR=/tmp/runtime-${USER}


FROM qtcreator_clang_base AS qtcreator_clang_libstdcpp_base
ARG DISTRO
ARG GCC_MAJOR
ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1
ARG DEBIAN_FRONTEND=noninteractive

RUN \
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 60C317803A41BA51845E371A1E9377A2BA9EF27F \
  && echo "deb http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu ${DISTRO} main" > /etc/apt/sources.list.d/gcc.list \
  && apt-get update --quiet \
  && apt-get install --yes --quiet --no-install-recommends \
    libstdc++-${GCC_MAJOR}-dev \
  && apt-get --yes autoremove \
  && apt-get clean autoclean \
  && rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*


FROM qtcreator_clang_libstdcpp_base AS qtcreator-clang-libstdcpp
ARG USER
ARG DISTRO
ARG GCC_MAJOR
ARG CLANG_MAJOR
ARG QTCREATOR_VERSION

LABEL Description="Ubuntu ${DISTRO} - Clang${CLANG_MAJOR} + libstdc++-${GCC_MAJOR} + QtCreator-${QTCREATOR_VERSION}"

USER ${USER}
ENV \
  HOME=/home/${USER} \
  XDG_RUNTIME_DIR=/tmp/runtime-${USER}


FROM qtcreator_clang_libstdcpp_base AS qtcreator-clang-libstdcpp-qt
ARG USER
ARG DISTRO
ARG CLANG_MAJOR
ARG GCC_MAJOR
ARG QTCREATOR_VERSION
ARG QT_ARCH
ARG QT_VERSION

LABEL Description="Ubuntu ${DISTRO} - Clang${CLANG_MAJOR} + libstdc++-${GCC_MAJOR} + QtCreator-${QTCREATOR_VERSION} + Qt-${QT_VERSION}"

COPY --from=qt_base /qt/${QT_VERSION}/${QT_ARCH} /opt/qt

USER ${USER}
ENV \
  HOME=/home/${USER} \
  XDG_RUNTIME_DIR=/tmp/runtime-${USER}


FROM qtcreator_base AS qtcreator_gcc_base
ARG DISTRO
ARG GCC_MAJOR
ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1
ARG DEBIAN_FRONTEND=noninteractive

# install Clang (https://apt.llvm.org/) with format and debugger
RUN \
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 60C317803A41BA51845E371A1E9377A2BA9EF27F \
  && echo "deb http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu ${DISTRO} main" > /etc/apt/sources.list.d/gcc.list \
  && apt-get update --quiet \
  && apt-get install --yes --quiet --no-install-recommends \
    gcc-${GCC_MAJOR} \
    g++-${GCC_MAJOR} \
    libstdc++-${GCC_MAJOR}-dev \
    gdb \
  && apt-get --yes autoremove \
  && apt-get clean autoclean \
  && rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*


FROM qtcreator_gcc_base AS qtcreator-gcc
ARG USER
ARG DISTRO
ARG GCC_MAJOR
ARG QTCREATOR_VERSION

LABEL Description="Ubuntu ${DISTRO} - GCC-${GCC_MAJOR} + QtCreator-${QTCREATOR_VERSION}"

USER ${USER}
ENV \
  HOME=/home/${USER} \
  XDG_RUNTIME_DIR=/tmp/runtime-${USER}


FROM qtcreator_gcc_base AS qtcreator-gcc-qt
ARG USER
ARG DISTRO
ARG GCC_MAJOR
ARG QTCREATOR_VERSION
ARG QT_ARCH
ARG QT_VERSION

LABEL Description="Ubuntu ${DISTRO} - GCC-${GCC_MAJOR} + QtCreator-${QTCREATOR_VERSION} + Qt-${QT_VERSION}"

COPY --from=qt_base /qt/${QT_VERSION}/${QT_ARCH} /opt/qt

USER ${USER}
ENV \
  HOME=/home/${USER} \
  XDG_RUNTIME_DIR=/tmp/runtime-${USER}
