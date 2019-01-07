FROM ubuntu:bionic as builder

RUN apt update && apt install -y  make bash git gcc golang go-dep

ENV GOPATH $HOME/go
ENV VERSION v1.8.2

RUN mkdir -p $GOPATH/src/github.com/jaegertracing && \
    cd $GOPATH/src/github.com/jaegertracing && \
    git clone https://github.com/jaegertracing/jaeger jaeger && \
    cd jaeger && \
    git checkout tags/$VERSION && \
    git submodule update --init --recursive && \
    dep ensure

COPY compressor.patch $GOPATH/src/github.com/jaegertracing/jaeger/

RUN cd $GOPATH/src/github.com/jaegertracing/jaeger && \
    git apply compressor.patch && \
    GOOS=linux make build-collector


FROM alpine:latest as certs
RUN apk add --update --no-cache ca-certificates

FROM scratch

COPY --from=certs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

EXPOSE 14267
EXPOSE 14250

COPY --from=builder /go/src/github.com/jaegertracing/jaeger/cmd/collector/collector-linux /go/bin/

ENTRYPOINT ["/go/bin/collector-linux"]
