# Toxin ![status](https://ci.codeberg.org/api/badges/hanna/toxin/status.svg?branch=dev)

**Toxin** is an experimental Zsh plugin manager created for the modern era.

## Building from source

Toxin is written in the [Zig](https://ziglang.org) programming language, therefore you will need to
grab the compiler first.

```sh
REPO=https://ziglang.org/download/index.json
curl -sL $(curl -sL $REPO | jq -r '.master."x86_64-linux".tarball') | tar xJ
```

After you download the Zig compiler and (optionally) add it to your path, you can build the project.

```txt
git clone -b dev --recursive https://codeberg.org/hanna/toxin
cd toxin && zig build -Dleaks=true
```

By design Toxin builds against [musl libc](https://musl.libc.org/) on linux, and gnu libc on every
other platform; **Afterwards, run it!**

```txt
./zig-out/bin/toxin --version
```
