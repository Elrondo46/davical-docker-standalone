#Version 0.4
#Davical + apache + postgres
#---------------------------------------------------------------------
#Default configuration: hostname: davical.example
#                       user: admin
#                       pass: 12345
#---------------------------------------------------------------------

FROM    alpine
MAINTAINER https://github.com/Elrondo46

ENV     TIME_ZONE "Europe/Paris"
ENV     HOST_NAME "davical.example"
ENV     LANG      "en_US.UTF-8"
ENV     DBHOST "db"
ENV     PASSDAVDB "davical"
ENV     PGSQL_ROOT_PASS "davical"
ENV     ADMINDAVICALPASS "davical" 

# config files, shell scripts
COPY    docker-entrypoint.sh /sbin/docker-entrypoint.sh
COPY    apache.conf /config/apache.conf
COPY    davical.php /config/davical.php
COPY    rsyslog.conf /config/rsyslog.conf

ENV MUSL_LOCALE_DEPS cmake make musl-dev gcc gettext-dev libintl
ENV MUSL_LOCPATH /usr/share/i18n/locales/musl

RUN apk add --no-cache \
    $MUSL_LOCALE_DEPS \
    && wget https://gitlab.com/rilian-la-te/musl-locales/-/archive/master/musl-locales-master.zip \
    && unzip musl-locales-master.zip \
      && cd musl-locales-master \
      && cmake -DLOCALE_PROFILE=OFF -D CMAKE_INSTALL_PREFIX:PATH=/usr . && make && make install \
      && cd .. && rm -r musl-locales-master


# apk
RUN     apk --update add \
        sudo \
        bash \
        less \
        sed \
        rsyslog \
        postgresql-client \
        apache2 \
        apache2-utils \
        apache2-ssl \
        php7 \
        php7-session \
        php7-intl \
        php7-openssl \
        php7-apache2 \
        php7-pgsql \
        php7-imap \
        php7-curl \
        php7-cgi \
        php7-xml \
        php7-gettext \
        php7-iconv \
        php7-ldap \
        php7-pdo \
        php7-pdo_pgsql \
        php7-calendar \
        perl \
        perl-yaml \
        perl-dbd-pg \
        perl-dbi \
        wget \
        git \
        iputils \

        && git clone https://gitlab.com/davical-project/awl.git /usr/share/awl/ \
        && git clone https://gitlab.com/davical-project/davical.git /usr/share/davical/ \
        && rm -rf /usr/share/davical/.git /usr/share/awl/.git/ \
        && apk del git \
# Apache
        && chown -R root:apache /usr/share/davical \
        && cd /usr/share/davical/ \
        && find ./ -type d -exec chmod u=rwx,g=rx,o=rx '{}' \; \
        && find ./ -type f -exec chmod u=rw,g=r,o=r '{}' \; \
        && find ./ -type f -name *.sh -exec chmod u=rwx,g=r,o=rx '{}' \; \
        && find ./ -type f -name *.php -exec chmod u=rwx,g=rx,o=r '{}' \; \
        && chmod o=rx /usr/share/davical/dba/update-davical-database \
        && chmod o=rx /usr/share/davical \
        && chown -R root:apache /usr/share/awl \
        && cd /usr/share/awl/ \
        && find ./ -type d -exec chmod u=rwx,g=rx,o=rx '{}' \; \
        && find ./ -type f -exec chmod u=rw,g=r,o=r '{}' \; \
        && find ./ -type f -name *.sh -exec chmod u=rwx,g=rx,o=r '{}' \; \
        && find ./ -type f -name *.sh -exec chmod u=rwx,g=r,o=rx '{}' \; \
        && chmod o=rx /usr/share/awl \
        && sed -i /CustomLog/s/^/#/ /etc/apache2/httpd.conf \
        && sed -i /ErrorLog/s/^/#/ /etc/apache2/httpd.conf \
        && sed -i /TransferLog/s/^/#/ /etc/apache2/httpd.conf \
        && sed -i /CustomLog/s/^/#/ /etc/apache2/conf.d/ssl.conf \
        && sed -i /ErrorLog/s/^/#/ /etc/apache2/conf.d/ssl.conf \
        && sed -i /TransferLog/s/^/#/ /etc/apache2/conf.d/ssl.conf \
# permissions for shell scripts and config files
        && chmod 0755 /sbin/docker-entrypoint.sh \
        && mkdir /etc/davical /etc/rsyslog.d \
        && echo -e "\$IncludeConfig /etc/rsyslog.d/*.conf" > /etc/rsyslog.conf \
        && chown -R root:apache /etc/davical \
        && chmod -R u=rwx,g=rx,o= /etc/davical \
        && chown root:apache /config/davical.php \
        && chmod u+rwx,g+rx /config/davical.php \
        && ln -s /config/apache.conf /etc/apache2/conf.d/davical.conf \
        && ln -s /config/davical.php /etc/davical/config.php \
        && ln -s /config/rsyslog.conf /etc/rsyslog.d/rsyslog-davical.conf \
# clean-up etc
        && rm -rf /var/cache/apk/* \
        && mkdir -p /run/apache2 \
# build-translations
	    && cd /usr/share/davical \
	    && make all


EXPOSE 80 443
VOLUME ["/config"]
ENTRYPOINT ["/sbin/docker-entrypoint.sh"]