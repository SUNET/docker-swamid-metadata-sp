FROM debian:bullseye
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get -q update && \
	apt-get -y upgrade && \
	apt-get -y install apache2 libapache2-mod-shib libapache2-mod-php php-mysql php-xml php-curl gettext-base git augeas-tools sqlite3 php-sqlite3 && \
	a2enmod ssl headers

# Disable apache default site and port 80
RUN a2dissite 000-default
RUN a2disconf other-vhosts-access-log
RUN echo "Listen 443" > /etc/apache2/ports.conf

# Output to stderr/stdout for better handling in a container environment
RUN sed -i 's#ErrorLog ${APACHE_LOG_DIR}/error.log#ErrorLog /dev/stderr#g' /etc/apache2/apache2.conf
RUN echo 'TransferLog /dev/stdout'  >> /etc/apache2/apache2.conf

ENV SP_HOSTNAME sp.example.com
ENV SP_CONTACT noc@sunet.se
ENV SP_ABOUT /about.html
ENV SP_METADATAFEED https://mds.swamid.se/
ENV DEFAULT_LOGIN seamless-access
ADD md-signer2.crt /etc/shibboleth/md-signer2.crt
ADD shibboleth2.xml /tmp/shibboleth2.xml
ADD attribute-map.xml /etc/shibboleth/attribute-map.xml
ADD default-ssl.conf /etc/apache2/sites-available/default-ssl.conf
ADD start.sh /start.sh
ADD shibd.logger /etc/shibboleth/shibd.logger
RUN a2ensite default-ssl && \
	sed -i 's/Options Indexes/Options/' /etc/apache2/apache2.conf && \
	mkdir -p /etc/shibboleth/certs /etc/shibboleth/metadata /var/cache/shibboleth/metadata && \
	chown _shibd /etc/shibboleth/metadata /var/cache/shibboleth/metadata && \
	chmod a+rx /start.sh && \
	sed -i 's/default_bits=3072/default_bits=4096/' /usr/sbin/shib-keygen

# Output to stdout for better handling in a container environment
RUN ln -sf /proc/self/fd/1 /var/log/shibboleth/shibd.log
RUN ln -sf /proc/self/fd/1 /var/log/shibboleth/shibd_warn.log
RUN ln -sf /proc/self/fd/1 /var/log/shibboleth/signature.log
RUN ln -sf /proc/self/fd/1 /var/log/shibboleth/transaction.log

EXPOSE 443
ENTRYPOINT ["/start.sh"]
