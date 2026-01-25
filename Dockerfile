# syntax=docker/dockerfile:1
# check=skip=SecretsUsedInArgOrEnv

ARG DISTRO=noble
ARG QTCREATOR_BASE_IMAGE=ubuntu:${DISTRO}
ARG USER=user
ARG UID=1000
ARG GID=1000
ARG CLANG_MAJOR=21
# clang source options:
# apt - directly use apt version
# llvm - add llvm distro repo
ARG CLANG_SOURCE=llvm
ARG GCC_MAJOR=14
# gcc source options:
# apt - directly use apt version
# ppa - add toolchain ppa
ARG GCC_SOURCE=apt
# note: this AQT version has patch for latest python pool issues (no new release yet)
ARG AQT_WHL_URL=https://github.com/arBmind/aqtinstall/releases/download/3.3.1-dev/aqtinstall-3.3.1.dev19-py3-none-any.whl
ARG QTCREATOR_VERSION="17.0.1-patched"
ARG QTCREATOR_URL="https://github.com/hicknhack-software/Qt-Creator/releases/download/v17.0.1-patched-2025-08-22/qtcreator-linux-x64-17475136203.7z"
ARG QT_ARCH=linux_gcc_64
ARG QT_VERSION=6.9.2
ARG QT_MODULES=qtshadertools
ARG RUNTIME_APT="icu-devtools libglib2.0-0 libdbus-1-3 libpcre2-16-0 libbrotli1"
# ARG RUNTIME_LUNAR="libicu72 libglib2.0-0 libdbus-1-3 libpcre2-16-0"
# ARG RUNTIME_XENIAL="libicu55 libglib2.0-0"


FROM python:3.13-slim AS qt_base
ARG \
  AQT_WHL_URL \
  QT_ARCH \
  QT_VERSION \
  QT_MODULES \
  DEBIAN_FRONTEND=noninteractive

RUN <<INSTALL_AQT
  apt-get -qq update -o=Dpkg::Use-Pty=0
  apt-get -qq --yes install -o=Dpkg::Use-Pty=0 --no-install-recommends \
    wget \
    p7zip-full \
    libglib2.0-0
  apt-get -qq --yes autoremove -o=Dpkg::Use-Pty=0
  apt-get -qq clean autoclean -o=Dpkg::Use-Pty=0
  rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*
  if [ "$AQT_WHL_URL" != "" ] ; then
    FILENAME=$(basename "$AQT_WHL_URL")
    wget -q -c ${AQT_WHL_URL} -O /tmp/$FILENAME
    pip install /tmp/$FILENAME
    rm /tmp/$FILENAME
  else
    pip install aqtinstall
  fi
INSTALL_AQT

# note: /tmp/7z.sh adds missing -snld20 option to allow 7z to extract symlinks
RUN <<INSTALL_QT
  set -e
  mkdir /qt
  cd /qt
  echo '#!/bin/bash' > /tmp/7z.sh
  echo "$(which 7zr) \"\$@\" -snld20" >> /tmp/7z.sh
  chmod u+x /tmp/7z.sh
  aqt install-qt linux desktop ${QT_VERSION} ${QT_ARCH} -m ${QT_MODULES} --external /tmp/7z.sh
  rm /tmp/7z.sh
INSTALL_QT



# base QtCreator setup
FROM ${QTCREATOR_BASE_IMAGE} AS qtcreator_base
ARG \
  DISTRO \
  USER \
  UID \
  GID \
  QTCREATOR_URL \
  RUNTIME_APT \
  DEBIAN_FRONTEND=noninteractive
ENV \
  LANG=C.UTF-8 \
  LC_ALL=C.UTF-8 \
  DISPLAY=:0 \
  WAYLAND_DISPLAY=wayland-0

