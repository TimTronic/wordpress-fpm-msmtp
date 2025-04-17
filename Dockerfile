FROM wordpress:6-php8.3-fpm

ENV MSMTP_MAILHOST=mailserver
ENV MSMTP_TLS=off
ENV MSMTP_STARTTLS=off
ENV MSMTP_TLS_CERTCHECK=off
ENV MSMTP_AUTH=off
ENV MSMTP_FROM=mailer
ENV MSMTP_PORT=25
ENV MSMTP_LOGFILE=/var/log/msmtp.log

RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    DEBIAN_FRONTEND=noninteractive \
    apt-get update && apt-get dist-upgrade -y && apt-get install msmtp rsync gettext-base imagemagick ghostscript poppler-utils --no-install-recommends -y

ADD https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar /usr/local/bin/wp-cli
ADD https://download.civicrm.org/cv/cv.phar /usr/local/bin/cv
RUN chmod 775 /usr/local/bin/wp-cli && chmod 775 /usr/local/bin/cv && ln -s /usr/local/bin/wp-cli /usr/local/bin/wp

# modify the ImageMagick security policy to allow PDF conversion
RUN perl -pi -e 's#<policy domain="coder" rights="none" pattern="PDF" />#<policy domain="coder" rights="read|write" pattern="PDF" />#' /etc/ImageMagick-*/policy.xml

COPY tree/ /
# undo any damage caused by copying the overlay
RUN chmod 775 /etc /usr /usr/local /usr/local/bin
ENTRYPOINT ["entrypoint-override.sh"]
CMD ["php-fpm"]
