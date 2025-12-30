FROM alpine:latest
WORKDIR /var/www/html/
RUN echo "UTC" > /etc/timezone
RUN apk add --no-cache zip unzip curl sqlite nginx supervisor 
RUN apk add bash
RUN sed -i 's/bin\/ash/bin\/bash/g' /etc/passwd
RUN apk add --no-cache php83 \
    php83-common \
    php83-fpm \
    php83-pdo \
    php83-opcache \
    php83-zip \
    php83-phar \
    php83-iconv \
    php83-cli \
    php83-curl \
    php83-openssl \
    php83-mbstring \
    php83-tokenizer \
    php83-fileinfo \
    php83-json \
    php83-xml \
    php83-xmlwriter \
    php83-simplexml \
    php83-dom \
    php83-pdo_mysql \
    php83-pdo_sqlite \
    php83-pecl-redis 
RUN ln -s /usr/bin/php83 /usr/bin/php
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer
RUN mkdir -p /etc/supervisor.d/
COPY .docker/supervisord.ini /etc/supervisor.d/supervisord.ini
RUN mkdir -p /run/php/
RUN touch /run/php/php8.0-fpm.pid
COPY .docker/php-fpm.conf /etc/php83/php-fpm.conf
COPY .docker/php.ini-production /etc/php83/php.ini
COPY .docker/nginx.conf /etc/nginx/
COPY .docker/nginx-laravel.conf /etc/nginx/modules/
RUN rm -f /etc/nginx/http.d/default.conf
RUN mkdir -p /run/nginx/
RUN touch /run/nginx/nginx.pid
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log
COPY . .
RUN composer install --no-dev
RUN composer install \
    --ignore-platform-reqs \
    --no-interaction \
    --no-plugins \
    --no-scripts \
    --prefer-dist \
    --no-dev
RUN chown -R nobody:nobody /var/www/html/storage
RUN mkdir /data
RUN chown nobody:nobody /data
VOLUME /data
EXPOSE 80
CMD ["supervisord", "-c", "/etc/supervisor.d/supervisord.ini"]
