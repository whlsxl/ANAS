FROM golang:1.20.4-alpine3.17 as go
RUN set -ex; \
  apk add --no-cache \
  vips-dev \
  vips-magick \
  vips-heif \
  vips-jxl \
  vips-poppler \
  build-base; \
  go install github.com/h2non/imaginary@b632dae8cc321452c3f85bcae79c580b1ae1ed84;

FROM alpine:3.17.3
RUN set -ex; \
  apk add --no-cache \
  tzdata \
  ca-certificates \
  netcat-openbsd \
  vips \
  vips-magick \
  vips-heif \
  vips-jxl \
  vips-poppler

COPY --from=go /go/bin/imaginary /usr/local/bin/imaginary

ENV PORT 9000

USER nobody

# https://github.com/h2non/imaginary#memory-issues
ENV MALLOC_ARENA_MAX=2
ENTRYPOINT ["imaginary", "-return-size", "-max-allowed-resolution", "222.2"]

HEALTHCHECK CMD nc -z localhost "$PORT" || exit 1
# LABEL com.centurylinklabs.watchtower.monitor-only="true"