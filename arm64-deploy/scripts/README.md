# arm64 offline package — build / deploy / verify scripts

Operational scripts for the ARM64 offline deployment package. Run **on an ARM64 VM**
(AnolisOS / Kylin V10), except where noted.

| Script | Runs on | Purpose |
|---|---|---|
| `build-offline-package.sh` | ARM VM w/ docker | Pull `platform`/`web:$PTAG` from ACR, assemble `arm64-deploy` + `docker save` 9 images + `docker-bins.tar` → `.tar.gz`, upload to OSS. Env: `ACR_USER ACR_PASS OSS_ID OSS_SECRET`; `TS`/`PTAG` set the package/image version. |
| `deploy-offline-fresh-vm.sh` | fresh ARM VM | Download the OSS package, install docker from static aarch64 bins, `docker load`, `compose up`. Set `PKG_URL`. |
| `verify-branch-fresh-vm.sh` | fresh ARM VM | Reuse a released package for docker+base images, **override** `platform`/`web` with a branch-tagged image + swap in new dumps/compose, boot & assert. Env: `ACR_USER ACR_PASS PTAG`. |

## Schema ownership (post-Flyway)
The base dumps in `../data/initsql/privacy{1,2,3}.sql` own the **complete** schema
(Flyway was removed). Drift is caught at CI time by `test-tools/mapper_check.py`
(workflow `.github/workflows/schema-drift-check.yml`), not at runtime. To edit the schema:
change `test-tools/dump-fixup.sql`, re-run `test-tools/regen-base-dumps.sh`, commit the dumps.

Post-deploy functional smoke test: `test-tools/functional_verify.py` (runs on the VM against
`localhost:30811`; logs in + exercises ~45 endpoints, flags any SQL-shape error).
