# Codex Usage for Ubuntu 22.04

A dependency-free GNOME Shell 42 extension that shows the current Codex usage
percentage in the top panel. Its menu shows both rate-limit windows, reset
times, credits, plan, and a manual refresh action.

## Install

```bash
./ubuntu-22/install.sh
```

If `codex` is managed by an editor and is not on your normal `PATH`, pass its
full path to the installer:

```bash
./ubuntu-22/install.sh /full/path/to/codex
```

Log out and back in, then enable it:

```bash
gnome-extensions enable codex-usage@dee.github.com
```

The indicator refreshes every five minutes.

You can also set or change that path manually:

```bash
mkdir -p ~/.config/codex-usage
command -v codex > ~/.config/codex-usage/codex-path
```

Run the data fetcher directly to diagnose login or path problems:

```bash
bash ubuntu-22/codex_usage.bash
```
