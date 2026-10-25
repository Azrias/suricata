# Skipped-test report

Windows UCRT64 build: Suricata `e16087fab`; suricata-verify `06ccb56d`.

Of 2,955 integration tests, **292 were skipped**, 2,663 passed, and none failed in the full run. All 2,619 C unit tests ran and passed. Rust workspace tests were blocked at linking; they are not included in the skipped-test count.

## Groups

| Primary skip reason | Tests |
|---|---:|
| Windows limitation: shell check not supported on Windows | 101 |
| Windows limitation: "command" tests are not supported on Windows | 60 |
| Version requirements | 43 |
| Windows limitation: file-compare check not supported on Windows | 21 |
| Missing build feature: QA_SIMULATION | 13 |
| Missing build feature: MAGIC | 12 |
| Missing build feature: LIBNET1.1 | 10 |
| Operating-system requirement | 7 |
| Missing build feature: liblz4 | 6 |
| Unix-style prerequisite scripts fail under Windows cmd.exe | 5 |
| Feature-selection exclusions: JA3/JA4 are enabled | 2 |
| Intentionally disabled unit-test wrappers: DISABLED feature marker | 2 |
| Missing build feature: ASAN | 2 |
| Missing build feature: GeoIP2 | 2 |
| Windows limitation: test "setup" not supported on Windows | 2 |
| Windows limitation: uid based skip not supported on Windows | 2 |
| Missing build feature: DEBUG | 1 |
| Unix-socket helper not discovered in the original run | 1 |
| **Total** | **292** |

## Interpretation

Each test is counted once, under the first prerequisite that stopped it, or its first skipped-check reason when all its checks were skipped. Other unmet requirements may exist behind that first reason.

`DISABLED` intentionally excludes the `ut-complete` and `ut-leakcheck` wrappers; it is not an optional Suricata library to install. The regular C unit suite was already run separately. The JA3/JA4 'requires-off' cases are intentionally excluded because those features are enabled.

A Windows shell-check skip can occur after Suricata processed the PCAP; it means the assertion did not run, not necessarily that the engine did not run. The runner reports the whole test as skipped when none of its checks succeed.

The original run did not discover `suricatasc` because its default path omitted `.exe`. The verification script now supplies the correct path. This build still lacks UNIX_SOCKET support, so those cases remain ineligible.

Unix-style prerequisite scripts use `/dev/null` and can fail under Windows cmd.exe. These prerequisite failures do not demonstrate a Suricata feature failure.

**Historical reconstruction:** the original quiet log has five command-path warnings, and the five tests with prerequisite scripts have no execution artifacts. Those five are attributed to prerequisite failures by inference. A current audit reproduced 289 skips; three metadata prerequisite probes now succeed. Their original names/reasons were not individually logged, so this report does not present that attribution as directly recorded evidence.

## Every skipped test

### Windows limitation: shell check not supported on Windows (101)

