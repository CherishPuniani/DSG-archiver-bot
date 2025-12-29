# Build stage
FROM golang:1.22-alpine AS builder
RUN apk add --no-cache git
WORKDIR /app
# Clone the fork with socket mode support
RUN git clone https://github.com/DavyJohnes/matterbridge.git . \
    && git checkout socket-mode \
    && go mod download \
    && CGO_ENABLED=0 go build -o matterbridge .

# Final stage
FROM alpine:latest
RUN apk add --no-cache ca-certificates python3 gettext curl jq
WORKDIR /app
COPY channels.csv /app/channels.csv
COPY generate_matterbridge_config.py /app/generate_matterbridge_config.py
COPY --from=builder /app/matterbridge /bin/matterbridge

COPY matterbridge.toml /etc/matterbridge/matterbridge.toml
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

