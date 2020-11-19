# note: this would require --privileged
# FROM ubuntu:bionic
# ARG DISTRO=bionic

ARG DISTRO=focal
ARG USER=user
ARG UID=1000
ARG GID=1000
ARG CLANG_MAJOR=11
ARG QT_MAJOR=515
ARG QT_VERSION=5.15.0
ARG QT_CREATOR_URL="https://github.com/arBmind/qt-creator/releases/download/v4.14.beta2-patched-snapshot_2020-11-07/qtcreator-Linux-351350901.7z"
ARG RUNTIME_APT
ARG RUNTIME_XENIAL="libicu55 libglib2.0-0"
ARG RUNTIME_FOCAL="libicu66 libglib2.0-0 libpcre2-16-0"

FROM ubuntu:${DISTRO} AS clang_base
ARG DISTRO
ARG CLANG_MAJOR

ENV \
  APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 \
  DEBIAN_FRONTEND=noninteractive \
  LANG=C.UTF-8 \
  LC_ALL=C.UTF-8

# install Clang (https://apt.llvm.org/) with format and debugger
RUN \
  apt-get update --quiet \
  && apt-get install --yes --quiet --no-install-recommends wget gnupg apt-transport-https ca-certificates \
  && wget -qO - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - \
  && echo "deb http://apt.llvm.org/${DISTRO}/ llvm-toolchain-${DISTRO}-${CLANG_MAJOR} main" > /etc/apt/sources.list.d/llvm.list \
  && apt-get update --quiet \
  && apt-get install --yes --quiet --no-install-recommends \
    clang-${CLANG_MAJOR} \
    clang-format-${CLANG_MAJOR} \
    lldb-${CLANG_MAJOR} \
    lld-${CLANG_MAJOR} \
    libc++abi-${CLANG_MAJOR}-dev \
    libc++-${CLANG_MAJOR}-dev \
  && update-alternatives --install /usr/bin/cc cc /usr/bin/clang-${CLANG_MAJOR} 100 \
  && update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++-${CLANG_MAJOR} 100 \
  && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-${CLANG_MAJOR} 100 \
  && update-alternatives --install /usr/bin/clang clang /usr/bin/clang-${CLANG_MAJOR} 100 \
  && update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-${CLANG_MAJOR} 100 \
  && update-alternatives --install /usr/bin/ld ld /usr/bin/ld.lld-${CLANG_MAJOR} 10 \
  && update-alternatives --install /usr/bin/ld ld /usr/bin/ld.gold 20 \
  && update-alternatives --install /usr/bin/ld ld /usr/bin/ld.bfd 30 \
  && c++ --version \
  && apt-get --yes autoremove \
  && apt-get clean autoclean \
  && rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*

FROM clang_base AS qtcreator-clang-qt
ARG DISTRO
ARG USER
ARG UID
ARG GID
ARG CLANG_MAJOR
ARG QT_MAJOR
ARG QT_VERSION
ARG QT_CREATOR_URL
ARG RUNTIME_APT
ARG RUNTIME_FOCAL
ARG RUNTIME_XENIAL

LABEL Description="Ubuntu ${DISTRO} - Clang${CLANG_MAJOR} + QtCreator + Qt ${QT_VERSION}"

# install prerequisites to run qtcreator, tools and Qt
RUN \
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C65D51784EDC19A871DBDBB710C56D0DE9977759 \
  && echo "deb http://ppa.launchpad.net/beineri/opt-qt-${QT_VERSION}-${DISTRO}/ubuntu ${DISTRO} main" > /etc/apt/sources.list.d/qt.list \
  && apt-get update --quiet \
  && if [ "${RUNTIME_APT}" != "" ] ; then export "RUNTIME_APT2=${RUNTIME_APT}" ; \
    elif [ "${DISTRO}" = "xenial" ] ; then export "RUNTIME_APT2=${RUNTIME_XENIAL}" ; \
    else export "RUNTIME_APT2=${RUNTIME_FOCAL}" ; \
    fi \
  && apt-get install --yes --quiet --no-install-recommends ${RUNTIME_APT2} \
    sudo \
    git \
    vim \
    patch \
    ssh \
    make \
    p7zip-full \
    xterm \
    xdg-utils \
    libgl1-mesa-dri \
    libgl1-mesa-glx \
    libxcb-keysyms1 \
    libxcb-render-util0 \
    libxcb-xfixes0 \
    libxcb-icccm4 \
    libxcb-image0 \
    libgssapi-krb5-2 \
    libxcb-xinerama0 \
    libxcb-xkb1 \
    libxkbcommon-x11-0 \
    libharfbuzz-icu0 \
    libegl1-mesa-dev \
    libglu1-mesa-dev  \
    qt${QT_MAJOR}base \
    qt${QT_MAJOR}declarative \
    qt${QT_MAJOR}tools \
    qt${QT_MAJOR}svg \
    qt${QT_MAJOR}serialport \
    qt${QT_MAJOR}quickcontrols \
    qt${QT_MAJOR}quickcontrols2 \
    qt${QT_MAJOR}graphicaleffects \
    qt${QT_MAJOR}location \
    qt${QT_MAJOR}imageformats \
    qt${QT_MAJOR}translations \
  && apt-get --yes autoremove \
  && apt-get clean autoclean \
  && rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*

# install qtcreator from CI build
RUN \  
  cd /opt \
  && mkdir qtcreator \
  && cd qtcreator \
  && wget --progress=bar:force:noscroll -O qtcreator.7z ${QT_CREATOR_URL} \  
  && 7z x qtcreator.7z \
  && rm qtcreator.7z \
  && ln -s /opt/qtcreator/bin/qtcreator /usr/bin/qtcreator

# preconfigure qtcreator
COPY config/qtversion.xml /home/${USER}/.config/QtProject/qtcreator/qtversion.xml
COPY config/QtCreator.ini /home/${USER}/.config/QtProject/QtCreator.ini
RUN \
  sed -i "s/\${QT_MAJOR}/$QT_MAJOR/g" /home/${USER}/.config/QtProject/qtcreator/qtversion.xml

# add user for development
RUN \
  mkdir -p /home/${USER} \
  mkdir -p /build \
  && groupadd -g ${GID} ${USER} \
  && useradd -d /home/${USER} -s /bin/bash -m ${USER} -u ${UID} -g ${GID} \
  && echo "${USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USER} \
  && chmod 0440 /etc/sudoers.d/${USER} \
  && chown ${UID}:${GID} -R /home/${USER} /build
USER ${USER}
ENV \
  HOME=/home/${USER} \
  XDG_RUNTIME_DIR=/tmp/runtime-${USER}

WORKDIR /build
# ENTRYPOINT ["qtcreator"]
