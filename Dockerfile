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

# PDF thumbnails: WordPress renders them through Imagick, which shells out to
# Ghostscript. Verified on this base -- convert reads a PDF and writes a PNG.
#
# The sed is defensive, not load-bearing here: this base ships no policy.xml at
# all, so there is no PDF denial to relax. Debian's ImageMagick has carried one
# (rights="none" pattern="PDF", added after the Ghostscript RCEs) and may again,
# in which case the packages above would be installed and the feature still
# would not work. Hence the line, and hence `|| true`.
#
# These three packages and this line already exist on the `civicrm` branch,
# where they are not CiviCRM's -- they are the site's PDF support, which is why
# that image cannot be treated as "the plain one plus CiviCRM".
RUN sed -i 's/rights="none" pattern="PDF"/rights="read|write" pattern="PDF"/' /etc/ImageMagick-*/policy.xml || true

# phpredis: PHP client for a persistent object cache (Redis Object Cache plugin,
# `object-cache.php` drop-in). Each site still runs its own `redis` service in
# compose; this only makes the fast C client available so the plugin does not
# fall back to bundled Predis.
RUN pecl install redis && docker-php-ext-enable redis

ADD https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar /usr/local/bin/wp
RUN chmod 775 /usr/local/bin/wp

COPY tree/ /
ENTRYPOINT ["entrypoint-override.sh"]
CMD ["php-fpm"]
