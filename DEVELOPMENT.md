# Windrose Dedicated Server — Development

This document covers local Podman development, image builds, and CI workflows. For production setup and daily operations, see [README.md](README.md).

## Table of contents

- [Local development quick start](#local-development-quick-start)
- [Fast local test](#fast-local-test)
- [Developer image channels](#developer-image-channels)
- [Local smoke build commands](#local-smoke-build-commands)
- [Build and release workflows](#build-and-release-workflows)
- [Environment for local testing](#environment-for-local-testing)

---

## Local development quick start

Most users can skip this section. Use the dev override only when you want to test local changes to the image or startup scripts:

```bash
# Build locally and start with the dev override
podman build --pull=missing -t localhost/windrose-ds:dev .
podman compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Restart after editing scripts/entrypoint.sh or scripts/healthcheck.sh
podman compose -f docker-compose.yml -f docker-compose.dev.yml restart windrose

# Stop the dev stack
podman compose -f docker-compose.yml -f docker-compose.dev.yml down
```

Both Compose files use local images. The dev override mounts local scripts for development and never pulls an image.

---

## Fast local test

Use this flow when you want to test local changes immediately without committing or contacting an image registry:

```bash
# 1) Build local image from current working tree
podman build --pull=missing -t localhost/windrose-ds:dev .

# 2) Start with the locally built image
podman compose -f docker-compose.yml -f docker-compose.dev.yml up -d windrose

# 3) Watch startup logs
podman compose -f docker-compose.yml -f docker-compose.dev.yml logs -f windrose
```

Notes:

- `docker-compose.dev.yml` sets a `localhost/windrose-ds:dev` image and `pull_policy: never`, so Compose uses your local build.
- This keeps existing mounted data (`./data`, `./steam-home`) and does not require any Git push/tag workflow.
- Canonical runtime scripts are mounted from `./scripts` to `/opt/windrose/scripts`.
- Root `entrypoint.sh` and `healthcheck.sh` are compatibility wrappers and are not the canonical runtime implementation.
- If you only changed files in `./scripts`, a rebuild is not required. Use:

```bash
podman compose -f docker-compose.yml -f docker-compose.dev.yml restart windrose
```

---

## Developer image channels

These channels are built automatically from the `main` branch but remain local to the CI runner.

- `dev`, `dev-staging`, `dev-debug`: build-only validation channels from the `main` branch.

---

## Local smoke build commands

Use these commands when you want to verify all image variants locally before pushing changes:

```bash
# stable
podman build \
   --build-arg WINE_FLAVOR=stable \
   --build-arg ENABLE_WINETRICKS=false \
   --build-arg INSTALL_DEBUG_TOOLS=false \
   --build-arg DEFAULT_WINEDEBUG=-all \
   -t windrose-smoke:stable .

# staging
podman build \
   --build-arg WINE_FLAVOR=staging \
   --build-arg ENABLE_WINETRICKS=true \
   --build-arg WINETRICKS_PACKAGES='win10 vcrun2022' \
   --build-arg INSTALL_DEBUG_TOOLS=false \
   --build-arg DEFAULT_WINEDEBUG=-all \
   -t windrose-smoke:staging .

# debug
podman build \
   --build-arg WINE_FLAVOR=stable \
   --build-arg ENABLE_WINETRICKS=false \
   --build-arg INSTALL_DEBUG_TOOLS=true \
   --build-arg DEFAULT_WINEDEBUG='warn+timestamp' \
   -t windrose-smoke:debug .
```

---

## Build and release workflows

- [`.github/workflows/ci.yml`](.github/workflows/ci.yml): validates shell syntax and builds the stable, staging, and debug images in CI.
- [`.github/workflows/docker-developer.yml`](.github/workflows/docker-developer.yml): build-only developer validation from `main`.
- [`.github/workflows/docker-publish.yml`](.github/workflows/docker-publish.yml): build-only release validation from version tags; it never publishes.

---

## Environment for local testing

Copy `.env.dev.example` to `.env` for local development and notifier testing:

```bash
cp .env.dev.example .env
```
