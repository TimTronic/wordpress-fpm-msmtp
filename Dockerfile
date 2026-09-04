FROM wordpress:7-php8.4-fpm

ENV MSMTP_MAILHOST=mailserver
ENV MSMTP_TLS=off
ENV MSMTP_STARTTLS=off
ENV MSMTP_TLS_CERTCHECK=off
ENV MSMTP_AUTH=off
ENV MSMTP_FROM=mailer
ENV MSMTP_PORT=25
ENV MSMTP_LOGFILE=/var/log/msmtp.log

RUN --mount=type=cache,target=/var/cache/apt,sharing=private \
    --mount=type=cache,target=/var/lib/apt,sharing=private \
    DEBIAN_FRONTEND=noninteractive \
    apt-get update && apt-get dist-upgrade -y && apt-get install msmtp rsync gettext-base imagemagick ghostscript poppler-utils --no-install-recommends -y

# phpredis: C client for Redis. WordPress uses it via the Redis Object Cache
# plugin's object-cache.php drop-in, which picks the extension up automatically
# and otherwise falls back to its bundled pure-PHP Predis. CiviCRM can use the
# same extension for its own caches via CIVICRM_DB_CACHE_CLASS.
#
# This only installs the client. Nothing caches until a site adds a redis
# service and opts in, so the image is unchanged for sites that do not.
#
# Kept in sync by hand with the same line on `master`. As with the ImageMagick
# and PDF lines above, these branches are edited independently rather than
# merged, so a change to one needs the same change to the other.
RUN pecl install redis && docker-php-ext-enable redis

ADD https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar /usr/local/bin/wp-cli
ADD https://download.civicrm.org/cv/cv.phar /usr/local/bin/cv
RUN chmod 775 /usr/local/bin/wp-cli && chmod 775 /usr/local/bin/cv && ln -s /usr/local/bin/wp-cli /usr/local/bin/wp

# allow ImageMagick to read/write PDFs (works whether the base ships ImageMagick 6 or 7)
RUN sed -i 's/rights="none" pattern="PDF"/rights="read|write" pattern="PDF"/' /etc/ImageMagick-*/policy.xml || true

COPY tree/ /
# undo any damage caused by copying the overlay
RUN chmod 775 /etc /usr /usr/local /usr/local/bin
ENTRYPOINT ["entrypoint-override.sh"]
CMD ["php-fpm"]