# install prerequisites to run qtcreator, tools and Qt
RUN <<INSTALL_PREREQUISITES
  set -e
  apt-get -qq update -o=Dpkg::Use-Pty=0
  apt-get -qq --yes upgrade -o=Dpkg::Use-Pty=0
  apt-get -qq --yes install -o=Dpkg::Use-Pty=0 --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    gnupg \
    wget
  apt-get -qq update -o=Dpkg::Use-Pty=0
  apt-get -qq --yes install -o=Dpkg::Use-Pty=0 --no-install-recommends \
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
    libpulse0 \
    libdbus-1-3 \
    libgl1-mesa-dri \
    libglx-mesa0 \
    libxcb-keysyms1 \
    libxcb-render-util0 \
    libxcb-xfixes0 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-randr0 \
    libxcb-shape0 \
    libxcb-cursor0 \
    libgssapi-krb5-2 \
    libxcb-xinerama0 \
    libxcb-xkb1 \
    libxkbcommon-x11-0 \
    libxkbcommon-dev \
    libharfbuzz-icu0 \
    libegl1-mesa-dev \
    libglu1-mesa-dev \
    libwayland-egl1 \
    libwayland-cursor0
  apt-get -qq --yes autoremove -o=Dpkg::Use-Pty=0
  apt-get -qq clean autoclean -o=Dpkg::Use-Pty=0
  rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*
INSTALL_PREREQUISITES

# install qtcreator from CI build
RUN <<INSTALL_QTCREATOR
  wget --progress=bar:force:noscroll -O qtcreator.7z ${QTCREATOR_URL}
  mkdir /opt/qtcreator
  7z x -o/opt/qtcreator qtcreator.7z
  rm qtcreator.7z
  ln -s /opt/qtcreator/bin/qtcreator /usr/bin/qtcreator
INSTALL_QTCREATOR

