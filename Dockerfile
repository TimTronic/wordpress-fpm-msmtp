FROM wordpress:6-php8.1-fpm

RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    apt-get update && apt-get dist-upgrade -y && apt-get install msmtp rsync gettext-base --no-install-recommends -y

COPY tree/ /
CMD cmd-override.sh
