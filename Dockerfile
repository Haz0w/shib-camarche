FROM centos:7

ARG SP_ENTITY_ID
ARG IDP_ENTITY_ID
ARG METADATA_FILE
ARG METADATA_URL
ARG SSL
ARG HOSTNAME

COPY conf/shibboleth.repo /etc/yum.repos.d/shibboleth.repo

RUN yum install -y wget
RUN yum install -y httpd
RUN yum install -y php
RUN yum install -y mod_ssl
RUN yum install -y openssl-devel
RUN yum install -y gcc
RUN wget --no-check-certificate https://curl.haxx.se/download/curl-7.64.1.tar.gz && \
    tar -xzf curl-7.64.1.tar.gz && \
    cd curl-7.64.1 && \
    ./configure --with-ssl && \
    make && \
    make install
RUN yum install -y epel-release
RUN yum install -y python-pip

RUN wget https://shibboleth.net/downloads/service-provider/RPMS/repomd.xml.key && rpm --import repomd.xml.key && rm repomd.xml.key
RUN yum install -y shibboleth

RUN pip install supervisor

COPY conf/supervisord.conf /etc/supervisord.conf

RUN echo "ServerName ${HOSTNAME}" >> /etc/httpd/conf/httpd.conf

# RUN sed -i 's|https://idp.example.org/idp/shibboleth|'"${IDP_ENTITY_ID}"'|g' /etc/shibboleth/shibboleth2.xml
RUN sed -i 's|https://sp.example.org/shibboleth|'"${SP_ENTITY_ID}"'|g' /etc/shibboleth/shibboleth2.xml
RUN sed -i 's|handlerSSL="true"|handlerSSL="'"${SSL}"'"|g' /etc/shibboleth/shibboleth2.xml
RUN sed -i 's|cipherSuites="DEFAULT:!EXP:!LOW:!aNULL:!eNULL:!DES:!IDEA:!SEED:!RC4:!3DES:!kRSA:!SSLv2:!SSLv3:!TLSv1:!TLSv1.1"||g' /etc/shibboleth/shibboleth2.xml
RUN if [ "${SSL}" = "true" ]; then sed -i 's|cookieProps="https"|cookieProps="https"|g' /etc/shibboleth/shibboleth2.xml; else sed -i 's|cookieProps="https"|cookieProps="http"|g' /etc/shibboleth/shibboleth2.xml; fi

RUN sed -i 's|acl="127.0.0.1 ::1"||g' /etc/shibboleth/shibboleth2.xml
RUN sed -i 's|showAttributeValues="false"|showAttributeValues="true"|g' /etc/shibboleth/shibboleth2.xml
RUN sed -i 's|<SSO|<!--<SSO|g' /etc/shibboleth/shibboleth2.xml
RUN sed -i 's|</SSO>|</SSO>-->\n\
<SSO discoveryProtocol="SAMLDS"\n\
discoveryURL="https://discovery.renater.fr/test">\n\
SAML2\n\
</SSO>\n\
|g' /etc/shibboleth/shibboleth2.xml


RUN sed -i 's|<!-- Map to extract|\
<MetadataProvider type="XML"\n\
 url="'"${METADATA_URL}"'"\n\
 backingFilePath="'"${METADATA_FILE}"'"\n\
 reloadInterval="7200">\n\
 <MetadataFilter type="Signature" certificate="renater-metadata-signing-cert-2016.pem"/>\n\
</MetadataProvider>\n\
<!-- Map to extract|g' /etc/shibboleth/shibboleth2.xml

RUN wget https://pub.federation.renater.fr/metadata/certs/renater-metadata-signing-cert-2016.pem
RUN cp renater-metadata-signing-cert-2016.pem /etc/shibboleth/


CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]