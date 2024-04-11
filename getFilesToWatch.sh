rm -rf ./watch/*

docker cp shibboleth:/etc/httpd/conf/httpd.conf ./watch/httpd.conf
docker cp shibboleth:/etc/httpd/conf.d/shib.conf ./watch/shib.conf
docker cp shibboleth:/etc/shibboleth ./watch/

mkdir ./watch/log
docker cp shibboleth:/var/log/httpd/error_log ./watch/log/httpd_error_log
docker cp shibboleth:/var/log/shibboleth/shibd.log ./watch/log/shibd.log
docker cp shibboleth:/var/log/shibboleth/shibd_warn.log ./watch/log/shibd_warn.log

rm ./watch/shibboleth/*.config
rm ./watch/shibboleth/*.dist