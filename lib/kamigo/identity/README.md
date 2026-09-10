# Identity persistence contract

Install the supplied migration in the host application. All identity and business
records must share a PostgreSQL database when atomically changing both domains.
The SQLite tests exercise functional contracts only, not PostgreSQL concurrency.

`Principal#public_id` is the stable application identity. Platform subjects are
opaque, case-sensitive keys scoped by both provider and namespace. A LINE
namespace is its provider; other adapters choose the documented issuer/tenant
scope. User-supplied display names, email claims, and a bare platform user ID
must never be used to link identities.

`Service.new(verifier:, recovery_available:)` has these operations:

* `create_principal!`: creates an independent principal; it does not create login credentials.
* `resolve(provider:, scope:, subject:)`: identity lookup, **not authentication**.
* `attach!(principal:, credentials:)`: invokes a trusted verifier, then atomically
  claims the external account. An existing owner causes `AlreadyLinked`, never a merge.
* `detach!(principal:, external_account:)`: removes the link only if another
  login-capable account or independent recovery method exists.

The host must authenticate the current principal recently and enforce CSRF,
nonce/replay protection, and link-intent confirmation before calling `attach!`.
The verifier is trusted dependency injection, not an endpoint-selectable class.
It must validate actual platform credentials and return `VerifiedIdentity` only
on success. The type is not a cryptographic proof and must never be deserialized
from client JSON. Invalid verification should raise `VerificationFailed`.

The recovery predicate defaults to false. The host's independent credential
creation/removal must use the same principal row lock; its predicate executes
inside the detach transaction. In addition, revoke any sessions or delegated
credentials derived from the removed account in the host's encompassing database
transaction. This module does not implement sessions, passkeys, OAuth challenges,
account merging, exports, or a recovery UI; these are required before claiming a
complete user-sovereignty login product.

All link mutations must use this service (or acquire the same locks and enforce
its rules). Direct ActiveRecord updates are trusted internal operations. Model
presence validations and database uniqueness/check constraints do not replace
caller authorization. PostgreSQL uniqueness is the final arbiter for concurrent
claims. A losing claim receives `AlreadyLinked` and must authenticate again.