- [app-layer-protocol-exact-http-invalid](suricata-verify/tests/app-layer-protocol-exact-http-invalid/test.yaml)
- [app-layer-protocol-list-prefilter-invalid](suricata-verify/tests/app-layer-protocol-list-prefilter-invalid/test.yaml)
- [app-layer-protocol-negated-duplicate-invalid](suricata-verify/tests/app-layer-protocol-negated-duplicate-invalid/test.yaml)
- [bug-3463](suricata-verify/tests/bug-3463/test.yaml)
- [bug-3490](suricata-verify/tests/bug-3490/test.yaml)
- [bug-3515](suricata-verify/tests/bug-3515/test.yaml)
- [bug-5220/bug-5220-1](suricata-verify/tests/bug-5220/bug-5220-1/test.yaml)
- [bug-5220/bug-5220-2](suricata-verify/tests/bug-5220/bug-5220-2/test.yaml)
- [bug-5220/bug-5220-3](suricata-verify/tests/bug-5220/bug-5220-3/test.yaml)
- [bug-5220/bug-5220-4](suricata-verify/tests/bug-5220/bug-5220-4/test.yaml)
- [bug-6278-1](suricata-verify/tests/bug-6278-1/test.yaml)
- [bug-6278-2](suricata-verify/tests/bug-6278-2/test.yaml)
- [bug-7389-01](suricata-verify/tests/bug-7389-01/test.yaml)
- [bug-7389-02](suricata-verify/tests/bug-7389-02/test.yaml)
- [bug-7549-01](suricata-verify/tests/bug-7549-01/test.yaml)
- [bug-7549-02](suricata-verify/tests/bug-7549-02/test.yaml)
- [bug-8845/bug-8845-02](suricata-verify/tests/bug-8845/bug-8845-02/test.yaml)
- [config-includes](suricata-verify/tests/config-includes/test.yaml)
- [config-includes-array](suricata-verify/tests/config-includes-array/test.yaml)
- [datajson/datajson-12-nonstring-md5](suricata-verify/tests/datajson/datajson-12-nonstring-md5/test.yaml)
- [datajson/datajson-13-nonstring-sha256](suricata-verify/tests/datajson/datajson-13-nonstring-sha256/test.yaml)
- [datajson/datajson-14-nonstring-ipv4](suricata-verify/tests/datajson/datajson-14-nonstring-ipv4/test.yaml)
- [datajson/datajson-15-nonstring-ipv6](suricata-verify/tests/datajson/datajson-15-nonstring-ipv6/test.yaml)
- [datarep-03-bad-reputation](suricata-verify/tests/datarep-03-bad-reputation/test.yaml)
- [datasets-06-state-long](suricata-verify/tests/datasets-06-state-long/test.yaml)
- [detect-bidir-impossible](suricata-verify/tests/detect-bidir-impossible/test.yaml)
- [detect-bsize-01](suricata-verify/tests/detect-bsize-01/test.yaml)
- [detect-bytejump-03](suricata-verify/tests/detect-bytejump-03/test.yaml)
- [detect-bytejump-07](suricata-verify/tests/detect-bytejump-07/test.yaml)
- [detect-bytemath-02](suricata-verify/tests/detect-bytemath-02/test.yaml)
- [detect-bytemath-06](suricata-verify/tests/detect-bytemath-06/test.yaml)
- [detect-bytetest-05](suricata-verify/tests/detect-bytetest-05/test.yaml)
- [detect-compress_whitespace-01](suricata-verify/tests/detect-compress_whitespace-01/test.yaml)
- [detect-content-strip-whitespace-01](suricata-verify/tests/detect-content-strip-whitespace-01/test.yaml)
- [detect-filestore-config-03](suricata-verify/tests/detect-filestore-config-03/test.yaml)
- [detect-filestore-config-04](suricata-verify/tests/detect-filestore-config-04/test.yaml)
- [detect-ftp/ftp-command-02](suricata-verify/tests/detect-ftp/ftp-command-02/test.yaml)
- [detect-ftp/ftp-mode-03](suricata-verify/tests/detect-ftp/ftp-mode-03/test.yaml)
- [detect-ftp/ftp-reply-received-03](suricata-verify/tests/detect-ftp/ftp-reply-received-03/test.yaml)
- [detect-ip_proto-01](suricata-verify/tests/detect-ip_proto-01/test.yaml)
- [detect-pcre-relative-invalid](suricata-verify/tests/detect-pcre-relative-invalid/test.yaml)
- [detect-pcrexform-02](suricata-verify/tests/detect-pcrexform-02/test.yaml)
- [detect-pcrexform-04](suricata-verify/tests/detect-pcrexform-04/test.yaml)
- [detect-strip_whitespace-01](suricata-verify/tests/detect-strip_whitespace-01/test.yaml)
- [detect-to_lowercase-02](suricata-verify/tests/detect-to_lowercase-02/test.yaml)
- [detect-to_uppercase-02](suricata-verify/tests/detect-to_uppercase-02/test.yaml)
- [file-force-hash-invalid](suricata-verify/tests/file-force-hash-invalid/test.yaml)
- [filestore-ftp-active-mode](suricata-verify/tests/filestore-ftp-active-mode/test.yaml)
- [filestore-ftp-passive-mode](suricata-verify/tests/filestore-ftp-passive-mode/test.yaml)
- [filestore-issue-5868](suricata-verify/tests/filestore-issue-5868/test.yaml)
- [firewall/engine-analysis-state-tables](suricata-verify/tests/firewall/engine-analysis-state-tables/test.yaml)
- [firewall/firewall-action-pass-requires-accept-policies-invalid](suricata-verify/tests/firewall/firewall-action-pass-requires-accept-policies-invalid/test.yaml)
- [firewall/firewall-action-pass-requires-accept-rule-invalid](suricata-verify/tests/firewall/firewall-action-pass-requires-accept-rule-invalid/test.yaml)
- [firewall/firewall-action-pass-requires-accept-valid](suricata-verify/tests/firewall/firewall-action-pass-requires-accept-valid/test.yaml)
- [firewall/firewall-action-scope-inherited-policies-invalid](suricata-verify/tests/firewall/firewall-action-scope-inherited-policies-invalid/test.yaml)
- [firewall/firewall-action-scope-inherited-rule-invalid](suricata-verify/tests/firewall/firewall-action-scope-inherited-rule-invalid/test.yaml)
- [firewall/firewall-action-scope-inherited-valid](suricata-verify/tests/firewall/firewall-action-scope-inherited-valid/test.yaml)
- [firewall/firewall-policy-config-action-invalid](suricata-verify/tests/firewall/firewall-policy-config-action-invalid/test.yaml)
- [firewall/firewall-pre-flow-policy-flow-scope-invalid](suricata-verify/tests/firewall/firewall-pre-flow-policy-flow-scope-invalid/test.yaml)
- [firewall/firewall-pre-flow-rule-scope-invalid](suricata-verify/tests/firewall/firewall-pre-flow-rule-scope-invalid/test.yaml)
- [firewall/ruletype-firewall-103-tls-upgrade-state-rename-rule](suricata-verify/tests/firewall/ruletype-firewall-103-tls-upgrade-state-rename-rule/test.yaml)
- [firewall/ruletype-firewall-104-tls-upgrade-legacy-config-keys](suricata-verify/tests/firewall/ruletype-firewall-104-tls-upgrade-legacy-config-keys/test.yaml)
- [firewall/ruletype-firewall-147-default-policy-scope-packet-hook](suricata-verify/tests/firewall/ruletype-firewall-147-default-policy-scope-packet-hook/test.yaml)
- [firewall/ruletype-firewall-148-default-policy-scope-app-hook](suricata-verify/tests/firewall/ruletype-firewall-148-default-policy-scope-app-hook/test.yaml)
- [firewall/ruletype-firewall-149-default-policy-scope-substate](suricata-verify/tests/firewall/ruletype-firewall-149-default-policy-scope-substate/test.yaml)
- [firewall/ruletype-firewall-154-firewall-policy-http2-substate](suricata-verify/tests/firewall/ruletype-firewall-154-firewall-policy-http2-substate/test.yaml)
- [firewall/ruletype-firewall-264-app-layer-state-beyond-end-rejected](suricata-verify/tests/firewall/ruletype-firewall-264-app-layer-state-beyond-end-rejected/test.yaml)
- [firewall/ruletype-firewall-265-app-layer-state-start-state-rejected](suricata-verify/tests/firewall/ruletype-firewall-265-app-layer-state-start-state-rejected/test.yaml)
- [firewall/ruletype-firewall-277-app-layer-state-beyond-end-tls-rejected](suricata-verify/tests/firewall/ruletype-firewall-277-app-layer-state-beyond-end-tls-rejected/test.yaml)
- [firewall/ruletype-firewall-278-app-layer-state-start-state-smtp-rejected](suricata-verify/tests/firewall/ruletype-firewall-278-app-layer-state-start-state-smtp-rejected/test.yaml)
- [firewall/ruletype-firewall-548-td-lt-hook-rejected](suricata-verify/tests/firewall/ruletype-firewall-548-td-lt-hook-rejected/test.yaml)
- [firewall/ruletype-firewall-549-config-kw-not-support-td](suricata-verify/tests/firewall/ruletype-firewall-549-config-kw-not-support-td/test.yaml)
- [firewall/ruletype-firewall-550-no-support-config-action](suricata-verify/tests/firewall/ruletype-firewall-550-no-support-config-action/test.yaml)
- [firewall/ruletype-firewall-90-ban-replace-keyword](suricata-verify/tests/firewall/ruletype-firewall-90-ban-replace-keyword/test.yaml)
- [firewall/ruletype-firewall-91-ban-replace-from-fw-mode](suricata-verify/tests/firewall/ruletype-firewall-91-ban-replace-from-fw-mode/test.yaml)
- [firewall/ruletype-firewall-92-ban-bypass-keyword](suricata-verify/tests/firewall/ruletype-firewall-92-ban-bypass-keyword/test.yaml)
- [ftp/ftp-invalid-config](suricata-verify/tests/ftp/ftp-invalid-config/test.yaml)
- [ja4-rules-invalid](suricata-verify/tests/ja4-rules-invalid/test.yaml)
- [list-frames](suricata-verify/tests/list-frames/test.yaml)
- [lua/lua-hashlib-output](suricata-verify/tests/lua/lua-hashlib-output/test.yaml)
- [lua/lua-transform-04](suricata-verify/tests/lua/lua-transform-04/test.yaml)
- [lua-output-dns](suricata-verify/tests/lua-output-dns/test.yaml)
- [lua-output-smtp](suricata-verify/tests/lua-output-smtp/test.yaml)
- [lua-output-stats](suricata-verify/tests/lua-output-stats/test.yaml)
- [mqtt-limit-log-fail](suricata-verify/tests/mqtt-limit-log-fail/test.yaml)
- [output-eve-anomaly-04](suricata-verify/tests/output-eve-anomaly-04/test.yaml)
- [output-pcap-log-conditional-noalert](suricata-verify/tests/output-pcap-log-conditional-noalert/test.yaml)
- [pcap-log-uncompressed-01](suricata-verify/tests/pcap-log-uncompressed-01/test.yaml)
- [pcap-log-uncompressed-02-multi](suricata-verify/tests/pcap-log-uncompressed-02-multi/test.yaml)
- [pcre-invalid-rule-01](suricata-verify/tests/pcre-invalid-rule-01/test.yaml)
- [reference-06](suricata-verify/tests/reference-06/test.yaml)
- [reference-08](suricata-verify/tests/reference-08/test.yaml)
- [rules/parenthesis](suricata-verify/tests/rules/parenthesis/test.yaml)
- [smb-version-keyword-invalid](suricata-verify/tests/smb-version-keyword-invalid/test.yaml)
- [smtp-raw-extraction](suricata-verify/tests/smtp-raw-extraction/test.yaml)
- [ssh-hassh-disabled](suricata-verify/tests/ssh-hassh-disabled/test.yaml)
- [ssh-lua-output](suricata-verify/tests/ssh-lua-output/test.yaml)
- [subslice/subslice-04](suricata-verify/tests/subslice/subslice-04/test.yaml)
- [test-unreachable-distance-1](suricata-verify/tests/test-unreachable-distance-1/test.yaml)
- [tls/tls-store-01](suricata-verify/tests/tls/tls-store-01/test.yaml)
- [tls/tls-store-02](suricata-verify/tests/tls/tls-store-02/test.yaml)

