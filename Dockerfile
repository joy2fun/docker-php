FROM php:8.1-apache-bookworm

WORKDIR /var/www/html

COPY php/zzz.ini /usr/local/etc/php/conf.d/zzz.ini
COPY apache2/sites-enabled/000-default.conf /etc/apache2/sites-enabled/000-default.conf

RUN sed -ri \
    -e "s/AccessFileName .htaccess/#AccessFileName .htaccess/" \
    -e "s/AllowOverride All/AllowOverride None/g"  \
    -e "s/ServerTokens OS/ServerTokens Prod/g" \
    -e "s/ServerSignature On/ServerSignature Off/g" \
    /etc/apache2/conf-available/*.conf

RUN curl -o /usr/local/bin/composer https://getcomposer.org/download/latest-stable/composer.phar \
    && chmod +x /usr/local/bin/composer

# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
    cron \
    icu-devtools \
    jq \
    libfreetype6-dev libicu-dev libjpeg62-turbo-dev libpng-dev libpq-dev \
    libsasl2-dev libssl-dev libwebp-dev libxpm-dev libzip-dev libzstd-dev \
    unzip \
    zlib1g-dev \
    && apt-get clean \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# hadolint ignore=DL3059
RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp --with-xpm \
    && docker-php-ext-install gd intl pdo_mysql zip \
    && docker-php-ext-enable opcache \
    && a2enmod rewrite remoteip 
