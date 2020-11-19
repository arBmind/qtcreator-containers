# Docker image with QtCreator, Clang and Qt

This docker image is used to develop on WSL2 with Docker.

The image contains a clang and libc++ as the main compiler setup.
The latest Qt is installed as well.

QtCreator is preconfigured to run Gui applications properly.
The main user can install missing packages with sudo.

## Usage

Default entrypoint is bash

```bash
docker run -it \
    --mount src="$(pwd)",target=/build,type=bind \
    qtcreator-clang:latest \
    qtcreator myproject.qbs
```

This mounts your current directory to `/build` in the container and starts qtcreator with your project file.
