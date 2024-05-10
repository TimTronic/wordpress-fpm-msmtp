#!/bin/bash

envsubst < /etc/msmtprc.template > /etc/msmtprc
php-fpm
