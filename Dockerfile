FROM node:22-alpine AS builder

WORKDIR /app

RUN npm install -g mcp-proxy strava-mcp-server

FROM node:22-alpine

WORKDIR /app

COPY --from=builder /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=builder /usr/local/bin /usr/local/bin

EXPOSE 8080

CMD ["mcp-proxy", "--port", "8080", "--", "strava-mcp-server"]
