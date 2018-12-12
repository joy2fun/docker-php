FROM php:7.3-fpm-alpine

#RUN sed -i -e "s/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g" /etc/apk/repositories
RUN apk add --no-cache --virtual .build-deps \
        tzdata \
        linux-headers \
        libzip-dev \
        curl-dev \
        git \
    && apk add --no-cache --virtual .persistent-deps \
        libzip \
        unzip \
# user & group
    && addgroup -g 3000 -S app \
    && adduser -u 3000 -S -D -G app app \
# timezone
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && docker-php-source extract \
# configure zip, including install phpize_deps
    && docker-php-ext-configure zip --with-libzip \
# pecl first
    && pecl install ds \
# phpiredis
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
# molten
    && git clone --depth=1 https://github.com/chuan-yun/Molten.git /usr/src/php/ext/molten \
    && docker-php-ext-configure molten --enable-zipkin-header=yes \
# install exts
    && docker-php-ext-install -j$(nproc) zip pdo_mysql molten \
    && docker-php-source delete \
    && apk del .build-deps \
# composer
    && curl -s https://raw.githubusercontent.com/composer/getcomposer.org/877cb10b101957ef8bbb9d196f711dbb8a011bb4/web/installer | php -- --install-dir=/bin --filename=composer --quiet \
    && echo done!

WORKDIR /app

