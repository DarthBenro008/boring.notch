# Security Policy

## Reporting a Vulnerability

We take security bugs in Custom Notch seriously. Please report vulnerabilities privately via GitHub Security Advisories on this repository (use **Report a Vulnerability** on the Security tab) rather than opening a public issue.

We will acknowledge receipt and keep you updated on progress toward a fix when possible.

Report security bugs in third-party dependencies to the maintainers of those packages when appropriate.

## Plugins

Custom Notch runs plugins **in-process** with the host App Sandbox and entitlements.

- **First-party plugins** ship inside the app binary and are reviewed with the main codebase.
- **Third-party `.cnplugin` loading** is planned ([docs/plugins-third-party.md](./docs/plugins-third-party.md)). When enabled:
  - Release builds should **refuse unsigned or invalidly signed** plugins before load.
  - Loading third-party signed code under hardened runtime may require **disabling library validation** for the host process; that trade-off will be documented here when the entitlement is added.
  - Users should treat install/enable of third-party plugins as **trust decisions** (capability prompts, default-disabled after install).

Do not assume plugins are isolated from your calendar, network, or files beyond the host sandbox.
