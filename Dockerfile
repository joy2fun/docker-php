FROM arm64v8/php:apache

ENV APACHE_DOCUMENT_ROOT /app

COPY laravel-apache2.conf /etc/apache2/apache2.conf

RUN mkdir ${APACHE_DOCUMENT_ROOT} && chown -R www-data:www-data ${APACHE_DOCUMENT_ROOT} \
    && sed -ri \
        -e "s/AccessFileName .htaccess/#AccessFileName .htaccess/" \
        -e "s/AllowOverride All/AllowOverride None/g"  \
        -e "s/ServerTokens OS/ServerTokens Prod/g" \
        -e "s/ServerSignature On/ServerSignature Off/g" \
        /etc/apache2/conf-available/*.conf \
    && sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' \
        /etc/apache2/apache2.conf \
        /etc/apache2/conf-available/*.conf \
        /etc/apache2/sites-enabled/*.conf

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        libzip4 \
        libzip-dev \
        libxml2-dev \
    && docker-php-source extract \
# configure zip, including install phpize_deps
    && docker-php-ext-configure zip --with-libzip \
# pecl first
    && docker-php-ext-install -j$(nproc) \
      pdo_mysql \
      zip \
      soap \
    && docker-php-ext-enable opcache \
    && docker-php-source delete \
    && apt-get remove -y \
        libzip-dev \
    && apt-get purge -y \
    && apt autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && echo done!

WORKDIR /app

