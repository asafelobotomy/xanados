# Development Setup

This guide explains how to install the tools used for linting and testing
XanadOS. Install these utilities before running the checks listed in
[AGENTS.md](../AGENTS.md).

## Node and npm

Ensure Node.js and npm are available:

```bash
sudo pacman -S nodejs npm   # Arch Linux example
```

Run `npm install` inside the project root to install project dependencies.

## Atom

Markdown files are validated using Atom. Install it from your package
manager or [atom.io](https://atom.io):

```bash
sudo pacman -S atom
```

Check documentation formatting with:

```bash
atom --check **/*.md
```

## Prettier

Prettier formats Markdown and JavaScript. Install it globally via npm:

```bash
npm install -g prettier
```

Verify formatting with:

```bash
prettier --check .
```

## ESLint

ESLint keeps the frontend code consistent. Install it globally or as a
local dev dependency:

```bash
npm install -g eslint
```

Run it using:

```bash
eslint file.js
```

## Additional Tools

The project also uses:

- `shellcheck` and `shfmt` for shell scripts
- `black` for Python code
- `bats` for shell tests

Install them with your package manager, for example:

```bash
sudo pacman -S shellcheck shfmt python-black bats
```
