# Homebrew template

Provisioned from [`Qode-Fleet-Control/fleet-template-v1`](https://github.com/Qode-Fleet-Control/fleet-template-v1) — the fleet
lifecycle contract (`bin/`, `fleet.conf`, `compose.yaml`, deploy workflows) with a
Homebrew starter laid on top. **A job, not a service**: the image's default command runs the
check and exits 0 on success; nothing listens on `$PORT`.

## What it is

A `Brewfile` installed with [Homebrew on Linux](https://docs.brew.sh/Homebrew-on-Linux)
in the image, and a job that proves it is satisfied:

| path | what |
|---|---|
| `Brewfile` | the packages: `hello`, `tree` (two tiny bottles) |
| `scripts/check.sh` | **the job**: `brew bundle check --verbose`, every formula installed, and the tools run |

Add a formula to the `Brewfile` and rebuild; keep it to bottles (no compiler in the image).

## Run it

**With docker** (what the fleet does):

    docker compose build                 # installs Homebrew, then `brew bundle install`
    docker compose run --rm app          # the check; exit 0 = Brewfile satisfied
    docker compose run --rm app brew bundle list

**Without docker** (needs Homebrew, macOS or Linux):

    brew bundle install --file=Brewfile  # = fleet.conf INSTALL_CMD
    sh scripts/check.sh

## Origin

Homebrew's official installer (Homebrew/install, pinned to commit
`35da6871c4be7d7fdab2fd505fb7fa667926a2a5`) run as a non-root user, then Homebrew's
own bundle command:

    NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/<commit>/install.sh)"
    brew bundle install --file=Brewfile

The `Brewfile` is hand-written (`brew bundle dump` writes the same format).

## Deviations from stock output, and why

- **Not `FROM homebrew/brew`.** The official image is ~1.5 GB compressed (it carries a
  full build toolchain). This image is `debian:bookworm-slim` with Homebrew's runtime
  requirements (`curl file git procps`) and no `build-essential`: everything in the
  Brewfile is a bottle.
- The installer creates `/home/linuxbrew/.linuxbrew` without sudo because the Dockerfile
  makes `/home/linuxbrew` writable by the non-root user first.
- `HOMEBREW_NO_AUTO_UPDATE=1`: the job checks what the image installed instead of
  updating Homebrew at run time. Formula versions are whatever Homebrew's API serves at
  build time (Brewfiles pin names, not versions).
## Verified

**The docker image has NOT been built or run yet**: on 2026-10-05 the shared build host's docker disk was full (0-2 GB free for over 8 hours), so `docker compose build` was never attempted. Run `docker compose build && docker compose run --rm app` once before trusting it.

Without docker it has not been run either: Homebrew is not installed on the build host.
Nothing in this template has been executed yet.


## Fleet lifecycle

`fleet.conf` drives every script in `bin/` (see `docs/fleet-lifecycle.md`). On the fleet
the docker runtime runs `DOCKER_BUILD_CMD` (`docker compose build`) and, because this is
a job and not a service, stops there: `DOCKER_START_CMD` is empty, the same as
`START_CMD`. Run the job itself with `docker compose run --rm app`.

    ./bin/run                    # docker runtime: builds the image, then stops (no server)
    docker compose run --rm app  # runs the job; exit code 0 = pass
    FLEET_RUNTIME=process ./bin/run   # no docker: runs INSTALL_CMD, then stops at start

`bin/run` ends with the template's own "no START_CMD" message — that is intentional.

## Serving over HTTP

Fleet apps are served at the root of their own hostname
(`https://<hash>.<FLEET_APP_DOMAIN>/`). **This repo has no HTTP surface**: `PORT`,
`HEALTH_PATH` and `START_CMD` are empty and `compose.yaml` publishes nothing. If you add
an HTTP endpoint, listen on `0.0.0.0:$PORT` (read at runtime), serve at `/`, set `PORT`,
`HEALTH_PATH`, `START_CMD` and `DOCKER_START_CMD='docker compose up --remove-orphans'`
in `fleet.conf`, and publish `"${PORT:-N}:${PORT:-N}"` in `compose.yaml`.

`compose.yaml` passes the fleet's variables (`DATABASE_URL`, `REDIS_URL`, `S3_*`,
`SMTP_*` …) through to the container without values; this template reads none of them.
