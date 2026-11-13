# pigallery2-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [PiGallery2](https://github.com/bpatrik/PiGallery2).

## What this is

A four-file TOS Docker application archive (`pigallery2docker.tar.gz`) that installs
PiGallery2 on TOS 7 through the App Center:

- `config.ini` — TOS application metadata (`application_type: docker`, id `pigallery2docker`)
- `pigallery2docker.lang` — 23-language superset (TOS requires 14)
- `pigallery2docker.svg` — application icon (274 bytes, 2 SVG elements)
- `docker-compose.yml` — one service, image `bpatrik/pigallery2:3.5.2`

## How it works

| | |
|---|---|
| Container image | `bpatrik/pigallery2:3.5.2` (Docker Hub, used unmodified) |
| Open | `http://<NAS-IP>:8050/` (container port 3000) |
| Runs as | non-root, `user: "1000:1000"` |
| Persistent data | `/app/data` → `/Volume1/DockerAppData/pigallery2docker/data` |
| Logs | `docker logs pigallery2docker` (stdout/stderr) |

`/app/data` keeps the SQLite database, users and the generated config; `/app/images` (mounted from `.../images`) is the folder the gallery indexes - the photos themselves stay untouched.

## Design highlights

- **Non-root.** `user: "1000:1000"`; verified on real hardware (the container reports uid 1000).
- **Entrypoint wrapper**: the image binds port 80 (not allowed for uid 1000) and expects `/app/data/config/config.json`; the wrapper seeds a minimal config on port 3000 and starts the Node backend as uid 1000.
- **Fixed image tag, never `:latest`**, Docker Hub only, no `privileged`, no `network_mode: host`, and no Docker socket, no `cap_add`.
- **Health check** probing the service on container port 3000.
- **Deterministic build**: GNU tar with uid/gid 0 and zeroed timestamps, gzip without a timestamp, plus the review-standards self-check above.
- **Port moved to 3000.** The image binds 80 by default, which an unprivileged container cannot do; the wrapper seeds `config.json` with `Server.port = 3000`.
- **SQLite only.** No database server; the gallery is a folder plus a small database.

## Runtime file manifest

Everything the application writes on the NAS lives inside its own data
directory; the container-internal `/tmp` is discarded with the container. The
table lists what is created and how it behaves. Nothing else is written.

| Path | Purpose | Created when | Growth bound | Lifecycle |
|---|---|---|---|---|
| `/Volume1/DockerAppData/pigallery2docker/data` | PiGallery2 application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |

## Build

```bash
scripts/build.sh                  # -> out/pigallery2docker.tar.gz + .sha256
scripts/build.sh 3.5.2-2   # packaging iteration bump
scripts/build.sh 3.5.2-1 aarch64
```

The build stages the four files, substitutes the version/platform placeholders,
embeds `src/entrypoint.sh` into the compose file (escaping every `$` as `$$`), removes CRLF/BOM/AppleDouble, then runs
`tools/verify.py`, a review-standards self-check (archive layout, JSON validity,
required fields, 14+ language coverage, version consistency, Docker-Hub-only
images, fixed tag, reserved/recommended host ports, non-root user, per-service
healthcheck/TZ/restart, data path below the application data root, never the
`/Volume*` wildcard, comment-free sequence blocks, `x-app-meta` position, no
literal secrets and the SVG size/element limits).

## Local verification

```bash
./TOSAppSelfTestingTool -c out/pigallery2docker.tar.gz   # official spec check
bash test/install-and-verify.sh                  # on-device E2E (needs root)
```

> Docker applications cannot be side-loaded through the App Center's manual
> install page (it accepts `.deb` only); the official self-testing tool's `-i`
> mode or `docker compose` are the only ways to install one for testing.

## Store submission checklist

1. Public GitHub repo (code + README only).
2. Release **tag `v3.5.2-1`**, assets `pigallery2docker.tar.gz` +
   `pigallery2docker.tar.gz.sha256` (Docker asset naming: `<app_id>.tar.gz`, **no
   platform suffix**).
3. Developer platform → Add Application: ID `pigallery2docker`, package type Docker,
   repository URL, architecture `x86_64`.
4. Version Management → Add Version `3.5.2-1` → automated validation → review.

## License / branding

PiGallery2 is distributed by its upstream authors under **MIT**. The container image is the official image from Docker Hub (`bpatrik/pigallery2:3.5.2`) and is used unmodified; no upstream source code is redistributed here. This packaging is an independent community submission by Moechz and is not affiliated with the upstream project or TerraMaster.

## Limitations

- The images folder is not visible in TOS File Manager; add photos over SMB/SSH.
- Indexing a large library takes time and thumbnails consume extra disk space.
- The UI is plain HTTP; use a TLS reverse proxy before exposing it to the internet.

---

Packaged for TOS 7 by Moechz. Upstream image used unmodified from Docker Hub.