### Windows limitation: "command" tests are not supported on Windows (60)

- [bug-2190](suricata-verify/tests/bug-2190/test.yaml)
- [classification-config-validate-01](suricata-verify/tests/classification-config-validate-01/test.yaml)
- [classification-config-validate-02](suricata-verify/tests/classification-config-validate-02/test.yaml)
- [datasets-bug-5109](suricata-verify/tests/datasets-bug-5109/test.yaml)
- [detect-filestore-config-01](suricata-verify/tests/detect-filestore-config-01/test.yaml)
- [detect-filestore-config-02](suricata-verify/tests/detect-filestore-config-02/test.yaml)
- [iprep-02](suricata-verify/tests/iprep-02/test.yaml)
- [iprep-03-bug-6834](suricata-verify/tests/iprep-03-bug-6834/test.yaml)
- [iprep-04-bug-6834-any](suricata-verify/tests/iprep-04-bug-6834-any/test.yaml)
- [iprep-05-bug-6834-both](suricata-verify/tests/iprep-05-bug-6834-both/test.yaml)
- [iprep-06-bug-6834-dst](suricata-verify/tests/iprep-06-bug-6834-dst/test.yaml)
- [iprep-07-bug-6834-src-cidr](suricata-verify/tests/iprep-07-bug-6834-src-cidr/test.yaml)
- [iprep-08-bug-6834-any-cidr](suricata-verify/tests/iprep-08-bug-6834-any-cidr/test.yaml)
- [iprep-09-bug-6834-both-cidr](suricata-verify/tests/iprep-09-bug-6834-both-cidr/test.yaml)
- [iprep-10-bug-6834-dst-cidr](suricata-verify/tests/iprep-10-bug-6834-dst-cidr/test.yaml)
- [iprep-11-isset](suricata-verify/tests/iprep-11-isset/test.yaml)
- [issue-4280-iprep](suricata-verify/tests/issue-4280-iprep/test.yaml)
- [issue-4407](suricata-verify/tests/issue-4407/test.yaml)
- [pcap-file-stdin](suricata-verify/tests/pcap-file-stdin/test.yaml)
- [reference-config-validate-01](suricata-verify/tests/reference-config-validate-01/test.yaml)
- [reference-config-validate-02](suricata-verify/tests/reference-config-validate-02/test.yaml)
- [reputation-config/reputation-config-cr](suricata-verify/tests/reputation-config/reputation-config-cr/test.yaml)
- [reputation-config/reputation-config-cr-lf](suricata-verify/tests/reputation-config/reputation-config-cr-lf/test.yaml)
- [reputation-config/reputation-config-lf](suricata-verify/tests/reputation-config/reputation-config-lf/test.yaml)
- [runmode-error-5711](suricata-verify/tests/runmode-error-5711/test.yaml)
- [test-bad-byte-extract-rule-1](suricata-verify/tests/test-bad-byte-extract-rule-1/test.yaml)
- [test-bad-byte-extract-rule-2](suricata-verify/tests/test-bad-byte-extract-rule-2/test.yaml)
- [test-bad-content-dsize-rule-2](suricata-verify/tests/test-bad-content-dsize-rule-2/test.yaml)
- [test-bad-content-dsize-rule-3](suricata-verify/tests/test-bad-content-dsize-rule-3/test.yaml)
- [test-bad-content-quotes-rule-1](suricata-verify/tests/test-bad-content-quotes-rule-1/test.yaml)
- [test-bad-depth-depth-rule-1](suricata-verify/tests/test-bad-depth-depth-rule-1/test.yaml)
- [test-bad-depth-distance-rule-1](suricata-verify/tests/test-bad-depth-distance-rule-1/test.yaml)
- [test-bad-depth-distance-rule-2](suricata-verify/tests/test-bad-depth-distance-rule-2/test.yaml)
- [test-bad-depth-rule-1](suricata-verify/tests/test-bad-depth-rule-1/test.yaml)
- [test-bad-depth-within-rule-1](suricata-verify/tests/test-bad-depth-within-rule-1/test.yaml)
- [test-bad-depth-within-rule-2](suricata-verify/tests/test-bad-depth-within-rule-2/test.yaml)
- [test-bad-dsize-offset-rule-2](suricata-verify/tests/test-bad-dsize-offset-rule-2/test.yaml)
- [test-bad-dsize-range-offset-rule-2](suricata-verify/tests/test-bad-dsize-range-offset-rule-2/test.yaml)
- [test-bad-dsize-range-rule-2](suricata-verify/tests/test-bad-dsize-range-rule-2/test.yaml)
- [test-bad-hex-rule-1](suricata-verify/tests/test-bad-hex-rule-1/test.yaml)
- [test-bad-hex-rule-2](suricata-verify/tests/test-bad-hex-rule-2/test.yaml)
- [test-bad-hex-rule-3](suricata-verify/tests/test-bad-hex-rule-3/test.yaml)
- [test-bad-http-host-rule-1](suricata-verify/tests/test-bad-http-host-rule-1/test.yaml)
- [test-bad-http-host-rule-2](suricata-verify/tests/test-bad-http-host-rule-2/test.yaml)
- [test-bad-negate-fast-pattern-rule-1](suricata-verify/tests/test-bad-negate-fast-pattern-rule-1/test.yaml)
- [test-bad-offset-distance-rule-1](suricata-verify/tests/test-bad-offset-distance-rule-1/test.yaml)
- [test-bad-offset-offset-rule-1](suricata-verify/tests/test-bad-offset-offset-rule-1/test.yaml)
- [test-bad-offset-within-rule-1](suricata-verify/tests/test-bad-offset-within-rule-1/test.yaml)
- [test-bad-quotation-marks-rule-1](suricata-verify/tests/test-bad-quotation-marks-rule-1/test.yaml)
- [test-bad-relative-keyword-fast-pattern-rule-1](suricata-verify/tests/test-bad-relative-keyword-fast-pattern-rule-1/test.yaml)
- [test-bad-semicolon-rule-1](suricata-verify/tests/test-bad-semicolon-rule-1/test.yaml)
- [test-bad-semicolon-rule-2](suricata-verify/tests/test-bad-semicolon-rule-2/test.yaml)
- [test-bad-within-within-rule-1](suricata-verify/tests/test-bad-within-within-rule-1/test.yaml)
- [test-config-empty-rule-file](suricata-verify/tests/test-config-empty-rule-file/test.yaml)
- [test-content-limits-1](suricata-verify/tests/test-content-limits-1/test.yaml)
- [test-ruleparse-etopen-01](suricata-verify/tests/test-ruleparse-etopen-01/test.yaml)
- [threshold-config-validate-01](suricata-verify/tests/threshold-config-validate-01/test.yaml)
- [threshold-config-validate-02](suricata-verify/tests/threshold-config-validate-02/test.yaml)
- [udp-5379/udp-hlen-invalid-non-strict](suricata-verify/tests/udp-5379/udp-hlen-invalid-non-strict/test.yaml)
- [udp-5379/udp-hlen-invalid-strict](suricata-verify/tests/udp-5379/udp-hlen-invalid-strict/test.yaml)

