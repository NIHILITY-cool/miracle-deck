# Contributing

Token Monitor is in its engineering-prototype phase. Before submitting a
change:

1. Keep provider-specific parsing outside the App and UI targets.
2. Never commit real credentials or account responses.
3. Add fixtures and tests for provider response changes.
4. Preserve the distinction between official, compatible, local, and
   estimated data.
5. Run `make verify`.

Provider contributions should also document the data source, credential type,
known limitations, and privacy boundary.
