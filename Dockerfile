# Built by .github/workflows/deploy.yml (context ., file Dockerfile) and pushed
# to Artifact Registry.
#
# A job image, not a server: Homebrew on Linux, installed with its OFFICIAL installer
# (Homebrew/install, pinned commit) into the default prefix /home/linuxbrew/.linuxbrew
# for a non-root user, then the Brewfile installed with `brew bundle install`. The default
# command runs `brew bundle check` and the installed tools (scripts/check.sh) and exits 0
# when the Brewfile is satisfied.
#
# Why not FROM homebrew/brew: that image is ~1.5 GB compressed (it carries a full build
# toolchain); this one installs only what the Brewfile's bottles need.

FROM debian:bookworm-slim
ARG BUILD_ID=""
ARG BREW_INSTALL_REF=35da6871c4be7d7fdab2fd505fb7fa667926a2a5
# Homebrew on Linux requirements (docs.brew.sh/Homebrew-on-Linux), minus build-essential:
# bottles need no compiler.
RUN apt-get update \
 && apt-get install -y --no-install-recommends bash ca-certificates curl file git procps \
 && rm -rf /var/lib/apt/lists/*
# The installer creates the prefix without sudo when its parent is writable by the user.
RUN useradd -m -u 10001 -s /bin/bash app \
 && mkdir -p /home/linuxbrew /app && chown app:app /home/linuxbrew /app
USER app
ENV HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_ENV_HINTS=1
RUN NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/$BREW_INSTALL_REF/install.sh)"
ENV PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH

WORKDIR /app
COPY --chown=app:app Brewfile ./
RUN brew bundle install --file=Brewfile \
 && brew cleanup --prune=all -s \
 && rm -rf "$(brew --cache)"
COPY --chown=app:app . .
ENV BUILD_ID=$BUILD_ID
CMD ["sh", "scripts/check.sh"]
