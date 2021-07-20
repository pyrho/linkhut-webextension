# Linkhut Companion

A webextension for [linkhut](https://ln.ht).

## How To Build

Make sure you have the following dependencies installed:

- [just](https://github.com/casey/just) to run tasks
- [elm](https://elm-lang.org/) to build the source
- [node/npm](https://nodejs.org/en/) to package the extension via web-ext

Then run `just build` to create the extension archive.

A complete list of available commands is available by running `just` or by looking at [the justfile](./justfile)
