FROM golang:1.27-alpine AS builder

RUN apk add --no-cache ca-certificates

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .

ARG VERSION=railway

RUN CGO_ENABLED=0 go generate ./... && \
    CGO_ENABLED=0 go build \
      -ldflags="-s -w -X main.version=${VERSION}" \
      -o /coraza-waf-mod .


FROM alpine:3.22

RUN apk add --no-cache ca-certificates

COPY --from=builder /coraza-waf-mod /coraza-waf-mod
COPY railway-entrypoint.sh /railway-entrypoint.sh

RUN chmod +x /railway-entrypoint.sh

ENV PORT=8080
ENV TMPDIR=/tmp

EXPOSE 8080

ENTRYPOINT ["/railway-entrypoint.sh"]