FROM node:22-alpine AS builder

WORKDIR /app

# Pin both proxy and server versions for reproducible builds.
# mcp-proxy 6.x exposes both SSE (deprecated) and Streamable HTTP (default
# /mcp endpoint, MCP spec 2025-06-18) simultaneously.
RUN npm install -g mcp-proxy@6.4.6 strava-mcp-server@1.2.1

FROM node:22-alpine

WORKDIR /app

COPY --from=builder /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=builder /usr/local/bin /usr/local/bin

EXPOSE 8080

# Default proxy command serves both transports:
#   /mcp  - Streamable HTTP  (current MCP transport — use this)
#   /sse  - HTTP+SSE        (deprecated, kept for backwards compat)
CMD ["mcp-proxy", "--port", "8080", "--", "strava-mcp-server"]