### Version requirements (43)

- [bug-4903/bug-4903-04](suricata-verify/tests/bug-4903/bug-4903-04/test.yaml) — for version less than 9
- [bug-8845/bug-8845-03](suricata-verify/tests/bug-8845/bug-8845-03/test.yaml) — for version less than 9.0
- [detect-app-layer-state-01](suricata-verify/tests/detect-app-layer-state-01/test.yaml) — for version less than 9
- [firewall/firewall-arp-accept-false](suricata-verify/tests/firewall/firewall-arp-accept-false/test.yaml) — for version less than 9
- [firewall/firewall-arp-accept-true](suricata-verify/tests/firewall/firewall-arp-accept-true/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-03-ruleset-vs-ping](suricata-verify/tests/firewall/ruletype-firewall-03-ruleset-vs-ping/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-04-ruleset-vs-sni](suricata-verify/tests/firewall/ruletype-firewall-04-ruleset-vs-sni/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-05-ruleset-vs-sni](suricata-verify/tests/firewall/ruletype-firewall-05-ruleset-vs-sni/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-09-ruleset-default-app-policy](suricata-verify/tests/firewall/ruletype-firewall-09-ruleset-default-app-policy/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-10-ruleset-packet-drop-vs-app](suricata-verify/tests/firewall/ruletype-firewall-10-ruleset-packet-drop-vs-app/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-100-fw-accept-flow-td-drop-noalert](suricata-verify/tests/firewall/ruletype-firewall-100-fw-accept-flow-td-drop-noalert/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-101-fw-accept-flow-td-pkt-drop-noalert](suricata-verify/tests/firewall/ruletype-firewall-101-fw-accept-flow-td-pkt-drop-noalert/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-102-fw-accept-flow-td-pkt-drop](suricata-verify/tests/firewall/ruletype-firewall-102-fw-accept-flow-td-pkt-drop/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-11-ruleset-pass-vs-fw](suricata-verify/tests/firewall/ruletype-firewall-11-ruleset-pass-vs-fw/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-13-ruleset-accept-flowbit](suricata-verify/tests/firewall/ruletype-firewall-13-ruleset-accept-flowbit/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-14-ruleset-pass-vs-fw](suricata-verify/tests/firewall/ruletype-firewall-14-ruleset-pass-vs-fw/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-15-state-keyword](suricata-verify/tests/firewall/ruletype-firewall-15-state-keyword/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-30-fw-accept-td-drop](suricata-verify/tests/firewall/ruletype-firewall-30-fw-accept-td-drop/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-33-ssh](suricata-verify/tests/firewall/ruletype-firewall-33-ssh/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-34-ssh-sw](suricata-verify/tests/firewall/ruletype-firewall-34-ssh-sw/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-35-ssh-sw](suricata-verify/tests/firewall/ruletype-firewall-35-ssh-sw/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-37-minimal-bad](suricata-verify/tests/firewall/ruletype-firewall-37-minimal-bad/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-43-tls-cert-chain](suricata-verify/tests/firewall/ruletype-firewall-43-tls-cert-chain/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-44-yaml-config-only](suricata-verify/tests/firewall/ruletype-firewall-44-yaml-config-only/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-49-reject-app](suricata-verify/tests/firewall/ruletype-firewall-49-reject-app/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-51-tls-cert-chain](suricata-verify/tests/firewall/ruletype-firewall-51-tls-cert-chain/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-59-tls-default-policy](suricata-verify/tests/firewall/ruletype-firewall-59-tls-default-policy/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-68-config-default-policy-tls](suricata-verify/tests/firewall/ruletype-firewall-68-config-default-policy-tls/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-69-config-default-policy-tls-accept](suricata-verify/tests/firewall/ruletype-firewall-69-config-default-policy-tls-accept/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-71-reject-app-default-policy](suricata-verify/tests/firewall/ruletype-firewall-71-reject-app-default-policy/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-81-ruleset-default-packet-policy-accept-hook-all](suricata-verify/tests/firewall/ruletype-firewall-81-ruleset-default-packet-policy-accept-hook-all/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-82-ruleset-default-app-policy-accept-flow](suricata-verify/tests/firewall/ruletype-firewall-82-ruleset-default-app-policy-accept-flow/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-89-lt-sni](suricata-verify/tests/firewall/ruletype-firewall-89-lt-sni/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-90-lt-sni-mix](suricata-verify/tests/firewall/ruletype-firewall-90-lt-sni-mix/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-95-ruleset-default-packet-policy-accept-hook-alert](suricata-verify/tests/firewall/ruletype-firewall-95-ruleset-default-packet-policy-accept-hook-alert/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-97-fw-accept-flow-td-drop](suricata-verify/tests/firewall/ruletype-firewall-97-fw-accept-flow-td-drop/test.yaml) — for version less than 9
- [firewall/ruletype-firewall-98-fw-accept-pass-flow-td-drop](suricata-verify/tests/firewall/ruletype-firewall-98-fw-accept-pass-flow-td-drop/test.yaml) — for version less than 9
- [flowbits-toggle-pre-9](suricata-verify/tests/flowbits-toggle-pre-9/test.yaml) — for version less than 9
- [pgsql/pgsql-80x-default-notice](suricata-verify/tests/pgsql/pgsql-80x-default-notice/test.yaml) — for version less than 9
- [rule-hooks/tls-handshake-01-ips-sni](suricata-verify/tests/rule-hooks/tls-handshake-01-ips-sni/test.yaml) — for version less than 9
- [rule-hooks/tls-handshake-02-ips-sni-drop](suricata-verify/tests/rule-hooks/tls-handshake-02-ips-sni-drop/test.yaml) — for version less than 9
- [ssh-lua-hassh](suricata-verify/tests/ssh-lua-hassh/test.yaml) — for version less than 9
- [ssh-lua-rules](suricata-verify/tests/ssh-lua-rules/test.yaml) — for version less than 9

