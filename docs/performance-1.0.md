# Local performance evidence (2026-09-09)

Router-only benchmark: 1,000 exact commands, lookup of last command, 20,000
resolutions with one prebuilt event/context, Ruby 4.0.6 on this development machine.
Linear route traversal: 1.067311 seconds / 20,011 allocations.
Indexed command/event candidates with ordered predicate checks: 0.002030 seconds /
11 allocations. Declaration-order behavior has regression coverage.
Reproduce current implementation with `bundle exec ruby benchmark/router.rb`.
This compares two implementations within this rewrite, not old released Kamigo.
It does not measure database, templates, HTTP, concurrency or end-to-end capacity;
it is not evidence of supporting one million daily active users.

Other corrected issues: shared handler state replaced with factories; Kamiflex class
mutation replaced by per-call builders; arbitrary browser-selected route dispatch
removed from Kamiliff. Tests cover isolation and authorization boundaries.

The host acceptance project separately measures representative keyword data,
concurrent PostgreSQL message writes, p50/p95/p99 latency, storage growth and
outbox delivery/recovery. Those product benchmarks stay in the host because this
gem does not own its keyword schema or workload. RSS/GC and target-cloud load must
be measured again on the selected deployment size before production cutover.
