#!/bin/bash

#SET THE TIMEZONE
apk add --update tzdata
cp "/usr/share/zoneinfo/$TIME_ZONE" /etc/localtime
echo "$TIME_ZONE" > /etc/timezone
apk del tzdata

#PREPARE THE PERMISSIONS FOR VOLUMES
chown -R root:root /config
chmod -R 755 /config
mv -n /apache.conf /config/apache.conf
mv -n /davical.php /config/davical.php
mv -n /rsyslog.conf /config/rsyslog.conf
sed -i "s@host=example@host=$DBHOST@" /config/davical.php
sed -i "s@password=example@password=$PASSDAVDB@" /config/davical.php
chown -R root:root /config
chmod -R 755 /config
chown root:apache /config/davical.php
chmod u+rwx,g+rx /config/davical.php

sleep 15
/usr/bin/pg_isready -U postgres -h "$DBHOST" -t 2000

INITIALIZED_DB=$(PGPASSWORD="$PGSQL_ROOT_PASS" /usr/bin/psql -qX -U postgres -h "$DBHOST" -l | grep davical)
if [[ -z "$INITIALIZED_DB" ]]; then
    PGPASSWORD="$PGSQL_ROOT_PASS" /usr/bin/psql -qX -U postgres -h "$DBHOST" -c 'CREATE DATABASE davical;'
    PGPASSWORD="$PGSQL_ROOT_PASS" /usr/bin/psql -qX -U postgres -h "$DBHOST" -c 'CREATE ROLE davical_dba;'
    PGPASSWORD="$PGSQL_ROOT_PASS" /usr/bin/psql -qX -U postgres -h "$DBHOST" -c 'CREATE ROLE davical_app;'
    PGPASSWORD="$PGSQL_ROOT_PASS" /usr/bin/psql -qX -U postgres -h "$DBHOST" -c "ALTER USER davical_dba WITH PASSWORD '$PASSDAVDB';"
    PGPASSWORD="$PGSQL_ROOT_PASS" /usr/bin/psql -qX -U postgres -h "$DBHOST" -c "ALTER USER davical_app WITH PASSWORD '$PASSDAVDB';"
    PGPASSWORD="$PGSQL_ROOT_PASS" /usr/bin/psql -qX -U postgres -h "$DBHOST" -c 'GRANT ALL PRIVILEGES ON DATABASE davical TO davical_dba;'
    PGPASSWORD="$PGSQL_ROOT_PASS" /usr/bin/psql -qX -U postgres -h "$DBHOST" -c 'GRANT ALL PRIVILEGES ON DATABASE davical TO davical_app;'
    PGPASSWORD=$PGSQL_ROOT_PASS /usr/bin/psql -qX -U postgres -h $DBHOST -c 'ALTER USER davical_dba WITH LOGIN;'
    PGPASSWORD=$PGSQL_ROOT_PASS /usr/bin/psql -qX -U postgres -h $DBHOST -c 'ALTER USER davical_app WITH LOGIN;'
    PGPASSWORD="$PASSDAVDB" /usr/bin/psql -qXAt -U davical_dba -h "$DBHOST" davical < /usr/share/awl/dba/awl-tables.sql
    PGPASSWORD="$PASSDAVDB" /usr/bin/psql -qXAt -U davical_dba -h "$DBHOST" davical < /usr/share/awl/dba/schema-management.sql
    PGPASSWORD="$PASSDAVDB" /usr/bin/psql -qXAt -U davical_dba -h "$DBHOST" davical < /usr/share/davical/dba/davical.sql
    PGPASSWORD="$PASSDAVDB" /usr/share/davical/dba/update-davical-database --dbname davical --dbuser davical_dba --dbhost "$DBHOST" --dbpass "$PASSDAVDB" --appuser davical_app --nopatch --owner davical_dba
    PGPASSWORD="$PASSDAVDB" /usr/bin/psql -qXAt -U davical_dba -h "$DBHOST" davical < /usr/share/davical/dba/base-data.sql
    PGPASSWORD="$PASSDAVDB" /usr/bin/psql davical -qX -U davical_dba -h "$DBHOST" -c "UPDATE usr SET password = '**$ADMINDAVICALPASS' WHERE user_no = 1;"
else
    PGPASSWORD="$PGSQL_ROOT_PASS" /usr/bin/psql -qX -U postgres -h "$DBHOST" -c "ALTER USER davical_dba WITH PASSWORD '$PASSDAVDB';"
    PGPASSWORD="$PGSQL_ROOT_PASS" /usr/bin/psql -qX -U postgres -h "$DBHOST" -c "ALTER USER davical_app WITH PASSWORD '$PASSDAVDB';"
    PGPASSWORD="$PGSQL_ROOT_PASS" /usr/bin/psql -qX -U postgres -h "$DBHOST" -c 'GRANT ALL PRIVILEGES ON DATABASE davical TO davical_dba;'
    PGPASSWORD="$PGSQL_ROOT_PASS" /usr/bin/psql -qX -U postgres -h "$DBHOST" -c 'GRANT ALL PRIVILEGES ON DATABASE davical TO davical_app;'
    PGPASSWORD="$PASSDAVDB" /usr/bin/psql davical -qX -U davical_dba -h "$DBHOST" -c "UPDATE usr SET password = '**$ADMINDAVICALPASS' WHERE user_no = 1;"
fi

#UPDATE ALWAYS THE DATABASE
sleep 3

/usr/share/davical/dba/update-davical-database --dbname davical --dbuser davical_dba --dbhost "$DBHOST" --dbpass "$PASSDAVDB" --appuser davical_app --nopatch --owner davical_dba

#LAUNCH THE INIT PROCESS
exec /usr/sbin/httpd -e error -E /var/log/apache2/apache-start.log -DFOREGROUND