### Windows limitation: file-compare check not supported on Windows (21)

- [compress_ipv6-03](suricata-verify/tests/compress_ipv6-03/test.yaml)
- [datasets-01](suricata-verify/tests/datasets-01/test.yaml)
- [datasets-05-state](suricata-verify/tests/datasets-05-state/test.yaml)
- [datasets-07-state-ip](suricata-verify/tests/datasets-07-state-ip/test.yaml)
- [datasets-08-state-ipv6](suricata-verify/tests/datasets-08-state-ipv6/test.yaml)
- [datasets-11-longstring](suricata-verify/tests/datasets-11-longstring/test.yaml)
- [datasets-pcrexform](suricata-verify/tests/datasets-pcrexform/test.yaml)
- [lua/lua-ntp-output](suricata-verify/tests/lua/lua-ntp-output/test.yaml)
- [lua/lua-tlslib-01](suricata-verify/tests/lua/lua-tlslib-01/test.yaml)
- [lua-flowstats](suricata-verify/tests/lua-flowstats/test.yaml)
- [lua-flowtuple](suricata-verify/tests/lua-flowtuple/test.yaml)
- [lua-output-http](suricata-verify/tests/lua-output-http/test.yaml)
- [lua-output-http-02](suricata-verify/tests/lua-output-http-02/test.yaml)
- [lua-output-http-03](suricata-verify/tests/lua-output-http-03/test.yaml)
- [lua-output-streaming](suricata-verify/tests/lua-output-streaming/test.yaml)
- [lua-scfileinfo](suricata-verify/tests/lua-scfileinfo/test.yaml)
- [lua-scpackettuple](suricata-verify/tests/lua-scpackettuple/test.yaml)
- [output-pcap-log](suricata-verify/tests/output-pcap-log/test.yaml)
- [output-pcap-log-conditional-alert](suricata-verify/tests/output-pcap-log-conditional-alert/test.yaml)
- [output-pcap-log-conditional-tag-alert](suricata-verify/tests/output-pcap-log-conditional-tag-alert/test.yaml)
- [output-tcp-data](suricata-verify/tests/output-tcp-data/test.yaml)

