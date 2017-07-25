#!/bin/bash

set -e
initfile=$(echo $HOST_HOSTNAME)\.initialised
if [ -f /www/$(echo $initfile) ]; then
        echo 'initial configuration done.'
else    
        ### run once at container start IF no initialization file.
        ### if the .initialised file is removed, the container    
        ### will be reset to it's default state, unless the www
        ### folder is maintained.
        
        if [ ! -d /www ]; then
           mkdir -p /www
           echo "<? header('Location: /test.php'); ?>" > /www/index.php
           #cp /usr/share/javascript/jquery/jquery.min.js /synced/www/
           cp -TRv /tmp/www/ /www/
        fi   
        echo "Creating Musicbrainz database structure"
        echo "postgresql:5432:musicbrainz:$POSTGRES_USER:$POSTGRES_PASSWORD"  > ~/.pgpass
        chmod 0600 ~/.pgpass
        if [ ! -d /www/sqls ]; then
            mkdir -p /www/sqls
        fi
        cd /www/sqls
        if [ ! -f /www/sqls/Extensions.sql ]; then
            wget https://raw.githubusercontent.com/metabrainz/musicbrainz-server/master/admin/sql/Extensions.sql
        fi
        if [ ! -f /www/sqls/CreateTables.sql ]; then 
            wget https://raw.githubusercontent.com/metabrainz/musicbrainz-server/master/admin/sql/CreateTables.sql
        fi
        if [ ! -f /www/sqls/CreatePrimaryKeys.sql ]; then 
            wget https://raw.githubusercontent.com/metabrainz/musicbrainz-server/master/admin/sql/CreatePrimaryKeys.sql
        fi
        if [ ! -f /www/sqls/CreateIndexes.sql ]; then
            wget https://raw.githubusercontent.com/metabrainz/musicbrainz-server/master/admin/sql/CreateIndexes.sql
        fi
        echo "Downloading last Musicbrainz dump"
        if [ ! -d /www/dump ]; then
            mkdir -p /www/dump
        fi
        cd /www/dump
        wget -nd -nH -P /www/dump http://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport/LATEST
        LATEST="$(cat /www/dump/LATEST)"
        if [ ! -f /www/dump/mbdump-derived.tar.bz2 ]; then
            wget -nd -nH -P /www/dump http://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport/$LATEST/mbdump-derived.tar.bz2
            echo "Uncompressing Musicbrainz mbdump-derived.tar.bz2"
            tar xjf /www/dump/mbdump-derived.tar.bz2
        fi
        if [ ! -f /www/dump/mbdump.tar.bz2 ]; then
            wget -nd -nH -P /www/dump http://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport/$LATEST/mbdump.tar.bz2
            echo "Uncompressing Musicbrainz mbdump.tar.bz2"
            tar xjf /www/dump/mbdump.tar.bz2
        fi
        
        
           #psql -h postgresql -d musicbrainz -U $POSTGRES_USER -a -c "CREATE SCHEMA musicbrainz"
           #psql -h postgresql -d musicbrainz -U $POSTGRES_USER -a -f Extensions.sql
           #psql -h postgresql -d musicbrainz -U $POSTGRES_USER -a -f CreateTables.sql

        #for f in mbdump/*
        #do
        #   tablename="${f:7}"
        #   echo "Importing $tablename table"
        #   echo "psql -h postgresql -d musicbrainz -U $POSTGRES_USER -a -c COPY $tablename FROM '/tmp/$f'"
        #   chmod a+rX /tmp/$f
        #   psql -h postgresql -d musicbrainz -U $POSTGRES_USER -a -c "\COPY $tablename FROM '/tmp/$f'"
        #done

        #echo "Creating Indexes and Primary Keys"
        #psql -h postgresql -d musicbrainz -U $POSTGRES_USER -a -f CreatePrimaryKeys.sql
        #psql -h postgresql -d musicbrainz -U $POSTGRES_USER -a -f CreateIndexes.sql
           
        echo -e "Do not remove this file.\nIf you do, container will be fully reset on next start." > /www/$(echo $initfile)
        date >> /www/$(echo $initfile)
fi