# add user for development
RUN --mount=source=./config,target=/qtcreator-config <<SETUP_USER
  if [ "${UID}" = "1000" ] ; then
    userdel --remove ubuntu
  fi
  groupadd --gid ${GID} ${USER}
  useradd --create-home --home-dir /home/${USER} --shell /bin/bash ${USER} --uid ${UID} --gid ${GID}
  echo "${USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USER}
  chmod 0440 /etc/sudoers.d/${USER}
  mkdir -p /build
  mkdir -p /home/${USER}/.config/QtProject/qtcreator
  cp /qtcreator-config/* /home/${USER}/.config/QtProject/qtcreator
  chown ${UID}:${GID} -R /home/${USER} /build
SETUP_USER

WORKDIR /build



FROM qtcreator_base AS qtcreator_clang_base
ARG \
  DISTRO \
  CLANG_MAJOR \
  CLANG_SOURCE \
  DEBIAN_FRONTEND=noninteractive

# install Clang (https://apt.llvm.org/) with format and debugger
RUN <<INSTALL_CLANG
  if [ "$CLANG_SOURCE" = "llvm" ] ; then
    wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key > /etc/apt/trusted.gpg.d/apt.llvm.org.asc
    tee /etc/apt/sources.list.d/llvm.sources <<LLVM_SOURCES
Enabled: yes
Types: deb
URIs: http://apt.llvm.org/${DISTRO}/
Suites: llvm-toolchain-${DISTRO}-${CLANG_MAJOR}
Components: main
Signed-By: /etc/apt/trusted.gpg.d/apt.llvm.org.asc
LLVM_SOURCES
    apt-get -qq update -o=Dpkg::Use-Pty=0
  fi
  apt-get -qq --yes install -o=Dpkg::Use-Pty=0 --no-install-recommends \
    clang-${CLANG_MAJOR} \
    clang-format-${CLANG_MAJOR} \
    lldb-${CLANG_MAJOR} \
    lld-${CLANG_MAJOR} \
    libc++abi-${CLANG_MAJOR}-dev \
    libc++-${CLANG_MAJOR}-dev
  update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-${CLANG_MAJOR} 100
  update-alternatives --install /usr/bin/clang clang /usr/bin/clang-${CLANG_MAJOR} 100
  update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-${CLANG_MAJOR} 100
  update-alternatives --install /usr/bin/ld ld /usr/bin/ld.lld-${CLANG_MAJOR} 10
  update-alternatives --install /usr/bin/ld ld /usr/bin/ld.gold 20
  update-alternatives --install /usr/bin/ld ld /usr/bin/ld.bfd 30
  apt-get -qq --yes autoremove -o=Dpkg::Use-Pty=0
  apt-get -qq clean autoclean -o=Dpkg::Use-Pty=0
  rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*
INSTALL_CLANG



# final qtcreator-clang
FROM qtcreator_clang_base AS qtcreator-clang
ARG USER

USER ${USER}
ENV \
  HOME=/home/${USER} \
  XDG_RUNTIME_DIR=/tmp/runtime-${USER}



FROM qtcreator_clang_base AS qtcreator_clang_libstdcpp_base
ARG \
  DISTRO \
  GCC_MAJOR \
  GCC_SOURCE \
  APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 \
  DEBIAN_FRONTEND=noninteractive

RUN <<INSTALL_LIBSTDCPP
  if [ "$GCC_SOURCE" = "ppa" ] ; then
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 60C317803A41BA51845E371A1E9377A2BA9EF27F
    echo "deb http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu ${DISTRO} main" > /etc/apt/sources.list.d/gcc.list
    apt-get -qq update -o=Dpkg::Use-Pty=0
  fi
  apt-get -qq --yes install -o=Dpkg::Use-Pty=0 --no-install-recommends \
    libstdc++-${GCC_MAJOR}-dev
  apt-get -qq --yes autoremove -o=Dpkg::Use-Pty=0
  apt-get -qq clean autoclean -o=Dpkg::Use-Pty=0
  rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*
INSTALL_LIBSTDCPP



# final qtcreator-clang-libstdcpp
FROM qtcreator_clang_libstdcpp_base AS qtcreator-clang-libstdcpp
ARG USER

USER ${USER}
ENV \
  HOME=/home/${USER} \
  XDG_RUNTIME_DIR=/tmp/runtime-${USER}



FROM qtcreator_clang_libstdcpp_base AS qtcreator-clang-libstdcpp-qt
ARG \
  USER \
  QT_VERSION

COPY --from=qt_base /qt/${QT_VERSION}/gcc_64 /opt/qt

USER ${USER}
ENV \
  HOME=/home/${USER} \
  XDG_RUNTIME_DIR=/tmp/runtime-${USER}



FROM qtcreator_base AS qtcreator_gcc_base
ARG \
  DISTRO \
  GCC_MAJOR \
  GCC_SOURCE \
  APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 \
  DEBIAN_FRONTEND=noninteractive

RUN <<INSTALL_GCC_GDB
  if [ "$GCC_SOURCE" = "ppa" ] ; then
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 60C317803A41BA51845E371A1E9377A2BA9EF27F
    echo "deb http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu ${DISTRO} main" > /etc/apt/sources.list.d/gcc.list
    apt-get -qq update -o=Dpkg::Use-Pty=0
  fi
  apt-get -qq --yes install -o=Dpkg::Use-Pty=0 --no-install-recommends \
    gcc-${GCC_MAJOR} \
    g++-${GCC_MAJOR} \
    libstdc++-${GCC_MAJOR}-dev \
    gdb
  apt-get -qq --yes autoremove -o=Dpkg::Use-Pty=0
  apt-get -qq clean autoclean -o=Dpkg::Use-Pty=0
  rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*
INSTALL_GCC_GDB



FROM qtcreator_gcc_base AS qtcreator-gcc
ARG USER

USER ${USER}
ENV \
  HOME=/home/${USER} \
  XDG_RUNTIME_DIR=/tmp/runtime-${USER}



FROM qtcreator_gcc_base AS qtcreator-gcc-qt
ARG \
  USER \
  QT_VERSION

COPY --from=qt_base /qt/${QT_VERSION}/gcc_64 /opt/qt

USER ${USER}
ENV \
  HOME=/home/${USER} \
  XDG_RUNTIME_DIR=/tmp/runtime-${USER}