### Missing build feature: QA_SIMULATION (13)

- [bug-6149-exception-policy-auto-ips](suricata-verify/tests/bug-6149-exception-policy-auto-ips/test.yaml)
- [exception-policy-applayer-01](suricata-verify/tests/exception-policy-applayer-01/test.yaml)
- [exception-policy-applayer-02](suricata-verify/tests/exception-policy-applayer-02/test.yaml)
- [exception-policy-applayer-03](suricata-verify/tests/exception-policy-applayer-03/test.yaml)
- [exception-policy-default-01](suricata-verify/tests/exception-policy-default-01/test.yaml)
- [exception-policy-defrag-01](suricata-verify/tests/exception-policy-defrag-01/test.yaml)
- [exception-policy-simulated-flow-memcap](suricata-verify/tests/exception-policy-simulated-flow-memcap/test.yaml)
- [exception-policy-stream-reassembly-memcap-01](suricata-verify/tests/exception-policy-stream-reassembly-memcap-01/test.yaml)
- [exception-policy-stream-reassembly-memcap-02](suricata-verify/tests/exception-policy-stream-reassembly-memcap-02/test.yaml)
- [exception-policy-stream-reassembly-memcap-03](suricata-verify/tests/exception-policy-stream-reassembly-memcap-03/test.yaml)
- [exception-policy-stream-reassembly-memcap-05](suricata-verify/tests/exception-policy-stream-reassembly-memcap-05/test.yaml)
- [exception-policy-stream-reassembly-memcap-06](suricata-verify/tests/exception-policy-stream-reassembly-memcap-06/test.yaml)
- [exception-policy-stream-ssn-memcap-01](suricata-verify/tests/exception-policy-stream-ssn-memcap-01/test.yaml)

### Missing build feature: MAGIC (12)

- [filemagic-01](suricata-verify/tests/filemagic-01/test.yaml)
- [filemagic-flowbits](suricata-verify/tests/filemagic-flowbits/test.yaml)
- [filemagic-flowbits-02](suricata-verify/tests/filemagic-flowbits-02/test.yaml)
- [filemagic-flowbits-03](suricata-verify/tests/filemagic-flowbits-03/test.yaml)
- [filestore-alert-log](suricata-verify/tests/filestore-alert-log/test.yaml)
- [filestore-filecontainer-http](suricata-verify/tests/filestore-filecontainer-http/test.yaml)
- [filestore-filecontainer-smb](suricata-verify/tests/filestore-filecontainer-smb/test.yaml)
- [filestore-filecontainer-smb1-data-offset](suricata-verify/tests/filestore-filecontainer-smb1-data-offset/test.yaml)
- [filestore-filecontainer-smb1-padding](suricata-verify/tests/filestore-filecontainer-smb1-padding/test.yaml)
- [firewall/ruletype-firewall-246-lte-file-keywords-segmented](suricata-verify/tests/firewall/ruletype-firewall-246-lte-file-keywords-segmented/test.yaml)
- [issue-3703](suricata-verify/tests/issue-3703/test.yaml)
- [rules/filemagic](suricata-verify/tests/rules/filemagic/test.yaml)

### Missing build feature: LIBNET1.1 (10)

- [bug-4394-pdonly-drop](suricata-verify/tests/bug-4394-pdonly-drop/test.yaml)
- [bug-5464-verdict-01](suricata-verify/tests/bug-5464-verdict-01/test.yaml)
- [bug-5464-verdict-03](suricata-verify/tests/bug-5464-verdict-03/test.yaml)
- [bug-5464-verdict-06](suricata-verify/tests/bug-5464-verdict-06/test.yaml)
- [bug-5464-verdict-07](suricata-verify/tests/bug-5464-verdict-07/test.yaml)
- [bug-7199](suricata-verify/tests/bug-7199/test.yaml)
- [firewall/ruletype-firewall-142-default-policy-packet-precedence](suricata-verify/tests/firewall/ruletype-firewall-142-default-policy-packet-precedence/test.yaml)
- [firewall/ruletype-firewall-49-reject-app-tls-states](suricata-verify/tests/firewall/ruletype-firewall-49-reject-app-tls-states/test.yaml)
- [firewall/ruletype-firewall-71-reject-app-default-policy-tls-states](suricata-verify/tests/firewall/ruletype-firewall-71-reject-app-default-policy-tls-states/test.yaml)
- [firewall/ruletype-firewall-77-ruleset-default-packet-policy](suricata-verify/tests/firewall/ruletype-firewall-77-ruleset-default-packet-policy/test.yaml)

### Operating-system requirement (7)

- [datasets/datasets-absolute-allowed](suricata-verify/tests/datasets/datasets-absolute-allowed/test.yaml) — sys.platform != "win32"
- [datasets/datasets-load-save-absolute](suricata-verify/tests/datasets/datasets-load-save-absolute/test.yaml) — sys.platform != "win32"
- [datasets/datasets-parent-path](suricata-verify/tests/datasets/datasets-parent-path/test.yaml) — sys.platform != "win32"
- [datasets-memcap-02](suricata-verify/tests/datasets-memcap-02/test.yaml) — linux
- [filestore-fd-exhaustion](suricata-verify/tests/filestore-fd-exhaustion/test.yaml) — linux
- [list-keywords-json](suricata-verify/tests/list-keywords-json/test.yaml) — sys.platform != "win32"
- [security-8550](suricata-verify/tests/security-8550/test.yaml) — linux

### Missing build feature: liblz4 (6)

- [pcap-log-lz4-01](suricata-verify/tests/pcap-log-lz4-01/test.yaml)
- [pcap-log-lz4-02-multi](suricata-verify/tests/pcap-log-lz4-02-multi/test.yaml)
- [pcap-log-lz4-03-multi-ring](suricata-verify/tests/pcap-log-lz4-03-multi-ring/test.yaml)
- [pcap-log-lz4-04-multi-ring-profile](suricata-verify/tests/pcap-log-lz4-04-multi-ring-profile/test.yaml)
- [pcap-log-lz4-05-tunnel](suricata-verify/tests/pcap-log-lz4-05-tunnel/test.yaml)
- [pcap-log-lz4-write](suricata-verify/tests/pcap-log-lz4-write/test.yaml)

