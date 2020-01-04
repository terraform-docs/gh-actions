FROM derekrada/terraform-docs:v1.0.1
COPY ./src/common.sh /common.sh
COPY ./src/docker-entrypoint.sh /docker-entrypoint.sh
COPY ./src/generate-readme.sh /generate-readme.sh
COPY ./src/default.tpl /default_template.tpl

ENTRYPOINT ["/docker-entrypoint.sh"]
