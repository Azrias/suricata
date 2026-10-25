# Upstream community and issue tracking

Verified against official sources on 2026-10-25. These links are for OISF's
upstream project, not this fork's GitHub Issues.

| Resource | Use |
| --- | --- |
| [Suricata forum](https://forum.suricata.io/) | Community discussion and support. |
| [Forum: Help](https://forum.suricata.io/c/help/5) | Build, installation, configuration, and usage questions. |
| [Forum: Developers](https://forum.suricata.io/c/developers/8) | Discuss implementation, Windows portability, and proposed changes. |
| [Suricata issue tracker](https://redmine.openinfosecfoundation.org/projects/suricata/issues) | Track bugs, features, tasks, and upstream fixes in OISF Redmine. |
| [Tracker search](https://redmine.openinfosecfoundation.org/projects/suricata/search?scope=subprojects) | Search existing tickets before reporting a duplicate; includes subprojects. |

The upstream [README](README.md#resources) identifies the forum as the user
support forum and Redmine as the bug tracker. The forum's official
[Help](https://forum.suricata.io/c/help/5) and
[Developers](https://forum.suricata.io/c/developers/8) categories separate support
and development discussion. Redmine's [project overview](https://redmine.openinfosecfoundation.org/projects/suricata)
lists its issue types, including Bug, Feature, Task, and Documentation.

## Using these resources for this Windows fork

1. Search the forum and tracker first. Useful terms include `Windows`, `MSYS2`,
   `UCRT64`, `mingw`, `cargo test`, and `suricata-verify`.
2. Use the forum when asking how something should work or discussing a proposed
   approach. For a reproducible upstream bug, use Redmine and link any related
   forum discussion. Keep fork-only tooling problems distinct from engine bugs.
3. Include the upstream commit, Windows/MSYS2 environment, toolchain versions,
   `suricata --build-info`, exact commands, and relevant logs. For test failures,
   include test names and the pinned suricata-verify commit. Remove credentials
   and sensitive traffic before sharing.
4. Before submitting a fix upstream, follow the official
   [contribution process](https://docs.suricata.io/en/latest/devguide/contributing/contribution-process.html).
   The upstream [PR template](.github/PULL_REQUEST_TEMPLATE.md) requires a Redmine
   ticket and its link.

These steps are a practical reporting checklist for this fork, not a claim that
the resources are synchronized with GitHub. No accounts or public reports are
created by this project.

## Local issue copy

Run `powershell -NoProfile -File scripts/sync-redmine.ps1` from the repository
root to download all public, non-closed Suricata issues, including comments,
change history, and attachment links. Attachment binaries and the forum are
not mirrored. This is read-only: local edits are never published to Redmine.

Browse the last completed export at
[the local mirror index](.scratch/upstream-redmine/README.md). Generated data
is Git-ignored. Refreshes reuse cached unchanged issues and preserve earlier
snapshots. Keep personal notes outside the generated mirror directory.

See [agent issue-tracker conventions](docs/agents/issue-tracker.md) for local
tasks and triage. Offline exporter checks:
`powershell -NoProfile -File scripts/test-sync-redmine.ps1`.

## Security reports are private

Report suspected vulnerabilities to [security@oisf.net](mailto:security@oisf.net),
not a public forum post or ordinary public ticket. The upstream
[security policy](SECURITY.md#reporting-issues) asks for detailed reproduction
information, recommends a suricata-verify reproducer, and describes private
security tickets.
