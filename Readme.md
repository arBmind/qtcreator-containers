# Docker images for QtCreator

These docker images allow you to use QtCreator on Linux or WSL2 with Docker, without a lot of setup.

## Options

compilers and standard libraries:
* Clang/libc++
* Clang/libstdc++
* GCC/libstdc++

Qt:
* none (bring your own)
* Qt official builds (using aqtinstall)

## Usage

You can use the image with Docker directly.
You will need to have a X server.

```bash
docker run -it \
    -e DISPLAY=host.docker.internal:0 \
    --mount src="$(pwd)",target=/build,type=bind \
    arbmind/qtcreator-clang-qt:latest \
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
  costaco6:
    image: arbmind/qtcreator-gcc-qt:7.0.0-patched-11-6.2.4
    environment:
      - DISPLAY=host.docker.internal:0
    command: qtcreator Costaco.qbs
    volumes:
      - ./qt624_gcc/:/opt/qt
      - ./repository/:/build
      - tmp:/tmp
```

## Details

The Dockerfile is multi staged and has different targets for all the variants.
All targets with underscores are meant to be internally only.

Targets:
* qtcreator-clang
* qtcreator-clang-libstdcpp
* qtcreator-clang-libstdcpp-qt
* qtcreator-gcc
* qtcreator-gcc-qt

Note: qtcreator-clang-qt is missing because the Qt Company does not publish binaries built for libc++

Each of the targets uses a subset of arguments to determine the versions.

QtCreator is preconfigured to run Gui applications properly.

To support your development the user is non-root.
You may still install extra software with sudo if you need.
