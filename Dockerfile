FROM derekrada/terraform-docs:v1.0.8
COPY ./src/common.sh /common.sh
COPY ./src/docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