### Unix-style prerequisite scripts fail under Windows cmd.exe (5)

- [eve-alert-metadata-defaults](suricata-verify/tests/eve-alert-metadata-defaults/test.yaml)
- [eve-alert-metadata-enable-rule](suricata-verify/tests/eve-alert-metadata-enable-rule/test.yaml)
- [eve-alert-metadata-off](suricata-verify/tests/eve-alert-metadata-off/test.yaml)
- [ipopts-esec](suricata-verify/tests/ipopts-esec/test.yaml)
- [tls/tls-ja3s-requires](suricata-verify/tests/tls/tls-ja3s-requires/test.yaml)

### Feature-selection exclusions: JA3/JA4 are enabled (2)

- [ja4-rules-requires-off](suricata-verify/tests/ja4-rules-requires-off/test.yaml) — not for feature HAVE_JA4
- [tls/tls-ja3s-requires-off](suricata-verify/tests/tls/tls-ja3s-requires-off/test.yaml) — not for feature HAVE_JA3

### Intentionally disabled unit-test wrappers: DISABLED feature marker (2)

- [ut-complete](suricata-verify/tests/ut-complete/test.yaml)
- [ut-leakcheck](suricata-verify/tests/ut-leakcheck/test.yaml)

### Missing build feature: ASAN (2)

- [transform-dotprefix-uaf-8537](suricata-verify/tests/transform-dotprefix-uaf-8537/test.yaml)
- [transform-gunzip-uaf-8536](suricata-verify/tests/transform-gunzip-uaf-8536/test.yaml)

### Missing build feature: GeoIP2 (2)

- [geoip](suricata-verify/tests/geoip/test.yaml)
- [issues/bug-8333-geoip](suricata-verify/tests/issues/bug-8333-geoip/test.yaml)

### Windows limitation: test "setup" not supported on Windows (2)

- [pcap-file-delete-non-alerts-only-no-alerts](suricata-verify/tests/pcap-file-delete-non-alerts-only-no-alerts/test.yaml)
- [pcap-file-delete-non-alerts-only-pseudo-no-alert](suricata-verify/tests/pcap-file-delete-non-alerts-only-pseudo-no-alert/test.yaml)

### Windows limitation: uid based skip not supported on Windows (2)

- [bug-5198](suricata-verify/tests/bug-5198/test.yaml)
- [filestore-v2.3-fserror](suricata-verify/tests/filestore-v2.3-fserror/test.yaml)

### Missing build feature: DEBUG (1)

- [bug-7389-03](suricata-verify/tests/bug-7389-03/test.yaml)

### Unix-socket helper not discovered in the original run (1)

- [unix-socket/hostbit-add-ip6](suricata-verify/tests/unix-socket/hostbit-add-ip6/test.yaml)

## Passed tests with skipped assertions

Another **47 passed tests** contain **60 skipped checks**. They are excluded from the 292 whole-test skips because other checks passed.

