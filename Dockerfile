FROM debian:bullseye-slim
ENV SHELL=/bin/bash

WORKDIR /antispambox
RUN mkdir tmp

# Configure OS base
RUN echo "alias logger='/usr/bin/logger -e'" >> /etc/bash.bashrc ; \
    echo "LANG=en_US.UTF-8" > /etc/default/locale ; \
    unlink /etc/localtime ; \
    ln -s /usr/share/zoneinfo/America/Costa_Rica /etc/localtime ; \
    unlink /etc/timezone ; \
    ln -s /usr/share/zoneinfo/America/Costa_Rica /etc/timezone ;

# Update package sources
RUN apt-get update ;\
    apt-get install -y --no-install-recommends lsb-release ;\
    CODENAME=`lsb_release -c -s` ;\
    echo "deb [arch=amd64] http://rspamd.com/apt-stable/ $CODENAME main" > /etc/apt/sources.list.d/rspamd.list ;\
    echo "deb-src [arch=amd64] http://rspamd.com/apt-stable/ $CODENAME main" >> /etc/apt/sources.list.d/rspamd.list ;\
    apt-get update

# Install requires packages
RUN apt-get install -y --no-install-recommends --allow-unauthenticated \
        cron \
        nano \
        vim \
        python3 \
        python3-pip \
        python3-setuptools \
        rsyslog \
        spamassassin \
        spamc \
        unzip \
        wget \
        python3-sphinx \
        lighttpd \
        logrotate \
        unattended-upgrades \
        cpanminus \
        make \
        rspamd \
        redis-server \
        lsb-release

# Install dependencies for pushtest
RUN pip3 install imapclient
RUN pip3 install isbg

# Download and install irsd (as long as it is not pushed to pypi)
RUN cd /antispambox/tmp && \
    wget https://codeberg.org/antispambox/IRSD/archive/master.zip && \
    unzip master.zip && \
    cd irsd && \
    python3 setup.py install && \
    cd /antispambox ;

# Copy all the config files
COPY files/cron.d/* /etc/cron.d
COPY files/logrotate.d/* /etc/logrotate.d

# Configure redis (rspamd)
RUN sed -i 's+/var/lib/redis+/var/spamassassin/bayesdb+' /etc/redis/redis.conf ;

# Configure spamassassin
RUN chown -R debian-spamd:mail /var/spamassassin ; \
    sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/spamassassin ; \
    sed -i 's/CRON=0/CRON=1/' /etc/default/spamassassin ; \
    sed -i 's/^OPTIONS=".*"/OPTIONS="--allow-tell --max-children 5 --helper-home-dir -u debian-spamd -x --virtual-config-dir=\/var\/spamassassin -s mail"/' /etc/default/spamassassin ; \
    echo "bayes_path /var/spamassassin/bayesdb/bayes" >> /etc/spamassassin/local.cf ;

# Integrate geo database
RUN cpanm  YAML &&\
	cpanm Geography::Countries &&\
	cpanm Geo::IP IP::Country::Fast &&\
	cd /antispambox/tmp && \
	wget -N http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz &&\
	gunzip GeoIP.dat.gz &&\
	mkdir /usr/local/share/GeoIP/ &&\
	mv GeoIP.dat /usr/local/share/GeoIP/ &&\
	echo "loadplugin Mail::SpamAssassin::Plugin::RelayCountry" >> /etc/spamassassin/init.pre ; \
    cd /antispambox

# Copy spamassassin configurations
COPY files/config/spamassassin/user_prefs.cf /etc/spamassassin/user_prefs.cf
COPY files/config/spamassassin/sa-channels /etc/spamassassin

# Copy rspamd configurations
COPY files/config/rspamd/* /etc/rspamd/local.d

# Copy antispambox scripts
COPY files/bin/* /antispambox

# Remove tools we don't need anymore
RUN apt-get remove -y wget python3-pip python3-setuptools unzip make cpanminus  && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /antispambox/tmp/*

# Define volumes
VOLUME /var/spamassassin/bayesdb

# EXPOSE 80/tcp
# EXPOSE 11334/tcp

CMD python3 /antispambox/startup.py && tail -n 0 -F /var/log/*.log
