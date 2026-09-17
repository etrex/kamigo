# Telegram safe rejection diagnostics

TGD-1 (2026-09-17): ran `bundle exec ruby script/acceptance/telegram_rejection_diagnostics.rb` against a real loopback HTTP endpoint using the public transport API. Eleven independent response cases returned allowlisted categories only: chat not found, migration with negative integer target, blocked, removed membership, too long, invalid entities, slow-mode 429, general 429, invalid JSON, over-limit body, invalid migration metadata. Retry-after values 12 and 792 remained available. Token/user-text sentinels did not appear in exceptions/output. No production messages sent and no migration performed.

`test/v1/telegram_rejection_diagnostics_acceptance_test.rb` replays exactly TGD-1. Metadata boundary tests separately protect public exception attributes. Provider descriptions are discarded; no raw text is logged. Invalid diagnostic bodies preserve ordinary 4xx rejection semantics; malformed 429 remains uncertain as before.
