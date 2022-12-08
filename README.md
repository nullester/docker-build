# Docker Build

This package makes building Docker images a little more easy.

## Installation

Clone this repository locally. For example in _~/.docker/.build_ which I use for all my Docker images.

In this _.docker_ folder I keep my _docker-compose.yml_ file.

BASH installation example
```bash
curl -s https://raw.githubusercontent.com/nullester/docker-build/master/install.sh | bash
```

## Building

Within this local _.docker/.build_ folder, clone any git repository that has a _Dockerfile_.

__IMPORTANT: Make sure the folder name matches the image name!__

### Suggested images to install

*Ubuntu*

```bash
git clone git@github.com:nullester/docker-ubuntu.git ~/.docker/.build/ubuntu
```

*Linux/Apache2/PHP server*

```bash
git clone git@github.com:nullester/docker-lap.git ~/.docker/.build/lap
```

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

#### -m "acme" / --maintainer="acme"

Sets the maintainer name.

```bash
./build.sh -m "acme"
./build.sh --maintainer="acme"
```

## Typical full example

```bash
./update.sh && ./build.sh -y -q --maintainer="acme" ubuntu lap:7.4
```
