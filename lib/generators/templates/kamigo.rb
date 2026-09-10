# Kamigo 1.0: trusted handlers are registered explicitly, never inferred from user paths.
# Instantiate a Renderer with Rails.root.join("app/views/chat"), then register
# controller actions using Kamigo::Controller.action and a mandatory policy.
# See docs/1.0.md for a complete ingress example. No public webhook is enabled
# until a platform verifier, context resolver and policy have been configured.
