FROM openresty/openresty:1.21.4.1-alpine-fat

# allowed domains should be lua match pattern
ENV ALLOWED_DOMAINS='.*' \
    AUTO_SSL_VERSION='0.13.1' \
    FORCE_HTTPS='true' \
    SITES='' \
    LETSENCRYPT_URL='https://acme-v02.api.letsencrypt.org/directory' \
    STORAGE_ADAPTER='file' \
    REDIS_HOST='' \
    REDIS_AUTH='' \
    REDIS_PORT='6379' \
    REDIS_DB='0' \
    REDIS_KEY_PREFIX='' \
    RESOLVER_ADDRESS='8.8.8.8'\
    INCLUDE_HTTP_PING='false'

# We create fallback ssl keys
RUN apk --no-cache add bash openssl \
    && /usr/local/openresty/luajit/bin/luarocks install lua-resty-auto-ssl $AUTO_SSL_VERSION \
    && openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
    -subj '/CN=sni-support-required-for-valid-ssl' \
    -keyout /etc/ssl/resty-auto-ssl-fallback.key \
    -out /etc/ssl/resty-auto-ssl-fallback.crt \
    # let's remove default open resty configuration, we'll conditionally add modified version in entrypoint.sh
    && rm /etc/nginx/conf.d/default.conf

COPY nginx.conf snippets /usr/local/openresty/nginx/conf/
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]
