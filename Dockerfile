FROM docker.io/golang:1.14.15-alpine as builder

RUN apk add --no-cache git

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG VERSION

ENV CGO_ENABLED=0 \
    GOPATH=/go \
    GOBIN=/go/bin \
    GO111MODULE=on

WORKDIR /workspace

COPY . .

RUN \
  export GOOS \
  && GOOS=$(echo ${TARGETPLATFORM} | cut -d / -f1) \
  && export GOARCH \
  && GOARCH=$(echo ${TARGETPLATFORM} | cut -d / -f2) \
  && export GOARM \
  && GOARM=$(echo ${TARGETPLATFORM} | cut -d / -f3 | cut -c2-) \
  && go build -o /go/bin/prometheus-dnssec-exporter -ldflags="-w -s"


FROM quay.io/prometheus/busybox:glibc

ARG BUILD_DATE
ARG VCS_REF

COPY --from=builder /go/bin/prometheus-dnssec-exporter /bin/prometheus-dnssec-exporter
COPY config.sample /etc/dnssec-checks

EXPOSE      9204
USER        nobody
ENTRYPOINT  [ "/bin/prometheus-dnssec-exporter" ]

LABEL maintainer="Harald Koch <harald.koch@gmail.com>" \
      org.opencontainers.image.created=${BUILD_DATE} \
      org.opencontainers.image.revision=${VCS_REF} \
      org.opencontainers.image.source="https://github.com/haraldkoch/prometheus-dnssec-exporter" \
      org.opencontainers.image.title="prometheus-dnssec-exporter" \
      org.opencontainers.image.version="${VERSION}"