- [alert-testmyids](suricata-verify/tests/alert-testmyids/test.yaml) — #3 shell: shell check not supported on Windows
- [alert-testmyids-frames](suricata-verify/tests/alert-testmyids-frames/test.yaml) — #2 shell: shell check not supported on Windows
- [alert-testmyids-midstream3](suricata-verify/tests/alert-testmyids-midstream3/test.yaml) — #4 shell: shell check not supported on Windows
- [alert-testmyids-midstream5](suricata-verify/tests/alert-testmyids-midstream5/test.yaml) — #4 shell: shell check not supported on Windows
- [alert-testmyids-not-established](suricata-verify/tests/alert-testmyids-not-established/test.yaml) — #1 shell: shell check not supported on Windows
- [bug-8205/bug-8205-g0-t0-u1](suricata-verify/tests/bug-8205/bug-8205-g0-t0-u1/test.yaml) — #3 shell: shell check not supported on Windows
- [bug-8205/bug-8205-g0-t1-u0](suricata-verify/tests/bug-8205/bug-8205-g0-t1-u0/test.yaml) — #3 shell: shell check not supported on Windows
- [bug-8205/bug-8205-g0-t1-u1](suricata-verify/tests/bug-8205/bug-8205-g0-t1-u1/test.yaml) — #3 shell: shell check not supported on Windows; #4 shell: shell check not supported on Windows
- [bug-8205/bug-8205-g1-t0-u0](suricata-verify/tests/bug-8205/bug-8205-g1-t0-u0/test.yaml) — #3 shell: shell check not supported on Windows; #4 shell: shell check not supported on Windows
- [bug-8205/bug-8205-g1-t0-u1](suricata-verify/tests/bug-8205/bug-8205-g1-t0-u1/test.yaml) — #3 shell: shell check not supported on Windows
- [bug-8205/bug-8205-g1-t1-u0](suricata-verify/tests/bug-8205/bug-8205-g1-t1-u0/test.yaml) — #3 shell: shell check not supported on Windows
- [bug-8845/bug-8845-01](suricata-verify/tests/bug-8845/bug-8845-01/test.yaml) — #1 shell: shell check not supported on Windows
- [bug-8861-eve-threaded-flow](suricata-verify/tests/bug-8861-eve-threaded-flow/test.yaml) — #1 shell: shell check not supported on Windows; #2 shell: shell check not supported on Windows; #3 shell: shell check not supported on Windows
- [datasets-10-unset](suricata-verify/tests/datasets-10-unset/test.yaml) — #3 file-compare: file-compare check not supported on Windows
- [detect-pcre-relative-bytejump](suricata-verify/tests/detect-pcre-relative-bytejump/test.yaml) — #6 shell: shell check not supported on Windows
- [engine-state/detect-engine-state-03](suricata-verify/tests/engine-state/detect-engine-state-03/test.yaml) — #5 shell: shell check not supported on Windows
- [engine-state/detect-engine-state-04](suricata-verify/tests/engine-state/detect-engine-state-04/test.yaml) — #4 shell: shell check not supported on Windows
- [engine-state/detect-engine-state-05](suricata-verify/tests/engine-state/detect-engine-state-05/test.yaml) — #3 shell: shell check not supported on Windows; #6 shell: shell check not supported on Windows
- [filestore-v2.1-forced](suricata-verify/tests/filestore-v2.1-forced/test.yaml) — #1 shell: shell check not supported on Windows
- [filestore-v2.2-forced-with-open-files](suricata-verify/tests/filestore-v2.2-forced-with-open-files/test.yaml) — #1 shell: shell check not supported on Windows
- [filestore-v2.8-stream-depth](suricata-verify/tests/filestore-v2.8-stream-depth/test.yaml) — #1 shell: shell check not supported on Windows
- [firewall/engine-analysis-default-policy](suricata-verify/tests/firewall/engine-analysis-default-policy/test.yaml) — #2 filter: for version less than 9; #5 filter: for version less than 9
- [firewall/firewall-packet-filter-policy-drop-flow-flush](suricata-verify/tests/firewall/firewall-packet-filter-policy-drop-flow-flush/test.yaml) — #2 filter: for version less than 9
- [firewall/ruletype-firewall-141-ban-bypass-keyword-firewall-rule](suricata-verify/tests/firewall/ruletype-firewall-141-ban-bypass-keyword-firewall-rule/test.yaml) — #5 shell: shell check not supported on Windows
- [firewall/tcp-session-decode-malformed-ipv4](suricata-verify/tests/firewall/tcp-session-decode-malformed-ipv4/test.yaml) — #7 shell: shell check not supported on Windows
- [http2-files](suricata-verify/tests/http2-files/test.yaml) — #1 file-compare: file-compare check not supported on Windows
- [http2-files-6](suricata-verify/tests/http2-files-6/test.yaml) — #1 file-compare: file-compare check not supported on Windows
- [http2-keywords2](suricata-verify/tests/http2-keywords2/test.yaml) — #11 filter: for version less than 9; #15 filter: for version less than 9; #17 filter: for version less than 9
- [ikev1](suricata-verify/tests/ikev1/test.yaml) — #2 filter: for version less than 9.0.0
- [ikev1-duplicate-proposals](suricata-verify/tests/ikev1-duplicate-proposals/test.yaml) — #2 filter: for version less than 9.0.0
- [ja4-rules-requires](suricata-verify/tests/ja4-rules-requires/test.yaml) — #2 shell: shell check not supported on Windows
- [lua/lua-base64](suricata-verify/tests/lua/lua-base64/test.yaml) — #2 shell: shell check not supported on Windows
- [lua/lua-fastlog](suricata-verify/tests/lua/lua-fastlog/test.yaml) — #2 file-compare: file-compare check not supported on Windows
- [lua-flowfunctions](suricata-verify/tests/lua-flowfunctions/test.yaml) — #1 file-compare: file-compare check not supported on Windows
- [lua-scrule-ids](suricata-verify/tests/lua-scrule-ids/test.yaml) — #2 file-compare: file-compare check not supported on Windows
- [output-pcap-log-filter](suricata-verify/tests/output-pcap-log-filter/test.yaml) — #1 file-compare: file-compare check not supported on Windows
- [pcap-file-delete-non-alerts-only-flow-timeout-alert](suricata-verify/tests/pcap-file-delete-non-alerts-only-flow-timeout-alert/test.yaml) — #2 shell: shell check not supported on Windows
- [pcap-file-delete-non-alerts-only-stream-alerts](suricata-verify/tests/pcap-file-delete-non-alerts-only-stream-alerts/test.yaml) — #2 shell: shell check not supported on Windows
- [pcap-file-delete-non-alerts-only-with-alerts](suricata-verify/tests/pcap-file-delete-non-alerts-only-with-alerts/test.yaml) — #2 shell: shell check not supported on Windows
- [pcap-log-uncompressed-03-multi-bpf](suricata-verify/tests/pcap-log-uncompressed-03-multi-bpf/test.yaml) — #2 shell: shell check not supported on Windows
- [requires-ok](suricata-verify/tests/requires-ok/test.yaml) — #3 filter: for version less than 9; #5 filter: for version less than 9
- [rules/http-request-body](suricata-verify/tests/rules/http-request-body/test.yaml) — #3 filter: for version less than 9
- [rules/http-response-body](suricata-verify/tests/rules/http-response-body/test.yaml) — #3 filter: for version less than 9
- [rules/icmp_id](suricata-verify/tests/rules/icmp_id/test.yaml) — #1 filter: for version less than 9.0
- [rules/tcp-seq-keyword](suricata-verify/tests/rules/tcp-seq-keyword/test.yaml) — #1 filter: for version less than 9.0; #2 filter: for version less than 9.0
- [rules/tcp_ack](suricata-verify/tests/rules/tcp_ack/test.yaml) — #1 filter: for version less than 9.0; #2 filter: for version less than 9.0; #3 filter: for version less than 9.0
- [rules/tcp_window](suricata-verify/tests/rules/tcp_window/test.yaml) — #1 filter: for version less than 9.0; #2 filter: for version less than 9.0

## Method and evidence

The earlier quiet run retained aggregate totals, not individual skip reasons. This report reconstructs decisions using the pinned runner's requirement and skip functions, the same native executable and installed tools, and original helper-discovery behavior. It reads current test configurations and performs read-only config dumps; prerequisite shell probes are not executed. It does not replay PCAPs or modify test artifacts. Check eligibility is audited without rerunning assertions; pass/fail results come from the full-run summary.

The reconstructed whole-test total matches the recorded **292 skips**, with the historical inference above explicitly retained.

- [Original full-run output](.build-tmp/full-suite-run.log)
- [Machine-readable audit](.build-tmp/skipped-tests.json)
- [Pinned runner](suricata-verify/run.py)
- [Shared requirement and check implementations](suricata-verify/lib/common.py)
