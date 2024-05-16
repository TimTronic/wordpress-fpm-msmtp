FROM wordpress:6-php8.1-fpm

ENV MSMTP_TLS=off
ENV MSMTP_STARTTLS=off
ENV MSMTP_TLS_CERTCHECK=off
ENV MSMTP_AUTH=off
ENV MSMTP_FROM=mailer
ENV MSMTP_PORT=25
ENV MSMTP_LOGFILE=/var/log/msmtp.log

RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    apt-get update && apt-get dist-upgrade -y && apt-get install msmtp rsync gettext-base --no-install-recommends -y
   
COPY tree/ /
CMD cmd-override.sh
