# WinDivert packet batching: upstream plans

Research date: 2026-10-25. Scope: public Suricata plans and current integration;
no implementation or performance testing.

## Finding

**No documented Suricata plan, dedicated ticket, or pull request for WinDivert
packet batching was found.** That is a search result, not proof that developers
have no private or unannounced plans. No owner, target release, or delivery date
for this optimization was identified.

WinDivert itself supports batched packet receive/reinjection through
`WinDivertRecvEx()` and `WinDivertSendEx()`. The official documentation describes
these batch operations and their address arrays; this API capability is distinct
from whether an application uses it.
Source: [WinDivert documentation](https://github.com/basil00/WinDivert/wiki/WinDivert-Documentation).

## What Suricata has actually done

- [#8138: WinDivert 2 support](https://redmine.openinfosecfoundation.org/issues/8138)
  records the API upgrade. It is not a batching commitment.
- The inspected Suricata revision, `e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4`,
  still receives one packet using `WinDivertRecv()` and reinjects an accepted
  packet using `WinDivertSend()`. A packet with a drop action is not reinjected.
  See [receive code](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/src/source-windivert.c#L458)
  and [verdict/send code](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/src/source-windivert.c#L780).
  A live fetch of upstream `main` on the research date still showed the same
  single-packet API calls, with no `RecvEx` / `SendEx` use.
- [#7764: tracking Windows support](https://redmine.openinfosecfoundation.org/issues/7764)
  contains no explicit batching proposal in its description or public history.
- [#3698: maximum filter length](https://redmine.openinfosecfoundation.org/issues/3698)
  discusses filter limits and the WinDivert 2 API migration, not batch I/O.

## Searches and limits

- Scanned the local snapshot of **1,460 public non-closed Suricata issues**,
  including descriptions and public journal notes, refreshed on 2026-10-25.
  Searched for WinDivert, `RecvEx`, `SendEx`, and batch-related issue titles;
  ignored incidental `WinDivert enabled: no` build-information dumps.
- Live Redmine searches across **all statuses** found eight WinDivert-titled
  tickets: #8138, #8137, #6052, #5629, #5628, #5627, #3698, and #2455.
  Their descriptions and public journals contained no identified batching plan.
  This title-based search does not exhaust every closed issue's comment text.
- GitHub issue/PR searches across all states found no `WinDivertRecvEx` or
  `WinDivertSendEx` results. Searching `windivert batch` found only
  [PR #16371](https://github.com/OISF/suricata/pull/16371), an unrelated C include
  cleanup whose wording says “Next batch”.
- Generic Redmine batch-title results concern Redis or offline PCAP processing.
  For example, [#2221](https://redmine.openinfosecfoundation.org/issues/2221)
  concerns Unix-socket scheduling between PCAP files, not WinDivert packets.
- Public web searches of the official forum, Redmine, and GitHub found no direct
  batching proposal. Search indexing and non-public discussions remain limits.
- Direct forum search for `windivert batch` returned one
  [configuration paste](https://forum.suricata.io/t/testing-ips-fails/2857/24):
  its `batchcount` setting belongs to NFQ, while WinDivert appears only in
  `--build-info` output as disabled. Searches for `WinDivertRecvEx` and
  `WinDivertSendEx` returned no matching posts. This was not a batching plan.

## Practical interpretation

Treat batching as a **potential new optimization**, not scheduled upstream work.
It would require more than upgrading the WinDivert library: receive-buffer
ownership, per-packet addresses and inspection verdicts, drop handling, accepted
packet reinjection, and latency/error behavior need a deliberate design and
correctness tests. Any throughput improvement must be measured, not assumed.

An upstream question referencing #8138 and #7764 would be the appropriate way to
ask maintainers whether an unpublished design or preferred approach exists.
No issue, forum post, or implementation was created during this research.
