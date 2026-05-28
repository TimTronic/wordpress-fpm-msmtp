#!/bin/bash

envsubst < /etc/msmtprc.template > /etc/msmtprc

# Install/refresh bundled must-use plugins into the (often bind-mounted) webroot
# so base-image WordPress fixes (e.g. the loopback session-lock fix) reach every
# site. Runs before docker-entrypoint.sh, so it works whether the volume is
# empty (first run) or already populated. cp -f keeps the base-image copy
# authoritative; failures here must never block container startup.
if ls /usr/src/wp-mu-plugins/*.php >/dev/null 2>&1; then
    mkdir -p /var/www/html/wp-content/mu-plugins
    cp -f /usr/src/wp-mu-plugins/*.php /var/www/html/wp-content/mu-plugins/ || true
    chown -R www-data:www-data /var/www/html/wp-content/mu-plugins 2>/dev/null || true
fi

/usr/local/bin/docker-entrypoint.sh $@
