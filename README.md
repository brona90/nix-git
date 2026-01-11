# Git Configuration Flake

My personal Git configuration managed with Nix flakes.

## Features

- Sensible defaults for modern Git workflows
- Comprehensive aliases for common operations
- Global gitignore for common files
- Histogram diff algorithm
- Auto-setup remote on push

## Usage
```bash
nix run .
```

## Home Manager Integration

This flake exports a `lib.mkGitConfig` function for use with home-manager.
