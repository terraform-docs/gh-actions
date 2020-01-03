FROM derekrada/terraform-docs:stable
COPY ./src/common.sh /common.sh
COPY ./src/docker-entrypoint.sh /docker-entrypoint.sh
COPY ./src/default.tpl /default_template.tpl

ENTRYPOINT ["/docker-entrypoint.sh"]
