# OpenPanel — open-source Mixpanel/Plausible-style analytics (2.3.0). Deploy on Railway with one click.

<!-- Deploy button: replace DEPLOY_CODE once the Railway template is generated -->
[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/DEPLOY_CODE)

[OpenPanel](https://openpanel.dev) is an open-source web and product analytics platform (funnels, retention, events) that combines Mixpanel-style product analytics with Plausible-style simplicity. This template ships **digest-pinned 2.3.0** app images, `API_HOST=::` for Railway IPv6 private networking, a single public Caddy domain for cookies, and **zero deploy-time inputs**.

## Why this template
- **Current, digest-pinned:** `lindesvard/openpanel-{api,dashboard,worker}:2.3.0` (multi-arch digests below). Existing marketplace templates still pin `*:2.2`.
- **Railway IPv6 private networking:** `API_HOST=::` on the API (and worker) so private DNS reaches the API over IPv6, as [upstream docs](https://openpanel.dev/docs/self-hosting/environment-variables) call out.
- **Proven 7-service architecture** (same layout as `openpanel-1`): Caddy proxy + api + dashboard + worker + Postgres + Redis + ClickHouse.
- **Zero deploy-time config:** `COOKIE_SECRET`, DB/Redis/ClickHouse passwords are auto-generated. Email and AI keys are optional after deploy.
- **Single public domain:** only `op-proxy` is public; `/api/*` → API, `/*` → dashboard (cookies work without a custom domain).

## Services
| Service | Source | Notes |
|---|---|---|
| op-proxy | `caddy:2-alpine@sha256:d8542f48d34a9cf4e4c11a478865229840e87e4c96ea3f439101f31a5d35f75f` | **only public domain**, port `8080`, Caddyfile from `CADDYFILE` env |
| op-api | `lindesvard/openpanel-api:2.3.0@sha256:cee4855cd715a7248c5c49090fe93a28ffc505541de20cb238d8884a6bcb9223` | port `3000`, health `/healthcheck`, migrations then `pnpm start`, `API_HOST=::` |
| op-dashboard | `lindesvard/openpanel-dashboard:2.3.0@sha256:b773cf864454a0ec89b2a133b48bf06202880ed650a75cc2f1f5c87aaed1cffa` | port `3000`, health `/api/healthcheck` |
| op-worker | `lindesvard/openpanel-worker:2.3.0@sha256:b22e247fb6980b820c1a954d0e3d2fe88b3edf40a58aa53329467af239538e80` | port `3000`, health `/healthcheck`, `API_HOST=::` |
| op-postgres | `ghcr.io/railwayapp-templates/postgres-ssl:17` | volume `/var/lib/postgresql/data` |
| op-redis | `redis:8.2.1@sha256:5fa2edb1e408fa8235e6db8fab01d1afaaae96c9403ba67b70feceb8661e8621` | volume `/data`, password via `REDIS_PASSWORD` |
| op-clickhouse | `clickhouse/clickhouse-server:25.12@sha256:8a790dd3468db22b1d4e7b18a176f378ff5ff6053b9c48dd4ea1fa71a24c5ba6` | volume `/var/lib/clickhouse`, HTTP `8123`, listens on `::` for Railway |

**API start command** (Railway replaces image CMD; migrations must run first):
```
sh -c "echo Running migrations...; CI=true pnpm -r run migrate:deploy; exec pnpm start"
```
(Also in `railway/api-start-command.txt`.)

**Proxy start command** (writes `CADDYFILE` then runs Caddy):
```
sh -c 'printf "%s\n" "$CADDYFILE" > /etc/caddy/Caddyfile && exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile'
```

## Variables (app services: op-api / op-dashboard / op-worker)
| Variable | Template value | Notes |
|---|---|---|
| SELF_HOSTED | `true` | |
| PORT | `3000` | |
| API_HOST | `::` | api + worker (IPv6 private networking) |
| COOKIE_SECRET | `${{secret(32, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")}}` on api; dashboard/worker use `${{op-api.COOKIE_SECRET}}` | |
| DATABASE_URL / DATABASE_URL_DIRECT | `${{op-postgres.DATABASE_URL}}` | |
| REDIS_URL | `${{op-redis.REDIS_URL}}` | |
| CLICKHOUSE_URL | `${{op-clickhouse.DATABASE_URL}}` | HTTP URL `http://user:pass@host:8123/openpanel` |
| DASHBOARD_URL | `https://${{op-proxy.RAILWAY_PUBLIC_DOMAIN}}` | public |
| API_URL | `https://${{op-proxy.RAILWAY_PUBLIC_DOMAIN}}/api` | public path through proxy |
| API_URL_SSR | `http://${{op-api.RAILWAY_PRIVATE_DOMAIN}}:${{op-api.PORT}}` | dashboard only |
| CUSTOM_COOKIE_DOMAIN | `${{op-proxy.RAILWAY_PUBLIC_DOMAIN}}` | |
| ALLOW_REGISTRATION | `true` | auto-disables after the first user (upstream behaviour) |
| ALLOW_INVITATION | `true` | |
| RESEND_API_KEY / EMAIL_SENDER / OPENAI_API_KEY / ANTHROPIC_API_KEY | empty | set after deploy if needed |

### op-proxy
| Variable | Template value |
|---|---|
| PORT | `8080` |
| API_URL | `http://${{op-api.RAILWAY_PRIVATE_DOMAIN}}:${{op-api.PORT}}` (internal upstream) |
| DASHBOARD_URL | `http://${{op-dashboard.RAILWAY_PRIVATE_DOMAIN}}:${{op-dashboard.PORT}}` (internal upstream) |
| CADDYFILE | contents of `railway/Caddyfile` (openpanel-1 Railway pattern with `X-Real-Ip`) |

### Data stores
| Service | Key vars |
|---|---|
| op-postgres | `POSTGRES_USER=postgres`, `POSTGRES_DB=railway`, `POSTGRES_PASSWORD=${{secret(...)}}`, `DATABASE_URL=postgresql://…@${{RAILWAY_PRIVATE_DOMAIN}}:5432/…`, `PGDATA=/var/lib/postgresql/data/pgdata` |
| op-redis | `REDIS_PASSWORD=${{secret(...)}}`, `REDIS_URL=redis://default:${{REDIS_PASSWORD}}@${{RAILWAY_PRIVATE_DOMAIN}}:${{PORT}}`, `PORT=6379` |
| op-clickhouse | `CLICKHOUSE_USER=clickhouse`, `CLICKHOUSE_DB=openpanel`, `CLICKHOUSE_PASSWORD=${{secret(...)}}`, `PORT=8123`, `DATABASE_URL=http://…@host:8123/openpanel` |

## After deploy
1. Open `https://<op-proxy-domain>` and create the first user (registration is allowed until the first account exists).
2. (Optional) Add `RESEND_API_KEY` + `EMAIL_SENDER` for invites/password resets.
3. (Optional) Add `OPENAI_API_KEY` and/or `ANTHROPIC_API_KEY` for the in-app AI chat.
4. Health: `GET https://<domain>/api/healthcheck` (via proxy → API) and the dashboard UI on `/`.

## Notes
- Generate the marketplace template from the live Railway project in the dashboard (**Do not publish from this README alone**).
- Run **one replica** of Redis/ClickHouse/Postgres volumes.
- Upstream: https://github.com/Openpanel-dev/openpanel · Docs: https://openpanel.dev/docs/self-hosting/deploy-docker-compose · https://openpanel.dev/docs/self-hosting/environment-variables
