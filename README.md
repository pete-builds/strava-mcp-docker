# strava-mcp-docker

A ready-to-run Docker recipe that serves the Strava MCP server over HTTP/SSE, so any MCP client on your network can connect.

## Why Docker + mcp-proxy?

- **Run it on a server, connect from anywhere.** Access your Strava data from any machine on your LAN or over Tailscale. No need to run the server locally.
- **No Node.js required on your workstation.** Everything runs inside the container.
- **API key auth protects the endpoint.** The mcp-proxy layer requires an `X-API-Key` header on every request.
- **Survives reboots.** The container restarts automatically with `restart: unless-stopped`.
- **Clean isolation.** No global npm packages polluting your system.

## How this differs from other Strava MCP repos

Several Strava MCP server implementations exist ([r-huijts/strava-mcp](https://github.com/r-huijts/strava-mcp), [eddmann/strava-mcp](https://github.com/eddmann/strava-mcp-server), and others). They give you the server code and leave deployment up to you.

This repo gives you the deployment. One `docker compose up -d` and you're done. It bridges the stdio-based `strava-mcp-server` to HTTP/SSE via `mcp-proxy`, so any MCP client on your network can connect over a standard HTTP endpoint. It also documents the OAuth scope pitfall that isn't covered anywhere else (see below).

There is no custom application code here. The value is the recipe and the documentation.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose
- A Strava account
- A Strava API application: create one at [strava.com/settings/api](https://www.strava.com/settings/api)

## Quick Start

1. Clone this repo:
   ```bash
   git clone https://github.com/psterpe/strava-mcp-docker.git
   cd strava-mcp-docker
   ```

2. Copy the example env file:
   ```bash
   cp .env.example .env
   ```

3. Generate an API key for mcp-proxy:
   ```bash
   openssl rand -hex 32
   ```

4. Open `.env` and fill in your Strava credentials and the API key you just generated.

5. Complete the [OAuth Walkthrough](#oauth-walkthrough) below to get your access and refresh tokens.

6. Start the container:
   ```bash
   docker compose up -d
   ```

## OAuth Walkthrough

This is the part that trips everyone up. Follow these steps carefully.

### 1. Set your callback domain

When creating your Strava API app at [strava.com/settings/api](https://www.strava.com/settings/api), Strava requires a real domain for the "Authorization Callback Domain." Localhost won't work. Use whatever domain you own (your personal site, a side project domain, anything). It doesn't need to be running a web server.

### 2. Build the authorization URL

> **CRITICAL: You MUST include `activity:read_all` in the scope parameter.** The default `read` scope only gives you profile access. Without `activity:read_all`, every activity request returns a 401 with `"field": "activity:read_permission", "code": "missing"`. This is the #1 gotcha and it is poorly documented.

Construct this URL, replacing the placeholders:

```
https://www.strava.com/oauth/authorize?client_id=YOUR_CLIENT_ID&redirect_uri=https://YOUR_DOMAIN&response_type=code&scope=read,activity:read_all
```

### 3. Authorize and grab the code

Open that URL in your browser. Strava will ask you to authorize the app. Click "Authorize."

Strava will redirect to your callback domain. The page will probably 404 or show your unrelated website. That's fine. Look at the URL bar. It will contain `?code=XXXXXXXXXX`. Copy that code.

### 4. Exchange the code for tokens

```bash
curl -X POST https://www.strava.com/oauth/token \
  -d client_id=YOUR_CLIENT_ID \
  -d client_secret=YOUR_CLIENT_SECRET \
  -d code=YOUR_CODE \
  -d grant_type=authorization_code
```

The response will include `access_token` and `refresh_token`. Copy both values into your `.env` file.

## Connecting to Claude Code

Add this to your Claude Code MCP settings (`~/.claude/settings.json` or project-level `.mcp.json`):

```json
{
  "mcpServers": {
    "strava": {
      "type": "sse",
      "url": "http://YOUR_SERVER_IP:18201/sse",
      "headers": {
        "X-API-Key": "your-mcp-api-key"
      }
    }
  }
}
```

Replace `YOUR_SERVER_IP` with the IP or hostname of the machine running Docker, and `your-mcp-api-key` with the key you generated during setup.

## Troubleshooting

**401 Authorization Error**
Wrong OAuth scopes. This is almost always the cause. Go back to the [OAuth Walkthrough](#oauth-walkthrough) and make sure `activity:read_all` is in your scope parameter.

**429 Rate Limit Exceeded**
Strava enforces a limit of 200 requests per 15 minutes and 2,000 per day. Wait and retry.

**Container keeps restarting**
Check the logs:
```bash
docker logs strava-mcp
```

**Token expired**
The refresh token should auto-renew, but if it fails, re-run the OAuth flow from [step 2](#2-build-the-authorization-url) onward.

## License

[MIT](LICENSE)
