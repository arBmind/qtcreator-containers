# Docker images for QtCreator

This project builds Docker images with QtCreator and various compilers used to build and debug C++ and Gui applications using WSL and Docker.

| Image (latest versions) | Size |
| -- | -- |
| [![Docker Image Version (latest semver)](https://img.shields.io/docker/v/arbmind/qtcreator-clang?color=black&label=arbmind%2Fqtcreator-clang&logo=Docker&sort=semver)](https://hub.docker.com/r/arbmind/qtcreator-clang) | [![Docker Image Size (latest semver)](https://img.shields.io/docker/image-size/arbmind/qtcreator-clang?color=g&logo=Ubuntu&sort=semver)](https://hub.docker.com/r/arbmind/qtcreator-clang) |
| [![Docker Image Version (latest semver)](https://img.shields.io/docker/v/arbmind/qtcreator-clang-libstdcpp?color=black&label=arbmind%2Fqtcreator-clang-libstdcpp&logo=Docker&sort=semver)](https://hub.docker.com/r/arbmind/qtcreator-clang-libstdcpp) | [![Docker Image Size (latest semver)](https://img.shields.io/docker/image-size/arbmind/qtcreator-clang-libstdcpp?color=green&logo=Ubuntu&sort=semver)](https://hub.docker.com/r/arbmind/qtcreator-clang-libstdcpp) |
| [![Docker Image Version (latest semver)](https://img.shields.io/docker/v/arbmind/qtcreator-clang-libstdcpp-qt?color=black&label=arbmind%2Fqtcreator-clang-libstdcpp-qt&logo=Docker&sort=semver)](https://hub.docker.com/r/arbmind/qtcreator-clang-libstdcpp-qt) | [![Docker Image Size (latest semver)](https://img.shields.io/docker/image-size/arbmind/qtcreator-clang-libstdcpp-qt?color=yellow&logo=Ubuntu&sort=semver)](https://hub.docker.com/r/arbmind/qtcreator-clang-libstdcpp-qt) |
| [![Docker Image Version (latest semver)](https://img.shields.io/docker/v/arbmind/qtcreator-gcc?color=black&label=arbmind%2Fqtcreator-gcc&logo=Docker&sort=semver)](https://hub.docker.com/r/arbmind/qtcreator-gcc) | [![Docker Image Size (latest semver)](https://img.shields.io/docker/image-size/arbmind/qtcreator-gcc?color=green&logo=Ubuntu&sort=semver)](https://hub.docker.com/r/arbmind/qtcreator-gcc) |
| [![Docker Image Version (latest semver)](https://img.shields.io/docker/v/arbmind/qtcreator-gcc-qt?color=black&label=arbmind%2Fqtcreator-gcc-qt&logo=Docker&sort=semver)](https://hub.docker.com/r/arbmind/qtcreator-gcc-qt) | [![Docker Image Size (latest semver)](https://img.shields.io/docker/image-size/arbmind/qtcreator-gcc-qt?color=red&logo=Ubuntu&sort=semver)](https://hub.docker.com/r/arbmind/qtcreator-gcc-qt) |

## Usage

Prerequiste: X server (Linux with X, Win11 or [VcXsrv](https://sourceforge.net/projects/vcxsrv/))

To run on Windows 11 you need to mount some special directories to enable fast graphics rendering and X11 communications.

```bash
docker run -it \
    --mount src=/tmp/.X11-unix,target=/tmp/.X11-unix,type=bind \
    --mount src=/mnt/wslg,target=/mnt/wslg,type=bind \
    -e WAYLAND_DISPLAY=wayland-0 \
    -e XDG_RUNTIME_DIR=/mnt/wslg/runtime-dir \
    --mount src="$(pwd)",target=/build,type=bind \
    arbmind/qtcreator-gcc-qt:latest \
    qtcreator myproject.qbs
```

To use clang instead of gcc use this:

```bash
docker run -it \
    --mount src=/tmp/.X11-unix,target=/tmp/.X11-unix,type=bind \
    --mount src=/mnt/wslg,target=/mnt/wslg,type=bind \
    -e WAYLAND_DISPLAY=wayland-0 \
    -e XDG_RUNTIME_DIR=/mnt/wslg/runtime-dir \
    --mount src="$(pwd)",target=/build,type=bind \
    arbmind/qtcreator-clang-libstdcpp-qt:latest \
    qtcreator myproject.qbs
```

Description:
* define the display variable to use Docker
* mount the current directory to the `/build` folder
* use the `qtcreator-clang-qt` image in the latest variant
* start the qtcreator with `myproject.qbs`

If you want to do more work on the project, we recommend to use a docker-compose.

```yaml
version: "3.7"

volumes:
  tmp: # cached builds

services:
  myproject:
    image: arbmind/qtcreator-gcc-qt:latest
    cap_add: [SYS_PTRACE] # needed for lldb debugging
    security_opt: [seccomp=unconfined] # needed for lldb debugging
    environment:
      - WAYLAND_DISPLAY=wayland-0
      - XDG_RUNTIME_DIR=/mnt/wslg/runtime-dir
    command: qtcreator myproject.qbs
    volumes:
      - /tmp/.X11-unix:/tmp/.X11-unix
      - /mnt/wslg:/mnt/wslg
      - ./repository/:/build
      - tmp:/tmp
```

## Details

The Dockerfile is multi staged and has different targets for all the variants.
All targets with underscores are meant to be internally only.

Note: The Clang Qt combination is missing because the Qt Company does not publish binaries built for libc++

QtCreator is preconfigured to run Gui applications properly.

To support your development the user is non-root.
You may still install extra software with sudo if you need.
