# Contributing

Thanks for helping improve **Custom Notch**.

Custom Notch is a fork of [Boring Notch](https://github.com/TheBoredTeam/boring.notch). Please keep contributions focused on this fork’s goals and branding.

## Table of Contents

- [Contributing code](#contributing-code)
- [Reporting bugs](#reporting-bugs)
- [Feature requests](#feature-requests)

## Contributing code

### Before you start

- Search existing issues to avoid duplicates.
- Open an issue first for large features so the approach can be discussed.

### Environment

1. Fork this repository.
2. Clone your fork:
   ```bash
   git clone https://github.com/{your-username}/custom.notch.git
   cd custom.notch
   ```
3. Create a feature branch:
   ```bash
   git checkout -b feature/{your-feature-name}
   ```
4. Open the Xcode project:
   ```bash
   open customNotch.xcodeproj
   ```

### Making changes

1. Prefer small, focused commits.
2. Match existing SwiftUI / AppKit style in the tree.
3. Test on a notched Mac when possible (or with the non-notch height modes).
4. Update English strings in `customNotch/Localizable.xcstrings` when you add user-facing text.
5. Do not reintroduce upstream branding (`boring.notch`, The Bored Team links in product UI, etc.). Upstream credit belongs in the README shoutout only.

### Pull requests

Include:

- A clear title and description
- Linked issues when applicable
- Screenshots or recordings for UI changes

## Reporting bugs

Include:

- Clear title
- Steps to reproduce
- Expected vs actual behavior
- Screenshots or logs when useful
- macOS version and app version

## Feature requests

Describe the use case, proposed behavior, and why it helps Custom Notch users.

---

Thanks for contributing to Custom Notch.
