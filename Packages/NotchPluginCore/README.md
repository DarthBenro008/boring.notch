# NotchPluginCore

Shared, **testable** logic used by Custom Notch plugins. Keep UI and OS integrations in the app target (`customNotch/Plugins/`); put pure models and algorithms here.

## What’s in the package

| Module area | Responsibility |
|-------------|----------------|
| `WizLampAPI` | Bulb configuration, SSID automation decisions, JSON request/response, injectable transport |
| `AudioOutputCore` | Device model, Core Audio transport fourCC mapping, sort / mark-default helpers |

## Run tests

```bash
cd Packages/NotchPluginCore
swift test
```

## Related docs

- [Plugin development guide](../../docs/plugins.md) — how to write app-side plugins, surfaces, limitations
- [AGENTS.md](../../AGENTS.md) — full repo architecture
- [README.md](../../README.md) — product features and roadmap
