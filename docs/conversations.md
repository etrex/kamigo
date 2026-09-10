# Conversations and memberships

`require 'kamigo/conversations'` provides `Kamigo::Conversations::Conversation` and `Membership` Active Record models. Install the conversation migration together with the identity migration.

A conversation key is `(provider, scope, subject)`. Scope identifies the platform connection/namespace; never assume equal subjects across scopes identify the same room. A membership binds one independent principal to a conversation, with `member` or `admin` role and optional `left_at`. `memberships.active` excludes departed members.

The framework does not infer membership from a browser-supplied conversation ID, an ID token or knowledge of an invitation URL. The host must establish membership through authenticated platform evidence and apply departure events. Platform delivery delay or absent departure events limit observed membership freshness; hosts requiring current membership must query a platform capability before privileged access.

Products own authorization, role election timing, settings and retention. Conversation membership is not deleted when short-lived message contents expire. Hosts must preserve uniqueness and foreign keys when importing identities or merging accounts.
