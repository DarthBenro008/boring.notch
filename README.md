<h1 align="center">
  <br>
  Custom Notch
  <br>
</h1>

<p align="center">
  <em>A powerful, customizable MacBook notch experience — forked and extended from Boring Notch.</em>
</p>

---

## Credits & shoutout

**Custom Notch** is a fork of **[Boring Notch](https://github.com/TheBoredTeam/boring.notch)** by **[The Bored Team](https://github.com/TheBoredTeam)**.

Huge thanks to everyone who built and maintained the original project — the architecture, polish, and community around Boring Notch made this fork possible. If you are looking for the upstream project, start here:

- **Upstream repo:** [TheBoredTeam/boring.notch](https://github.com/TheBoredTeam/boring.notch)
- **Website:** [theboring.name](http://theboring.name)

This fork renames the product, rebrands the codebase, and is the base for additional features beyond the original.

---

Say hello to **Custom Notch** — turn your MacBook’s notch into a dynamic control center with music controls and a visualizer, calendar integration, a file shelf with AirDrop support, system HUD replacements, and more.

<p align="center">
  <img src="https://github.com/user-attachments/assets/2d5f69c1-6e7b-4bc2-a6f1-bb9e27cf88a8" alt="Demo GIF" />
</p>

## Installation

**System Requirements:**
- macOS **14 Sonoma** or later
- Apple Silicon or Intel Mac

### Build from source (recommended for this fork)

1. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/custom.notch.git
   cd custom.notch
   ```

2. Open the project:
   ```bash
   open customNotch.xcodeproj
   ```

3. Select the **customNotch** scheme and press **Run** (`Cmd + R`).

### Gatekeeper note

If you distribute unsigned builds, macOS may warn that Custom Notch is from an unidentified developer. After moving the app to `/Applications`, you can clear quarantine with:

```bash
xattr -dr com.apple.quarantine /Applications/customNotch.app
```

## Usage

- Launch the app — the notch becomes an interactive surface at the top of the screen.
- Hover over the notch to expand it.
- Use music controls, calendar, shelf, and HUD features as enabled in Settings.
- Open Settings from the menu bar extra (sparkle icon) to customize behavior.

## Roadmap

Inherited and extended from the upstream project:

- [x] Playback live activity
- [x] Calendar integration
- [x] Reminders integration
- [x] Mirror
- [x] Charging indicator and percentage
- [x] Customizable gesture control
- [x] Shelf with AirDrop
- [x] Notch sizing customization
- [x] System HUD replacements (volume, brightness, backlight)
- [x] Plugin system (in-process first-party plugins; Hello Sample included)
- [ ] Bluetooth live activity
- [ ] Weather integration
- [ ] Customizable layout options
- [ ] Lock screen widgets
- [ ] WiZ lamp / audio-output sample plugins
- [ ] Additional Custom Notch–specific features (coming soon)

## Building from Source

### Prerequisites

- **macOS 15.6 or later** (recommended for development)
- **Xcode 16 or later**

### Steps

```bash
git clone https://github.com/YOUR_USERNAME/custom.notch.git
cd custom.notch
open customNotch.xcodeproj
```

Then build and run the **customNotch** scheme.

See [AGENTS.md](./AGENTS.md) for architecture notes useful when adding features.

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md) for setup and PR guidelines.

## Acknowledgments

Gratitude to the authors and maintainers of open-source projects that made this possible, including:

- **[Boring Notch](https://github.com/TheBoredTeam/boring.notch)** / **[The Bored Team](https://github.com/TheBoredTeam)** — original app this fork is based on
- **[MediaRemoteAdapter](https://github.com/ungive/mediaremote-adapter)** — Now Playing support on newer macOS
- **[NotchDrop](https://github.com/Lakr233/NotchDrop)** — instrumental for the early Shelf feature

For a full list of licenses and attributions, see [THIRD_PARTY_LICENSES](./THIRD_PARTY_LICENSES).

## License

This project remains under the **GNU General Public License v3.0** (see [LICENSE](./LICENSE)), consistent with the upstream project.
