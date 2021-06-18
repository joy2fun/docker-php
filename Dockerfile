FROM php:7.3-apache-stretch

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

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        libzip4 \
        libzip-dev \
        libxml2-dev \
# pdo_dblib deps
        #freetds-bin \
        #freetds-dev \
        #freetds-common \
# molten deps
        libcurl3-dev \
        git \
        linux-headers-4.9.0-8-amd64 \
    && ln -sf /usr/lib/x86_64-linux-gnu/libsybdb.so /usr/lib/ \
    && docker-php-source extract \
# configure zip, including install phpize_deps
    && docker-php-ext-configure zip --with-libzip \
# pecl first
    && pecl install ds \
# install hiredis
    && curl -fsSL 'https://github.com/redis/hiredis/archive/v0.13.3.tar.gz' -o hiredis.tar.gz \
    && mkdir -p hiredis \
    && tar -xf hiredis.tar.gz -C hiredis --strip-components=1 \
    && rm hiredis.tar.gz \
    && ( \
        cd hiredis \
        && make -j$(nproc) \
        && make install \
    ) \
    && rm -r hiredis \
    && curl -fsSL 'https://github.com/nrk/phpiredis/archive/v1.0.0.tar.gz' -o phpiredis.tar.gz \
    && mkdir -p phpiredis \
    && tar -xf phpiredis.tar.gz -C phpiredis --strip-components=1 \
    && rm phpiredis.tar.gz \
    && ( \
        cd phpiredis \
        && phpize \
        && ./configure --enable-phpiredis \
        && make -j$(nproc) \
        && make install \
    ) \
    && rm -r phpiredis \
    && docker-php-ext-enable phpiredis \
# molten
    && git clone --depth=1 https://github.com/joy2fun/Molten.git /usr/src/php/ext/molten \
    && docker-php-ext-configure molten --enable-zipkin-header=yes \
    && docker-php-ext-install -j$(nproc) \
      pdo_mysql \
      zip \
      soap \
      molten \
    && docker-php-ext-enable opcache \
    && docker-php-source delete \
    && apt-get remove -y git \
        libzip-dev \
        libxml2-dev \
        freetds-bin \
        freetds-dev \
        freetds-common \
        libcurl3-dev \
        linux-headers-4.9.0-8-amd64 \
    && apt-get purge -y \
    && apt autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
# composer
#    && curl -s https://raw.githubusercontent.com/composer/getcomposer.org/877cb10b101957ef8bbb9d196f711dbb8a011bb4/web/installer | php -- --install-dir=/bin --filename=composer --quiet \
    && echo done!

WORKDIR /app
