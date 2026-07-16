# Privacy

MiracleDeck is designed as a local-first macOS application.

- Provider credentials will be stored in macOS Keychain.
- Normalized snapshots and preferences stay on the user's Mac.
- The project does not require a MiracleDeck cloud account or backend.
- Provider requests are sent directly to the provider endpoint configured by
  the user.
- Prompts, model responses, API keys, cookies, and OAuth tokens must never be
  written to diagnostics or snapshot caches.
- Estimated local usage must be clearly distinguished from official billing
  or subscription data.

The current `0.0.x` engineering prototype uses mock data and does not connect
to external provider accounts.
