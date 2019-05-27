FROM php:7.3

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        zip \
        libzip4 \
        libzip-dev \
        libxml2-dev \
        openssh-client \
# pdo_dblib deps
        #freetds-bin \
        #freetds-dev \
        #freetds-common \
        git \
    && ln -sf /usr/lib/x86_64-linux-gnu/libsybdb.so /usr/lib/ \
    && docker-php-source extract \
# configure zip, including install phpize_deps
    && docker-php-ext-configure zip --with-libzip \
    && docker-php-ext-install -j$(nproc) \
      pdo_mysql \
      zip \
      soap \
    && docker-php-source delete \
    && apt-get remove -y \
        libzip-dev \
        libxml2-dev \
        freetds-bin \
        freetds-dev \
        freetds-common \
    && apt-get purge -y \
    && apt autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
# composer
    && curl -s https://raw.githubusercontent.com/composer/getcomposer.org/877cb10b101957ef8bbb9d196f711dbb8a011bb4/web/installer | php -- --install-dir=/bin --filename=composer --quiet \
    && echo done!

WORKDIR /app

ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /tmp
ENV COMPOSER_VERSION 1.7.3

RUN curl --silent --fail --location --retry 3 --output /tmp/installer.php --url https://raw.githubusercontent.com/composer/getcomposer.org/cb19f2aa3aeaa2006c0cd69a7ef011eb31463067/web/installer \
 && php -r " \
    \$signature = '48e3236262b34d30969dca3c37281b3b4bbe3221bda826ac6a9a62d6444cdb0dcd0615698a5cbe587c3f0fe57a54d8f5'; \
    \$hash = hash('sha384', file_get_contents('/tmp/installer.php')); \
    if (!hash_equals(\$signature, \$hash)) { \
      unlink('/tmp/installer.php'); \
      echo 'Integrity check failed, installer is either corrupt or worse.' . PHP_EOL; \
      exit(1); \
    }" \
 && php /tmp/installer.php --no-ansi --install-dir=/usr/bin --filename=composer --version=${COMPOSER_VERSION} \
 && composer --ansi --version --no-interaction \
 && rm -f /tmp/installer.php

COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/bin/sh", "/docker-entrypoint.sh"]

CMD ["composer"]
