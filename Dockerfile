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
# `pecl install` alone is flaky here. civicrm build #18 failed on
# "No releases available for package \"pecl.php.net/redis\"" after a 61s stall,
# while the identical line succeeded on master #20 minutes later -- a transient
# failure to fetch the channel's package list, not a missing package. So:
# refresh the channel first, retry, and verify the extension actually loaded
# rather than trusting the exit code. A silently absent phpredis would not break
# a site (the plugin falls back to Predis), which is exactly why the build has
# to be the thing that catches it.
RUN set -eux; \
    ok=; \
    for i in 1 2 3; do \
      if pecl channel-update pecl.php.net && pecl install redis; then ok=1; break; fi; \
      echo "pecl install redis failed (attempt $i of 3), retrying in 10s"; \
      sleep 10; \
    done; \
    [ -n "$ok" ]; \
    docker-php-ext-enable redis; \
    php --ri redis >/dev/null

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
