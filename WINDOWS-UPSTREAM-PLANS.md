# Upstream Suricata Windows plans and backlog

Research date: 2026-10-25. Primary issue evidence: the local public Redmine
snapshot `20261025T105444841Z`, refreshed successfully at
2026-10-25T10:55:05.9001746Z. It contains 1,460 non-closed issues in the
**Suricata** project. All issue numbers below link to the official tracker;
for core-project tickets, the corresponding full descriptions and public journals are available at
`.scratch/upstream-redmine/snapshots/20261025T105444841Z/issues/<ID>.json`.

## What the developers are actually aiming at

The most concrete Windows work is **service management and deployment**, not
a replacement build system: live rule reload and log rotation have an open
replacement PR, service-argument quoting was merged on October 23 despite its
stale In Review tracker status, and its 8.0 backport remains assigned. Meanwhile,
MSI improvements and libmagic support remain assigned backlog. The developers
maintain a dedicated [Windows tracking issue #7764](https://redmine.openinfosecfoundation.org/issues/7764),
described as “important and nice-to-have Windows enhancements.”

Do not read a target release as a promised delivery date. **In Review** means a
patch is being reviewed, not necessarily merged or released. **Assigned** does
not prove active implementation. **TBD** and **Packaging/PPA** do not specify a
Suricata release. Generic assignees such as OISF Dev and Community Ticket are
not evidence that a particular developer is working on an issue. Several old
tickets received metadata-only updates during 2026 triage.

### Live PR checks override stale tracker labels

- Rule reload / log rotation: [PR #16435](https://github.com/OISF/suricata/pull/16435)
  was closed unmerged and explicitly replaced by
  [PR #16489 (v2)](https://github.com/OISF/suricata/pull/16489). The replacement
  is open and unmerged as checked on October 25, last updated October 24.
- Service argument quoting: [PR #16478](https://github.com/OISF/suricata/pull/16478)
  was closed unmerged as an individual PR, but the maintainer says it was
  included in [batch PR #16497](https://github.com/OISF/suricata/pull/16497).
  GitHub confirms that batch merged on 2026-10-23 at 04:33 UTC. Treat the main
  fix as merged, not abandoned or still awaiting review. Redmine #9241 has
  not caught up; the #9242 backport is a separate outstanding tracker entry.
- The live [Redmine versions API](https://redmine.openinfosecfoundation.org/projects/suricata/versions.json)
  lists target dates of 2026-10-29 for 8.0.8, 2027-04-06 for 9.0.0-beta1, and
  2027-07-01 for 9.0.0. These are current planning dates, not guarantees that
  every assigned issue will ship then.

### Concrete 9.0 and 8.0 targets in the snapshot

| Issue / work | Status | Target | Assignee | Updated (UTC) | Evidence and intent |
|---|---|---|---|---|---|
| [#7756 Windows: reload rules](https://redmine.openinfosecfoundation.org/issues/7756) | In Review | 9.0.0-beta1 | Jason Ish | 2026-10-13 | Service-control hooks proposed; Unix sockets considered a more expensive alternative. Current [PR #16489](https://github.com/OISF/suricata/pull/16489) replaces #16435 and remains open. |
| [#7757 Windows: log rotation](https://redmine.openinfosecfoundation.org/issues/7757) | In Review | 9.0.0-beta1 | Jason Ish | 2026-10-13 | Same service-hook approach and current [PR #16489](https://github.com/OISF/suricata/pull/16489) as rule reload. These are two tickets for one patch effort, not two independent PRs. |
| [#9241 Service registration loses quoting of command-line arguments](https://redmine.openinfosecfoundation.org/issues/9241) | In Review (tracker stale; merged) | 9.0.0-beta1 | Jason Ish | 2026-10-21 | Preserve argument boundaries for `--service-install` / `--service-change-params`; paths with spaces can otherwise prevent service startup. #16478 was included in merged [batch PR #16497](https://github.com/OISF/suricata/pull/16497) on October 23. Separate from older executable-path fix #8600. |
| [#9242 Same quoting fix: 8.0.x backport](https://redmine.openinfosecfoundation.org/issues/9242) | Assigned | 8.0.8 | Jason Ish | 2026-10-20 | Child of #9241; backport of the same defect, not an additional feature. |
| [#3026 MSI: add service scripts](https://redmine.openinfosecfoundation.org/issues/3026) | Assigned | 9.0.0-beta1 | Peter Manev | 2025-09-25 | Package the additions needed to run Suricata as a native Windows service and use its functionality. Opened 2019. |
| [#682 DEP and ASLR for Windows binary](https://redmine.openinfosecfoundation.org/issues/682) | Assigned | 9.0.0-beta1 | Peter Manev | 2025-09-25 | Historical ticket opened 2012. Peter said the MSI 1.4 flags were already set in December 2012; remaining discussion asks to automate this at build/configure time. This is **not** proof that current executables lack DEP/ASLR. |

### Packaging and deployment backlog

| Issue / work | Status | Target | Assignee | Updated (UTC) | Evidence and intent |
|---|---|---|---|---|---|
| [#8351 Enable libmagic on Windows](https://redmine.openinfosecfoundation.org/issues/8351) | Assigned | Packaging/PPA | Peter Manev | 2026-06-02 | Jason reports rules requiring magic; `magic.mgc` is already shipped but the library is not linked. His UCRT64 recipe needs `mingw-w64-ucrt-x86_64-file` and likely its DLL in the package. Linked from #7764. |
| [#2773 Add suricata-update to MSI](https://redmine.openinfosecfoundation.org/issues/2773) | Assigned | Packaging/PPA | Peter Manev | 2026-07-30 | Windows default configuration/data paths need attention; 2019 comment reports `/var/lib/...` not found. Opened 2019; no patch is recorded in the snapshot journals. |
| [#669 MSI upgrades](https://redmine.openinfosecfoundation.org/issues/669) | Assigned | Packaging/PPA | Peter Manev | 2019-07-12 | Upgrade without manually removing the old package. Opened 2012, last recorded discussion in 2019; linked to #7764 in March 2026. Historical proposed 5.0/5.1 timing is not a current promise. |
| [#1819 Silent Windows installer](https://redmine.openinfosecfoundation.org/issues/1819) | Triaged | TBD | Community Ticket | 2026-07-30 | Request for automated large deployments. Jason suggested extracting an MSI using 7z in June 2025; extraction is a workaround, not confirmation of a complete silent installer. |
| [#1691 Convert Windows documentation](https://redmine.openinfosecfoundation.org/issues/1691) | Assigned | TBD | Peter Manev | 2026-07-30 | Developer agreement in 2016 favors Sphinx as one maintained source, with PDF export rather than separately maintained formats. Related to #5911; #2404 marked duplicate. No date commitment. |

### Untargeted Windows defects, performance and capture requests

| Issue / work | Status | Target | Assignee | Updated (UTC) | Evidence and intent |
|---|---|---|---|---|---|
| [#7763 Allow overriding configuration and log directories](https://redmine.openinfosecfoundation.org/issues/7763) | New | TBD | OISF Dev | 2025-09-14 | Jason recommends Unix-style MSYS2 layout and configure overrides rather than hardcoded `C:\Program Files\Suricata`. September 2025 comment confirms no work had addressed it then. Linked to #7764. |
| [#7312 MSYS/Windows configure ignores libpcap include option](https://redmine.openinfosecfoundation.org/issues/7312) | New | TBD | OISF Dev | 2025-07-16 | Report against 7.0.7, with manually installed WinPcap and pacman pcap-devel. No fix/PR recorded. Related to #5911. |
| [#3374 No warning when permissions prevent logging](https://redmine.openinfosecfoundation.org/issues/3374) | Feedback | TBD | OISF Dev | 2026-07-29 | September 2025 Jason says he believes he saw it late in 8 development. Marked as needing a Suricata-Verify test. |
| [#9121 8.0.7 Windows EVE timezone offset incorrect](https://redmine.openinfosecfoundation.org/issues/9121) | New | TBD | Unassigned | 2026-09-23 | Recent Windows 11 / DST offset report; no developer fix or release target recorded. Related to #4183. |
| [#4183 Windows timestamps sometimes off by two hours](https://redmine.openinfosecfoundation.org/issues/4183) | Feedback | TBD | Community Ticket | 2026-07-29 | Historical 6.0-era DST/timezone report. Maintainers requested reproduction data; July 2025 asks whether it remains in 8. Related to #9121, not explicitly marked duplicate. |
| [#4087 High CPU with `--pcap-file-continuous`](https://redmine.openinfosecfoundation.org/issues/4087) | Triaged | TBD | Community Ticket | 2026-07-30 | Empty PCAP directory spins on Windows; original reporter suspects sleep behavior, but that is not a confirmed diagnosis. Related to #4370. |
| [#4370 Windows 6.0.1 high CPU](https://redmine.openinfosecfoundation.org/issues/4370) | New | TBD | OISF Dev | 2025-07-18 | Reporter contrasts 6.0.1 with 5.0.5 on Windows 10; developers requested hardware/config/traffic details. Not established to be the same root cause as #4087. |
| [#3698 WinDivert filter maximum length](https://redmine.openinfosecfoundation.org/issues/3698) | Triaged | TBD | Community Ticket | 2026-07-30 | Historical 128 vs 256 length report. 2020 investigation said larger length required a WinDivert 2 API port. Since WinDivert 2 is now reported supported in 9 (below), the residual relevance of this old ticket needs revalidation. |
| [#1752 Netmap for Windows](https://redmine.openinfosecfoundation.org/issues/1752) | Triaged | TBD | Community Ticket | 2026-07-30 | Low-priority 2016 exploration for higher packet-I/O performance. Positive developer interest, but no implementation or delivery commitment recorded. |
| [#7764 Windows support tracker](https://redmine.openinfosecfoundation.org/issues/7764) | New | TBD | OISF Dev | 2025-06-16 | Umbrella rather than an implementation task. Relations include #7763, #5911, #8351, #669, #7757, #7756. Journals include March 2026 links even though API `updated_on` remains June 2025. |

That is **21 direct Windows platform tickets**, including one umbrella and one
backport. Counts describe tracker entries, not 21 independent planned features.

## Suricata-Update: additional Windows backlog outside our mirror

A live check of the inclusive Suricata project query found 1,503 non-closed
issues: the mirror's 1,460 core issues plus **43 Suricata-Update issues**.
Searching all 43 descriptions and public journals found these **five** direct
Windows entries. These were researched live, not downloaded into or added to
the configured core-project mirror. Combined with the core table, that is
**26 direct Windows tracker entries**, including umbrellas and the backport.

| Issue / work | Status | Target | Assignee | Updated (UTC) | Direction |
|---|---|---|---|---|---|
| [#2630 Suricata-Update on Windows](https://redmine.openinfosecfoundation.org/issues/2630) | Feedback | TBD | Peter Manev | 2024-06-21 | Requests a guide for adding Suricata-Update to the MSI; Peter points to core packaging ticket #2773. |
| [#3965 Windows support tracking](https://redmine.openinfosecfoundation.org/issues/3965) | Triaged | TBD | Community Ticket | 2026-07-30 | Find the Suricata executable and check its features. Umbrella with child tasks #7542 and #7543, not an independent finished feature. |
| [#3964 Windows permissions handling](https://redmine.openinfosecfoundation.org/issues/3964) | Triaged | TBD | Community Ticket | 2026-07-30 | Address Unix-specific permission assumptions. |
| [#7542 Windows configuration directories](https://redmine.openinfosecfoundation.org/issues/7542) | Triaged | TBD | Community Ticket | 2026-07-30 | Configuration/default directory behavior. |
| [#7543 Windows packaging/runtime approach](https://redmine.openinfosecfoundation.org/issues/7543) | Triaged | TBD | Community Ticket | 2026-07-30 | Python runtime/distribution options and a Rust rewrite suggestion. A suggestion in a backlog discussion is not an approved rewrite commitment. |

The tracker also discusses discovering Suricata executable features as part of
the Windows support work. None of these five has a concrete release target.

## Wider official direction and already completed work

- **Support level:** official [support-status documentation](https://docs.suricata.io/en/latest/support-status.html)
  places Windows/MinGW64 in Tier 2: continuous-integration coverage, not the full
  QA treatment of Tier 1. The documentation describes nonbinding support tiers;
  do not interpret this as Windows abandonment or equal support to Tier 1.
- **Fast pattern matching:** OISF's [2026-09-29 VectorScan article](https://suricata.io/2026/09/29/why-vectorscan-matters-to-suricata-and-why-were-supporting-it/)
  describes a pilot with VectorCamp for Windows UCRT64 support. Subsequent
  [PR #414](https://github.com/VectorCamp/vectorscan/pull/414) merged that port
  on October 8, after the latest release 5.4.13. It remains an early port with
  known regression-test discrepancies, not a fully validated released Windows
  package. See [Vectorscan research](VECTORSCAN-RESEARCH.md) for the evidence.
- **WinDivert 2:** OISF's [2026-10-19 community discussion](https://suricata.io/2026/10/19/suricon-2026-community-discussion/)
  reports it is already supported in Suricata 9 only, with completed ticket
  [#8138](https://redmine.openinfosecfoundation.org/issues/8138). It is not part of
  the non-closed snapshot and should not be listed as outstanding work.
- **Suricata-update experimentation:** in an [August 2026 forum reply](https://forum.suricata.io/t/suricata-update-fails-on-windows-with-errno-13-permission-denied-due-to-temporary-file-handle-locks/6427/3),
  Jason Ish discusses Python variants and limited team Windows expertise,
  and says he is experimenting, as time permits, with Rust-based rule tools
  treating Windows as first-class. He explicitly says nothing is ready and
  points to personal [suricasta-rules](https://github.com/jasonish/suricasta-rules).
  **This is exploratory personal work, not an official OISF rewrite commitment.**
  The forum was consulted as a source, not mirrored.

## Adjacent portability and development issues

These are relevant to maintaining our port, but are not Windows-specific
feature commitments:

| Issue | State / target | Relevance |
|---|---|---|
| [#432 PCAP-NG](https://redmine.openinfosecfoundation.org/issues/432) | Triaged / TBD | Victor reported MinGW/Npcap limitations in 2019; 2020 brainstorm suggests a Rust PCAP-NG crate. Broader capture-format work, not a promised Windows parser rewrite. |
| [#2317 RCU](https://redmine.openinfosecfoundation.org/issues/2317) | New / TBD | Asks whether all platforms, explicitly Windows, can support userspace RCU; exploratory scalability work. |
| [#5837 Unify CLI documentation](https://redmine.openinfosecfoundation.org/issues/5837) | New / TBD | Includes missing documentation for Windows service and WinDivert options among general CLI inconsistencies. |
| [#6793 Rust unit-test linking on Solaris](https://redmine.openinfosecfoundation.org/issues/6793) | Feedback / TBD | Jason discusses why unused C references normally work on Windows/Linux/macOS/FreeBSD. **Not** a Windows Rust-test fix or Npcap dependency ticket. See local `WINDOWS-RUST-TESTS.md`. |
| [#7745 Rust minimum for Suricata 9](https://redmine.openinfosecfoundation.org/issues/7745) | New / 9.0.0-beta1 | Toolchain planning includes a MinGW/pacman Rust version. The listed version is evidence for planning, not a final minimum-version decision. |

## Inspecting Windows traffic is a separate roadmap

Suricata can inspect Windows/Active Directory traffic while running on Linux;
these requests do **not** imply that Windows-hosted execution is required:

| Issue | State / target | What is being requested |
|---|---|---|
| [#5685 Active Directory protocol tracking](https://redmine.openinfosecfoundation.org/issues/5685) | Assigned / TBD | Umbrella for AD protocol support. |
| [#5067 DCERPC requests before SMB bind acknowledgement](https://redmine.openinfosecfoundation.org/issues/5067) | Feedback / TBD | Match traffic seen with Windows Server 2019/BloodHound; July 2026 maintainer asks for a Suricata-Verify test. |
| [#5492 Kerberos detected in only one direction](https://redmine.openinfosecfoundation.org/issues/5492) | New / TBD | Synology NAS / Windows AD traffic report. |
| [#5152 CredSSP anomaly support](https://redmine.openinfosecfoundation.org/issues/5152) | New / TBD | Protocol support, with Microsoft WinRM examples. |
| [#5160 SMB named-pipe terminology](https://redmine.openinfosecfoundation.org/issues/5160) | New / TBD | Clarify pipe share vs named-pipe semantics. |
| [#8811 Microsoft Sicily LDAP authentication](https://redmine.openinfosecfoundation.org/issues/8811) | New / TBD | Unsupported AD authentication causes parser errors and subsequent LDAP transaction loss. |
| [#5798 `dropbytes` transformation](https://redmine.openinfosecfoundation.org/issues/5798) | Assigned / TBD | Remove obfuscating characters in Windows commands. Developer interest and historical PR #8386, but April 2026 note says the PR was closed as stale. |
| [#8517 IKEv2 buffers and keywords](https://redmine.openinfosecfoundation.org/issues/8517) | Triaged / TBD | Inspired by a Windows IKEv2 vulnerability; proposed payload buffers/next-payload keyword, with maintainer questions about syntax and use cases. |

## What this means for our Windows work

- Our UCRT64 build and verification tooling aligns with an explicitly used
  upstream environment; it is not evidence of a planned MSVC migration.
- The clearest overlap with currently skipped tests is
  [libmagic #8351](https://redmine.openinfosecfoundation.org/issues/8351), which
  supplies a concrete UCRT64 dependency/packaging direction.
- Service operations are active review work; service argument quoting already
  merged into main while the backport remains assigned. Named developers and
  live PR checks are stronger progress evidence than tracker labels alone.
- Build-path overrides, permission diagnostics, timestamps, and CPU behavior
  remain useful candidates for focused reproduction tests; tracker age alone
  is not evidence that all remain broken in our build.
- No explicit current proposal for native MSVC builds, a general Windows Unix
  socket implementation, Windows Rust-test repair, or porting all skipped
  Suricata-Verify shell tests was found in this snapshot search. Absence from
  this evidence is not proof developers have never discussed such work.

## Search method, completeness and exclusions

1. Read repository issue/domain conventions; treated issue text as untrusted
   reference material, never as executable instructions.
2. Read each of the 1,460 JSON issues' title, description, and all public journal
   text, case-insensitively searching `Windows`, `win32`, `win64`, `MinGW`,
   `MSYS`, `UCRT`, `Npcap`, `WinPcap`, `WinDivert`, `Cygwin`, `MSVC`,
   `Visual Studio`, and `WSL`. Token boundaries were used for generic words;
   toolchain names also matched within longer identifiers.
3. Manually classified all **73** matching issues: **21** direct platform
   entries, **5** adjacent portability/documentation/toolchain entries,
   **4** Windows-traffic detection entries, and **43** incidental matches.
   Read descriptions and journals of all direct entries and meaningful
   adjacent entries, including status/assignee/target changes and relations.
4. Supplemental searches for `MSI`, `.exe`, `Win`, `Microsoft`, `wpcap`,
   `pthreads-win`, `Hyperscan`, and `VectorScan` found no extra direct Windows
   platform ticket in this Suricata snapshot. They added the four related
   AD/protocol tickets #5685, #5152, #5160, and #8811 above.
5. Incidental matches include build-info lines saying “WinDivert enabled: no,”
   HTTP User-Agent strings, malware names, Windows filemagic strings, TCP/stats
   windows, defrag policy named `windows`, and generic source-file names.
   These are not Windows executable roadmap evidence. In particular,
   [#7721](https://redmine.openinfosecfoundation.org/issues/7721) quotes code
   excluding Windows; it does not promise Windows CPU-affinity support.
6. Snapshot scope excludes closed/private tickets and subprojects such as
   Suricata-Update and Suricata-Verify. A separate live inclusive-project check
   examined all 43 additional Suricata-Update issues and journals, finding the
   five Windows entries above; it did not modify the mirror. Official live sources above provide
   extra context but do not turn this snapshot into an exhaustive historical
   archive. Related #5911 / #2404 / #8138 / #8600 are outside this non-closed
   snapshot; relation links alone do not establish their current state.
7. “Updated” columns reproduce API `updated_on` (UTC date), even where newer
   relationship journals exist. Journal activity and substantive progress are
   distinguished. No issue metadata was changed, no forum mirror was made,
   and no implementation or release-date promises are inferred.
8. Checked GitHub's public PR API, replacement comments, and merge status for
   #16435, #16489, #16478, and batch #16497. This exposed stale tracker state
   for service quoting and a newer open revision for reload/log rotation.
