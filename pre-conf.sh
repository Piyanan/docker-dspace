#!/bin/bash

  # need to install maven3
  wget http://ppa.launchpad.net/natecarlson/maven3/ubuntu/pool/main/m/maven3/maven3_3.2.1-0~ppa1_all.deb
  dpkg -i  maven3_3.2.1-0~ppa1_all.deb
  ln -s /usr/share/maven3/bin/mvn /usr/bin/mvn
  rm maven3_3.2.1-0~ppa1_all.deb

  # created user
  useradd -m dspace
  echo "dspace:admin"|chpasswd
  mkdir /dspace
  chown dspace /dspace

  #conf tomcat7 for dspace
  a=$(cat /etc/tomcat8/server.xml | grep -n "</Host>"| cut -d : -f 1 )
  sed -i "$((a-1))r /tmp/dspace_tomcat8.conf" /etc/tomcat8/server.xml

  mkdir /build
        chmod -R 770 /build
        cd /build
        wget https://github.com/DSpace/DSpace/releases/download/dspace-6.0/dspace-6.0-release.tar.gz
        tar -zxf dspace-6.0-release.tar.gz
        rm dspace-6.0-release.tar.gz
        
        cd /build/dspace-6.0-release
        mvn package
        
        sed -i 's/ssl = true/ssl = false/' /etc/postgresql/9.4/main/postgresql.conf
        
    #conf database before build and installation of dspace
        POSTGRESQL_BIN=/usr/lib/postgresql/9.4/bin/postgres
        POSTGRESQL_CONFIG_FILE=/etc/postgresql/9.4/main/postgresql.conf
        
        mkdir -p /var/run/postgresql/9.4-main.pg_stat_tmp
        chown postgres /var/run/postgresql/9.4-main.pg_stat_tmp
        chgrp postgres /var/run/postgresql/9.4-main.pg_stat_tmp
        
       chpst -u postgres $POSTGRESQL_BIN --single \
                --config-file=$POSTGRESQL_CONFIG_FILE \
              <<< "UPDATE pg_database SET encoding = pg_char_to_encoding('UTF8') WHERE datname = 'template1'" &>/dev/null

        chpst -u postgres $POSTGRESQL_BIN --single \
                --config-file=$POSTGRESQL_CONFIG_FILE \
                  <<< "CREATE USER dspace WITH SUPERUSER;" &>/dev/null
        chpst -u postgres $POSTGRESQL_BIN --single \
                --config-file=$POSTGRESQL_CONFIG_FILE \
                <<< "ALTER USER dspace WITH PASSWORD 'dspace';" &>/dev/null
                
        echo "local all dspace md5" >> /etc/postgresql/9.4/main/pg_hba.conf
        chpst -u postgres /usr/lib/postgresql/9.4/bin/postgres -D  /var/lib/postgresql/9.4/main -c config_file=/etc/postgresql/9.4/main/postgresql.conf >>/var/log/postgresd.log 2>&1 &
        sleep 10s
        chpst -u dspace createdb -U dspace -E UNICODE dspace 
        
        chpst -u postgres $POSTGRESQL_BIN --single \
                --config-file=$POSTGRESQL_CONFIG_FILE \
                <<< "CREATE EXTENSION pgcrypto;" &>/dev/null
        
        # build dspace and install
        cd /build/dspace-6.0-release/dspace/target/dspace-installer
        ant fresh_install
        chown tomcat8:tomcat8 /dspace -R
        killall postgres
        sleep 10s

  apt-get clean
  rm -rf /build
  rm -rf /tmp/* /var/tmp/*
  rm -rf /var/lib/apt/lists/*
