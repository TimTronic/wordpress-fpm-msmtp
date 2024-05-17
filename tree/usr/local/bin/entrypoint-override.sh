#!/bin/bash

envsubst < /etc/msmtprc.template > /etc/msmtprc
/usr/local/bin/docker-entrypoint.sh $@
