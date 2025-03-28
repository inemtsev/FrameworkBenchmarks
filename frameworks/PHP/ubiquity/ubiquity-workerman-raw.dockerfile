FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -yqq && apt-get install -yqq software-properties-common > /dev/null
RUN LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php
RUN apt-get update -yqq > /dev/null && \
    apt-get install -yqq git php8.4-cli php8.4-pgsql php8.4-xml php8.4-mbstring > /dev/null

COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

RUN apt-get install -y php-pear php8.4-dev libevent-dev > /dev/null
RUN pecl install event-3.1.4 > /dev/null && echo "extension=event.so" > /etc/php/8.4/cli/conf.d/event.ini

COPY deploy/conf/php-async.ini /etc/php/8.4/cli/php.ini

ADD ./ /ubiquity
WORKDIR /ubiquity

RUN chmod -R 777 /ubiquity

RUN apt-get update -yqq > /dev/null && \
    apt-get install -yqq git unzip > /dev/null

RUN composer require phpmv/ubiquity-devtools:dev-master phpmv/ubiquity-workerman:dev-master --quiet

RUN composer install --optimize-autoloader --classmap-authoritative --no-dev --quiet

RUN chmod 777 -R /ubiquity/.ubiquity/*

COPY deploy/conf/workerman/pgsql/raw/workerServices.php app/config/workerServices.php

RUN echo "opcache.preload=/ubiquity/app/config/preloader.script.php\n" >> /etc/php/8.4/cli/php.ini
RUN echo "opcache.jit_buffer_size=128M\nopcache.jit=tracing\n" >> /etc/php/8.4/cli/php.ini

EXPOSE 8080

CMD /ubiquity/vendor/bin/Ubiquity serve -t=workerman -p=8080 -h=0.0.0.0
