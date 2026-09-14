# Multiple platform connections

`CONNECTION-HTTP-001` exercises the public connection registry with two real
LINE adapters and real loopback HTTP delivery. Both connections receive the same
provider event ID, verify it with different signing secrets, preserve their own
connection identity, and send through different bearer tokens. A signature from
the first connection is rejected by the second. Unknown names and resolver
identity substitution fail closed in the unit contract.
