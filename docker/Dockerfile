FROM golang:1.13-alpine3.10 as builder
# Locked down to a specific commit until v0.8 is released
ARG VERSION=8fe71fde97e6fc47ed4fb292f5f187f0207352dd

# Install dependencies
RUN set -x \
	&& apk add --no-cache \
		bash \
		curl \
		gcc \
		git \
		make \
    wget \
  && GO111MODULE="on" go get "github.com/segmentio/terraform-docs@${VERSION}"

RUN set -x \
  && wget -O yq https://github.com/mikefarah/yq/releases/download/2.4.1/yq_linux_amd64 \
  && chmod 755 yq \
  && mv yq /usr/local/bin/yq \
  && wget -O gomplate https://github.com/hairyhenderson/gomplate/releases/download/v3.6.0/gomplate_linux-amd64 \
  && chmod 755 gomplate \
  && mv gomplate /usr/local/bin/gomplate

FROM alpine:3.10
COPY --from=builder /go/bin/terraform-docs /usr/local/bin/terraform-docs
COPY --from=builder /usr/local/bin/yq /usr/local/bin/yq
COPY --from=builder /usr/local/bin/gomplate /usr/local/bin/gomplate

RUN apk add --no-cache bash sed git

ENTRYPOINT ["/usr/local/bin/terraform-docs"]
