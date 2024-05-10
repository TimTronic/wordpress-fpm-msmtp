Simple Docker image for the latest wordpress-fpm image that has built in smtp mailing capability via environment variable configuration.

Example:
```
# host to connect to
MSMTP_MAILHOST=mail.example.org
MSMTP_PORT=587
# domain to announce as when connecting
MSMTP_DOMAIN=example.org
# credentials
MSMTP_USER=mailer@example.org
MSMTP_PASSWORD=<plain text password>
```
