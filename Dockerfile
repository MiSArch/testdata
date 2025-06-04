FROM alpine:latest

RUN apk add --no-cache bash curl jq

WORKDIR /app
COPY create-gatling-user.sh /app/
COPY create-test-data.sh /app/
COPY get-token.sh /app/
COPY create-grafana-api-token.sh /app/
COPY run.sh /app/

RUN chmod +x /app/*.sh

CMD ["/app/run.sh"]