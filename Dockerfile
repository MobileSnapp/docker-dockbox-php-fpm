###############################
# Dockerfile for PHP-FPM image
###############################
# Base image
FROM php:7-fpm

# Author: MobileSnapp Inc.
MAINTAINER MobileSnapp <support@mobilesnapp.com>

# Install dotdeb repo, PHP, composer and selected extensions
RUN apt-get update \
    && apt-get install -y curl \
    && echo "deb http://packages.dotdeb.org jessie all" > /etc/apt/sources.list.d/dotdeb.list \
    && curl -sS https://www.dotdeb.org/dotdeb.gpg | apt-key add - \
    && apt-get update \
    && apt-get -y --no-install-recommends install php7.0-cli php7.0-fpm php7.0-apcu php7.0-apcu-bc php7.0-curl php7.0-json php7.0-mcrypt php7.0-opcache php7.0-readline \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# Configure FPM to run properly on docker
RUN sed -i "/listen = .*/c\listen = [::]:9000" /etc/php/7.0/fpm/pool.d/www.conf \
    && sed -i "/;access.log = .*/c\access.log = /proc/self/fd/2" /etc/php/7.0/fpm/pool.d/www.conf \
    && sed -i "/;clear_env = .*/c\clear_env = no" /etc/php/7.0/fpm/pool.d/www.conf \
    && sed -i "/;catch_workers_output = .*/c\catch_workers_output = yes" /etc/php/7.0/fpm/pool.d/www.conf \
    && sed -i "/pid = .*/c\;pid = /run/php/php7.0-fpm.pid" /etc/php/7.0/fpm/php-fpm.conf \
    && sed -i "/;daemonize = .*/c\daemonize = no" /etc/php/7.0/fpm/php-fpm.conf \
    && sed -i "/error_log = .*/c\error_log = /proc/self/fd/2" /etc/php/7.0/fpm/php-fpm.conf \
    && usermod -u 1000 www-data

# Install selected extensions and other stuff
RUN apt-get update \
    && apt-get -y --no-install-recommends install  \
            php7.0-memcached \
            php7.0-mongodb \
            php7.0-mysql \
            php7.0-pgsql \
            php7.0-redis \
            php7.0-sqlite3 \
            php7.0-bz2 \
            php7.0-enchant \
            php7.0-gd \
            php7.0-geoip \
            php7.0-gmp \
            php7.0-igbinary \
            php7.0-imagick \
            php7.0-imap \
            php7.0-interbase \
            php7.0-intl \
            php7.0-ldap \
            php7.0-mbstring \
            php7.0-msgpack \
            php7.0-odbc \
            php7.0-phpdbg \
            php7.0-pspell \
            php7.0-recode \
            php7.0-snmp \
            php7.0-soap \
            php7.0-ssh2 \
            php7.0-sybase \
            php7.0-tidy \
            php7.0-xdebug \
            php7.0-xmlrpc \
            php7.0-xsl \
    && apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

ADD ./site.ini /usr/local/etc/php/conf.d
ADD ./site.pool.conf /etc/php5/fpm/pool.d/site.conf

RUN apt-get update && apt-get install -y \
    libpq-dev \
    libmemcached-dev \
    curl \
    libpng12-dev \
    libfreetype6-dev \
    --no-install-recommends \
    && rm -r /var/lib/apt/lists/*

# configure gd library
RUN docker-php-ext-configure gd \
    --enable-gd-native-ttf \
    --with-freetype-dir=/usr/include/freetype2

# Install extensions using the helper script provided by the base image
RUN docker-php-ext-install \
    pdo_mysql \
    pdo_pgsql \
    gd

# Configure Memcached for php 7
RUN curl -L -o /tmp/memcached.tar.gz "https://github.com/php-memcached-dev/php-memcached/archive/php7.tar.gz" \
    && mkdir -p /usr/src/php/ext/memcached \
    && tar -C /usr/src/php/ext/memcached -zxvf /tmp/memcached.tar.gz --strip 1 \
    && docker-php-ext-configure memcached \
    && docker-php-ext-install memcached \
    && rm /tmp/memcached.tar.gz

# Install xdebug
RUN pecl install xdebug \
    && docker-php-ext-enable xdebug

# Install mongodb driver
#RUN pecl install mongodb

# Clean up, to free some space
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Assign working directory
WORKDIR /var/www/site

CMD ["php-fpm"]
#CMD ["/usr/sbin/php-fpm7.0"]

# Expose FastCGI port.
EXPOSE 9000