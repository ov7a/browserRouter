# Browser Router

This is a simple app to select a browser based on a URL.
For example, open GitHub links in Firefox but open Google Docs in Chromium.
Note that this is a CLI app; it accepts a URL as a command-line argument.
It does not work with in-browser links; you'll need a custom browser extension for that.

It was made to get a taste of [Zig](https://ziglang.org/).

## Build

```sh
zig build
```
This app was originally developed with zig 0.11.

## Install

For Linux:

1. Edit `config.cfg`.
2. run
   ```sh
   ./install_linux.sh
   ```

For Mac:

While it works from CLI, Apple passes URLs via AppleEvents.
So this app can't be used as a default browser (yet).   
