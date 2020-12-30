FROM quay.io/terraform-docs/terraform-docs:0.10.1

# this can be removed when base image
# was upgraded to alpine:3.13 which has
# 'yq' in its repository out of the box.
RUN echo "http://dl-4.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories

RUN set -x \
    && apk add --no-cache \
        bash \
        git \
        jq \
        sed \
        yq

COPY ./src/common.sh /common.sh
COPY ./src/docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
