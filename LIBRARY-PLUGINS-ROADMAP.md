# Suricata library and plugin roadmap: developer evidence

Research date: 2026-10-25. This note separates maintainer commitments, completed
work, open proposals, and Windows-specific evidence. It complements source-code
inspection and local Windows experiments; it does not claim that a tracker target
is a release guarantee or that a platform works merely because generic APIs exist.

## Most important finding: the library is not merely an abandoned experiment

Jason Ish answered this exact maturity question on **October 1, 2026**:

> Mature in terms of stability. Suricata itself is really just a user of the
> library. However, its less mature when it comes to developer experience and
> stability of APIs.

He then stated that **as of 8.0, the API is considered stable within a major
release**: patch releases should not break ABI/API unless completely unavoidable;
major releases may break it. The intended integration is to bring your own packets
and threads into an existing packet-based system. Work remains on usability and
adapting to different environments. This is stronger and more current evidence
than describing all library support as experimental simply because its umbrella
ticket remains open. [Maintainer answer](https://forum.suricata.io/t/libsuricata-status/6476/3)

This is a policy statement, **not** a guarantee that every public/internal header
is a polished SDK, that arbitrary compiler/runtime combinations interoperate, or
that Windows embedding and DLL plugins are certified. The same statement expressly
acknowledges developer-experience and API limitations.

## Three different meanings of extension

- **Embedding libsuricata:** another executable owns the process and invokes the
  engine, supplies packets/threads, and handles events. This is the subject of
  [#2693](https://redmine.openinfosecfoundation.org/issues/2693).
- **Loading a Suricata plugin:** the Suricata executable owns the engine and loads
  an extension implementing capture, EVE output, application protocols, detection
  keywords, etc. This is [#4101](https://redmine.openinfosecfoundation.org/issues/4101).
- **Making a plugin for another application:** e.g. a VPP or c-icap module that
  embeds libsuricata. This is embedding, not proof that Suricata's own plugin
  loader supports the host platform. See the [VPP support discussion
  #8082](https://redmine.openinfosecfoundation.org/issues/8082) and the
  [icapsuricata prototype](https://forum.suricata.io/t/6357/1).

Likewise, the Rust static library and C/Rust FFI used inside Suricata are not by
themselves evidence of a standalone, stable Rust embedding SDK or a Windows DLL.
The library build history explicitly distinguishes the component C/Rust archives
from a combined library. [#4221](https://redmine.openinfosecfoundation.org/issues/4221)

## Library work already delivered

| Capability | Evidence | Interpretation |
|---|---|---|
| Basic static/shared library construction | [#4221](https://redmine.openinfosecfoundation.org/issues/4221), closed; [PR #5866](https://github.com/OISF/suricata/pull/5866), merged February 18, 2021 | Basic support is real. The maintainer's May 2021 completion note explicitly limited shared-library support to Linux **at that time**. Do not extrapolate that historical statement into proof of current Windows impossibility. |
| Minimal alternate-main example | [#4698](https://redmine.openinfosecfoundation.org/issues/4698), closed, 8.0-beta1 | Demonstrates bootstrapping, programmatic configuration, and rules from a buffer. |
| User-provided threads and packets | [#7240](https://redmine.openinfosecfoundation.org/issues/7240), closed, 8.0-beta1 | Jason states the foundation was in master April 1, 2025; new missing hooks should have separate tickets. |
| Opt-in signal handlers | [#6814](https://redmine.openinfosecfoundation.org/issues/6814), closed, 8.0.0 | Intended to keep library code from imposing application-level signal handlers. |
| EVE output callback registration outside plugin-specific API | [#6838](https://redmine.openinfosecfoundation.org/issues/6838), closed, 8.0-beta1 | Useful for library consumers registering custom event destinations. |
| Flow initialization/update callbacks | [#7319](https://redmine.openinfosecfoundation.org/issues/7319), [#7320](https://redmine.openinfosecfoundation.org/issues/7320), closed | [PR #12109](https://github.com/OISF/suricata/pull/12109) recorded as merged in both tickets. |
| Rate-filter callback | [#7673](https://redmine.openinfosecfoundation.org/issues/7673), closed, 8.0-rc1 | A customization hook, not a general packetless scanning interface. |
| Live packet-source example and lifecycle fixes | [#8096](https://redmine.openinfosecfoundation.org/issues/8096), closed; [#8097](https://redmine.openinfosecfoundation.org/issues/8097), closed 8.0.4 backport | Not just an offline-PCAP feature. The PR chain ends in merged [batch #14961](https://github.com/OISF/suricata/pull/14961), March 6, 2026. |

The live-example chain matters: [#14293](https://github.com/OISF/suricata/pull/14293)
and [#14919](https://github.com/OISF/suricata/pull/14919) are individually closed
unmerged, but #14919 was replaced by
[#14953](https://github.com/OISF/suricata/pull/14953), whose maintainer comment says
it was merged through #14961. Calling the whole effort abandoned based on the
first PR would be wrong.

## Library work still outstanding

Live Redmine status/owner/target checked October 25, 2026:

| Issue | Status / owner | Target | What is actually proposed |
|---|---|---|---|
| [#2693](https://redmine.openinfosecfoundation.org/issues/2693) | In Progress / Jason Ish | 9.0-beta1 | Long-running library umbrella; goals include opt-in application behavior, fewer globals, improved integration. Victor's July 2025 note says work continues toward 9.0. |
| [#8098](https://redmine.openinfosecfoundation.org/issues/8098) | Assigned / Victor Julien | 9.0.0 | Release-level library tracking, not a detailed standalone API specification. |
| [#8095](https://redmine.openinfosecfoundation.org/issues/8095) | Assigned / Jason Ish | 9.0-beta1 | Expose ruleset/tenant reload handles that library consumers can call directly; ideally backportable to 8. |
| [#4704](https://redmine.openinfosecfoundation.org/issues/4704) | New / OISF Dev | 9.0-beta1 | Separate command functionality from Unix-socket transport so library users and other interfaces can invoke it. |
| [#8106](https://redmine.openinfosecfoundation.org/issues/8106) | In Progress / Jason Ish | 9.0-beta1 | Stop keeping SCInstance in a global; pass the instance as appropriate. |
| [#4429](https://redmine.openinfosecfoundation.org/issues/4429) | Assigned / Jason Ish | 9.0-beta1 | More use-case examples. |
| [#9152](https://redmine.openinfosecfoundation.org/issues/9152) | Assigned / Jason Ish | 9.0-beta1 | Make OpenBSD pledge opt-in; platform-specific evidence that embedding still encounters lifecycle assumptions. |
| [#8109](https://redmine.openinfosecfoundation.org/issues/8109) | Triaged / OISF Dev | 9.0-beta1 | Avoid identifying every embedding executable as Suricata in its startup message. |
| [#4684](https://redmine.openinfosecfoundation.org/issues/4684) | Assigned / Jason Ish | TBD | Global context types for instance/per-thread storage. |
| [#5433](https://redmine.openinfosecfoundation.org/issues/5433) | Assigned / Jason Ish | TBD | Reduce unnecessarily public data structures. |
| [#6752](https://redmine.openinfosecfoundation.org/issues/6752) | New / OISF Dev | TBD | Keep autoconf implementation details out of public headers. |
| [#6754](https://redmine.openinfosecfoundation.org/issues/6754) | New / OISF Dev | TBD | Namespaced include-file layout. |
| [#8631](https://redmine.openinfosecfoundation.org/issues/8631) | Triaged / OISF Dev | TBD | Resolve leakage of stream-tcp-private.h through public headers; raised by a real embedding integration. |
| [#6858](https://redmine.openinfosecfoundation.org/issues/6858) | New / OISF Dev | TBD | Flow-expectation creation hook. |
| [#4430](https://redmine.openinfosecfoundation.org/issues/4430) | Assigned / Jason Ish | None | Apache/Nginx embedding example, not an available official integration. |
| [#4431](https://redmine.openinfosecfoundation.org/issues/4431) | In Progress / OISF Dev | TBD | libnids/network-grep example. Despite its status, Philippe explicitly unassigned himself May 1, 2026 because he had no plans to work on it. |
| [#4432](https://redmine.openinfosecfoundation.org/issues/4432) | New / OISF Dev | TBD | Wireshark-plugin example; described as a briefly mentioned idea. |
| [#9150](https://redmine.openinfosecfoundation.org/issues/9150) | New / unassigned | TBD | Direct, already-reassembled stream input, without synthetic IP/TCP packets. **Explicitly not on the near-term roadmap.** |

### Reload API: a real request, not a confirmed finished API

In [#8082](https://redmine.openinfosecfoundation.org/issues/8082), Jason explained
that library users must adapt to Suricata's threading model; the PCAP source in
an example is replaceable. On June 18, 2026, he explicitly said he had **not started
#8095**. The live #8095 ticket still has its November 2025 discussion, not a linked
completed implementation.

Victor explains why reloads are more than simply replacing a rules pointer:
configuration, detection contexts, per-thread contexts, pointer swaps, waiting for
workers to stop using old contexts, and waking idle capture loops must be
coordinated. Jason wants callable handles initially reproducing existing
Unix-socket functionality. [#8095 discussion](https://redmine.openinfosecfoundation.org/issues/8095)

### Raw application data: not the present high-level API

On October 1, Jason created #9150 and explicitly said it is **not on the near-term
roadmap**. Current adapters reconstruct packets. On October 2 he distinguished
the experimental open-source icapsuricata prototype from the pattern itself:
they have heard of closed-source production users, and the packet-input pattern
will remain first class. This is not proof that any particular third-party
prototype is production-ready. [Forum #6477, posts 3 and 5](https://forum.suricata.io/t/packetless-application-layer-interface/6477/3)

The [icapsuricata discussion](https://forum.suricata.io/t/6357) is useful integration
evidence: synthetic TCP/IP, ACK/FIN handling, OpenBSD sandbox ownership, prefork
initialization, and long-lived worker/statistics lifecycles all matter. Its
October 19 statistics/crash analysis is **the integrator's report**, explicitly
qualified by its author as potentially imperfect, not an independently confirmed
upstream diagnosis. Do not copy its workarounds into another host uncritically.

## Plugins: substantial functionality shipped, ecosystem still developing

The umbrella [#4101](https://redmine.openinfosecfoundation.org/issues/4101) remains
In Progress, Jason Ish, TBD; its description says the goal is getting plugins out
of an experimental state. That does not mean its completed subfeatures are absent.

Completed 8.0 work includes:

- Full application-protocol plugin support: parser, logging, detection keywords
  ([#4102](https://redmine.openinfosecfoundation.org/issues/4102), closed).
- Dynamic application-protocol IDs
  ([#5053](https://redmine.openinfosecfoundation.org/issues/5053), closed).
- Internal SNMP registration using the same API
  ([#4103](https://redmine.openinfosecfoundation.org/issues/4103), closed).
- Templates and developer documentation for app-layer, logging, detection, and
  capture plugins ([#7149](https://redmine.openinfosecfoundation.org/issues/7149),
  [#7150](https://redmine.openinfosecfoundation.org/issues/7150),
  [#7151](https://redmine.openinfosecfoundation.org/issues/7151),
  [#7152](https://redmine.openinfosecfoundation.org/issues/7152),
  [#7153](https://redmine.openinfosecfoundation.org/issues/7153),
  [#7154](https://redmine.openinfosecfoundation.org/issues/7154),
  [#4105](https://redmine.openinfosecfoundation.org/issues/4105), all closed).
- PF_RING and Napatech moved to bundled plugins
  ([#7162](https://redmine.openinfosecfoundation.org/issues/7162),
  [#7165](https://redmine.openinfosecfoundation.org/issues/7165), closed).
- Delayed initialization so plugins/library users can register transaction
  loggers ([#7236](https://redmine.openinfosecfoundation.org/issues/7236), closed).
  [PR #13393](https://github.com/OISF/suricata/pull/13393) was incorporated into
  merged [batch #13397](https://github.com/OISF/suricata/pull/13397), June 8, 2025.
- EVE filetype example: #4104 was closed March 12, 2026 with Jason pointing to
  `examples/plugins/c-json-filetype`.

Relevant unfinished work:

| Issue | Status / owner / target | Meaning |
|---|---|---|
| [#6370](https://redmine.openinfosecfoundation.org/issues/6370) | Assigned / Jason Ish / 9.0-beta1 | Install libsuricata-config with headers or by default. A plugin needs headers/config tooling, not necessarily linking the standalone engine library. |
| [#7499](https://redmine.openinfosecfoundation.org/issues/7499) | New / OISF Dev / TBD | First-class Rust plugin support: missing bindings and possible helper crate/module. |
| [#7500](https://redmine.openinfosecfoundation.org/issues/7500), [#7501](https://redmine.openinfosecfoundation.org/issues/7501) | New / OISF Dev / TBD | Rust EVE-filetype and app-layer support. These are improvements, not evidence that no Rust plugin can exist today. |
| [#7782](https://redmine.openinfosecfoundation.org/issues/7782) | Assigned / Jason Ish / TBD | Investigate libabigail ABI-change checks. Jason says he is working on it as time permits; Rust symbols make results noisy. This is not a completed ABI-verification guarantee. |
| [#7840](https://redmine.openinfosecfoundation.org/issues/7840) | Assigned / Jason Ish / 9.0-beta1 | Document transaction logger registration. The underlying capability #7236 is already implemented. |
| [#4070](https://redmine.openinfosecfoundation.org/issues/4070) | Triaged / Community Ticket / TBD | Notify capture plugins when processing is finished so externally owned packets can be reclaimed safely. |
| [#8094](https://redmine.openinfosecfoundation.org/issues/8094) | Triaged / OISF Dev / TBD | Package-manager idea spanning native plugins, Lua, possibly rules. Discusses source builds, dependencies, distribution, registries. Not a shipped official package manager. |

The developer guide documents a native `SCPluginRegister` entry point and YAML
plugin paths, and an app-layer Rust example. It warns against passing non-`repr(C)`
Rust layouts such as JsonBuilder across the boundary; use opaque-pointer C APIs.
Thus “Rust plugins exist” must not be confused with “arbitrary Rust crate versions
can share Rust-native data layouts safely.” [Current checkout developer guide](doc/userguide/devguide/libsuricata/index.rst)

### nDPI: active compatibility work, not yet new-version support in main

[#8077](https://redmine.openinfosecfoundation.org/issues/8077) remains In Review,
Community Ticket, TBD. Victor said January 5, 2026 that the team did not plan to do
the upgrade themselves and welcomed ntop/community work. Karim later offered a
working version. Jason discussed potentially externalizing the plugin so it can
evolve independently. Neither comment is a promise of Windows support.

The original [PR #15939](https://github.com/OISF/suricata/pull/15939) is closed
unmerged. The important current proposal is
[**PR #16354**](https://github.com/OISF/suricata/pull/16354), **open, unmerged**,
last updated October 14: compatibility with nDPI 4.12+, 5.0, and 6.0, with a
CentOS Stream CI matrix. Its claimed tests are the contributor's report, not a
Windows validation. Its additional nDPI-6 licensing discussion must not be
presented as an already shipped Suricata configuration option.

Requests for [category rules #8593](https://redmine.openinfosecfoundation.org/issues/8593)
and [TCP fingerprints #8594](https://redmine.openinfosecfoundation.org/issues/8594)
are assigned to Karim Shammas and depend on #8077. Jason supported considering
the category request; Juliana explicitly said fingerprint inclusion still needed
team/use-case discussion. Assignment alone does not imply acceptance for release.

## What the public roadmap says specifically about Windows

**I found no public, targeted Windows embedding/DLL-plugin implementation plan,
owner, or delivery version in the searched sources.** This is a bounded search
finding, not proof that nobody has private plans or a working downstream patch.

Important distinctions:

1. A Windows Suricata executable working does not prove that the optional
   standalone shared library or dynamically loaded plugins work.
2. Generic libsuricata roadmap tickets do not explicitly commit to Windows SDK,
   MSVC ABI compatibility, DLL packaging, or Windows plugin CI.
3. Historical Windows work on Rust archive naming is internal build support,
   not proof of a standalone embedding API.
4. Historical plugin discussion explicitly records the gap: in
   [PR #5326](https://github.com/OISF/suricata/pull/5326) and
   [#5343](https://github.com/OISF/suricata/pull/5343), Jason abandoned a runtime
   symbol-lookup approach because it depended on plugin support on platforms
   “like Windows” where it had not been figured out. This is **2020 historical
   evidence**, not sufficient by itself to declare today's implementation
   impossible; current loader/build guards and local experiments are needed.
5. Windows also cannot inherit a Unix-socket-based control workflow merely by
   embedding the engine. The still-open #4704/#8095 transport-independent API
   work is relevant to this portability gap, but not a Windows commitment.

Consequently the responsible recommendation is: use a **separate experimental
Windows build**, pin the exact source/toolchain, first prove static embedding,
then independently assess shared-library construction, plugin loading, exported
symbols/import libraries, and callback/runtime ownership. A successful static
example is not evidence of DLL plugins; a plugin that loads but never invokes a
host callback is not an adequate functional test.

## Search scope and reproducibility

- Read repository agent conventions and the current local snapshot of 1,460
  public non-closed core Suricata issues, searching subjects, descriptions, and
  public journal notes for library/embedding/plugin terminology, then Windows,
  MinGW, UCRT, and DLL terms. This avoids restricting findings to issue titles.
- Queried the live public Redmine API across **all states**, including completed
  library/plugin issues and umbrella relations. Subject searches returned 19
  libsuricata and 49 plugin issues. Compound subject searches for “windows
  plugin” and “windows library” returned none. These counts describe those
  queries, not an exhaustive count of every related ticket.
- Read official forum searches and full discussions #6476, #6477, #6357;
  specifically checked Windows/plugin and Windows/libsuricata searches. Search
  hits about Windows TCP window sizes or inspecting Windows executables are not
  Windows-host plugin support evidence.
- Queried OISF GitHub pull requests, their live merge state, and maintainer
  replacement/batch comments. PRs share number space with Redmine only by
  coincidence: GitHub PR #8095 is unrelated to Redmine issue #8095.
- This is a read-only research report. No upstream issues/comments/PRs were
  created, and no build or source modification is part of this note.
