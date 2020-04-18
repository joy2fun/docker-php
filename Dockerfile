FROM php:laravel

COPY sources.list /etc/apt/sources.list
COPY mod_xsendfile.c /tmp/mod_xsendfile.c

RUN cat /etc/apt/sources.list

RUN apt-get update \
    && apt-get install -y --no-install-recommends apache2-dev \
    && apxs -cia /tmp/mod_xsendfile.c \
    && apt-get remove -y \
        apache2-dev \
    && apt-get purge -y \
    && apt autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && echo done!

