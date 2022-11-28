# Docker Build

This package makes building Docker images a little more easy.

## Installation

Clone this repository locally. For example in _~/.docker_ which I use for all my Docker images.

In this folder I also keep my _docker-compose.yml_ file.

BASH installation example
```bash
[[ ! -d ~/.docker ]] && \
git clone git@github.com:nullester/docker-build.git ~/.docker && \
git clone git@github.com:nullester/docker-ubuntu.git ~/.docker/ubuntu && \
git clone git@github.com:nullester/docker-lap.git ~/.docker/lap
```

### Images

If you want all my docker images, run this command within your _.docker_ folder

```bash
git clone git@github.com:nullester/docker-ubuntu.git ubuntu && \
git clone git@github.com:nullester/docker-lap.git lap
```

## Building

Within this local _.docker_ folder, clone any git repository that has a _Dockerfile_.

__IMPORTANT: Make sure the folder name matches the image name!__

Then run command:

```bash
./build.sh <the-docker-name> <optionally-another-name:optional-release>
```

If no image names were provided, the build command will try to build all known images in correct order.

```bash
./build.sh
```

### build.sh options

#### -c

Enables the cache mode.

```bash
./build.sh -c
```

#### -y

Enables the yes-to-all mode.

```bash
./build.sh -y
```

#### -q

Enables the quiet build mode.

```bash
./build.sh -q
```

#### --maintainer="acme"

Sets the maintainer name.

```bash
./build.sh --maintainer="acme"
```

## Typical full example

```bash
./update.sh && ./build.sh -y -q --maintainer="acme" ubuntu lap:7.4 fw:7.4 laravel
```
