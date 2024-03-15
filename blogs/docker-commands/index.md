---
title: Docker commands
abstract: Docker (`docker`) commands I frequently use.
date: 2024-01-31
categories: [shell]
---

# Building a docker image

```sh
docker build -t foobarbaz .
```

Build an image using the `Dockerfile` in the current working
directory, and *tag* it as `foobarbaz`.

# Running arbitrary commands inside a container

```sh
docker run --rm -it -v "$(pwd):/app" --cpus 8.0 --memory 320000000000 foobarbaz ./bin/my-script.bash
```

1. Run `bin/my-script.bash` inside a container created from the
   foobarbaz image.
2. Remove the container automatically after the script finishes (with
   the `--rm` flag).
3. Connect the current tty with the container (with the `-it` flags).
4. And connect the current working directory with the `/app` directory
   inside the container (with the `-v` flag). This assumes that the
   `WORKDIR` has been set to `/app` in the `Dockerfile`.
5. Restrict the number of cpus to 8 cores and and 32GB memory used by
   the container (using the `--cpus` and `--memory` flags
   respectively).

# Cleanup

```sh
docker system prune --all
```

Removes all:
1. stopped containers
2. networks not used by at least 1 container
3. dangling images
4. dangling build caches
