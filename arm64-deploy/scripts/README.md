# arm64 offline package — build / deploy / verify scripts

Operational scripts for the ARM64 offline deployment package. Each is **self-contained** and
runs on **any** server (build: any arm64 host, or x86 with QEMU; deploy/verify: a fresh
arm64 VM — AnolisOS / Kylin V10). No dependency on a prior local deploy.

| Script | Runs on | Purpose |
|---|---|---|
| `build-offline-package.sh` | any arm64 host w/ docker+git (or x86+QEMU) | Sources `arm64-deploy` from **this git repo** (complete dumps + hardened compose), fetches static docker aarch64 bins from OSS, pulls 9 images from ACR, `docker save` + tar (+ optional OSS upload). |
| `deploy-offline-fresh-vm.sh` | fresh arm64 VM | Download the OSS package, install docker from static aarch64 bins, `docker load`, `compose up`. |
| `verify-branch-fresh-vm.sh` | fresh arm64 VM | Reuse a released package for docker+base images, **override** `platform`/`web` with a branch-tagged image + swap in new dumps/compose, boot & assert (incl. **no `flyway_schema_history`**). |

## Build on any server

```bash
# arm64 host (or x86 with the containerd snapshotter for --platform)
git clone <repo> && cd primihub-platform
ACR_USER=... ACR_PASS=... PTAG=<platform/web tag> TS=<version> \
  bash arm64-deploy/scripts/build-offline-package.sh
# add OSS_ID=... OSS_SECRET=... to also publish to OSS
```

Prereqs: `git`, `docker` (arm64 native, or x86 w/ QEMU + containerd snapshotter for
`docker save --platform linux/arm64`), `curl`, `python3` (only for OSS upload).
All inputs are env vars — see the header of each script. The package version (`TS`) and the
platform/web image tag (`PTAG`) are independent so you can repackage without rebuilding images.

## Schema ownership (post-Flyway)
The base dumps in `../data/initsql/privacy{1,2,3}.sql` own the **complete** schema
(Flyway was removed). Drift is caught at CI time by `test-tools/mapper_check.py`
(workflow `.github/workflows/schema-drift-check.yml`), not at runtime. To edit the schema:
change `test-tools/dump-fixup.sql`, re-run `test-tools/regen-base-dumps.sh`, commit the dumps.

Post-deploy functional smoke test: `test-tools/functional_verify.py` (runs on the VM against
`localhost:30811`; logs in + exercises ~45 endpoints, flags any SQL-shape error).
