
# based on php:7.x-apache

 - disabled .htaccess
 - default timezone: PRC
 - doc root & workdir: /app
 - ali-apt to use aliyun sources.list

## Laravel

```Dockerfile
FROM joy2fun/php:apache

RUN cp -f /etc/apache2/laravel-apache2.conf /etc/apache2/apache2.conf

COPY --chown=www-data:www-data /path/to/src/. /app
```

