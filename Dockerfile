FROM php:8.3-apache-bookworm

WORKDIR /var/www/html

# hadolint ignore=DL3008
RUN apt-get update; \
    apt-get install --no-install-recommends -y unzip \
        libfreetype6-dev libicu-dev libjpeg62-turbo-dev libpng-dev libpq-dev \
        libsasl2-dev libssl-dev libwebp-dev libxpm-dev libzip-dev libzstd-dev \
        zlib1g-dev \
    && cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp --with-xpm \
    && docker-php-ext-install -j$(nproc) gd intl pdo_mysql zip pcntl \
    && pecl install redis \
    && docker-php-ext-enable opcache redis \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
        apt-get clean; \
        apt-get autoclean; \
        rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*;

RUN a2enmod rewrite remoteip; \
    sed -ri \
        -e "s/AccessFileName .htaccess/#AccessFileName .htaccess/" \
        -e "s/AllowOverride All/AllowOverride None/g"  \
        -e "s/ServerTokens OS/ServerTokens Prod/g" \
        -e "s/ServerSignature On/ServerSignature Off/g" \
        /etc/apache2/conf-available/*.conf
