#!/bin/sh
set -eu
version="$1"
sha="$2"
if php -r 'exit(version_compare(PHP_VERSION, $argv[1], ">=") ? 0 : 1);' "$version"; then exit 0; fi
php -m | sort > /tmp/php-modules-before
options="$(php-config --configure-options)"
options="${options%% build_alias=*}"
if command -v apk >/dev/null; then
    apk add --no-cache autoconf dpkg-dev dpkg file g++ gcc libc-dev make pkgconf re2c argon2-dev curl-dev oniguruma-dev readline-dev libsodium-dev sqlite-dev openssl-dev libxml2-dev zlib-dev linux-headers gnu-libiconv-dev
else
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends autoconf dpkg-dev file g++ gcc libc6-dev make pkg-config re2c libargon2-dev libcurl4-openssl-dev libonig-dev libreadline-dev libsodium-dev libsqlite3-dev libssl-dev libxml2-dev zlib1g-dev
    case "$options" in *--with-apxs2*) DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends apache2-dev ;; esac
fi
mkdir -p /usr/src/php-security
cd /usr/src/php-security
curl -fsSL "https://www.php.net/distributions/php-$version.tar.xz" -o php.tar.xz
echo "$sha  php.tar.xz" | sha256sum -c -
tar -xJf php.tar.xz --strip-components=1
./configure $options
make -j8
make install
cp php.tar.xz /usr/src/php.tar.xz
rm -rf /usr/src/php
php -v
php -m | sort > /tmp/php-modules-after
if ! diff -u /tmp/php-modules-before /tmp/php-modules-after; then
    echo 'PHP module list changed unexpectedly' >&2
    exit 1
fi
php -r 'exit(PHP_VERSION === $argv[1] ? 0 : 1);' "$version"
rm -rf /usr/src/php-security /var/lib/apt/lists/* /tmp/php-modules-before /tmp/php-modules-after
