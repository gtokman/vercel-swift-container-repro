# Swift on Vercel's container runtime: build cache repro

A hello-world [Hummingbird](https://github.com/hummingbird-project/hummingbird) server with
the same dependencies, pins (`Package.resolved`) and Dockerfile as our production Swift
server, with our own code taken out. It deploys with Vercel's container runtime
(`vercel.json` → `"runtime": "container"`).

## The problem

Every deploy builds the image from scratch: no Docker layers are reused between builds.

The Dockerfile is written for a layer cache. It compiles the dependencies (SwiftNIO,
swift-crypto, swift-syntax for macros and so on) against a stub source in their own layer,
which only changes with `Package.swift`/`Package.resolved`. With a cache, a code-only
change rebuilds just the app module, in well under a minute. On Vercel, both steps run
every time.

Our production server's numbers, for one deploy:

| Step | Time |
|---|---|
| Dependencies (stub layer) | 427 s |
| App build (recompiles all ~500 targets again) | 364 s |
| Whole build | 15 min 22 s |

That's about $0.22 per deploy at $0.0035 per build CPU-minute, and 15 minutes from push to
live, including for a one-line change.

## Reproduce

```sh
vercel deploy            # first build: full dependency compile
# edit the string in Sources/HelloServer/main.swift
vercel deploy            # second build: expected to reuse the dependency layer; it doesn't
curl https://<deployment>/   # Hello, world!
```

Compare the two build logs: the `swift build` in the stub layer runs in full both times.
Locally, `docker build .` twice with a source edit in between reuses that layer.

## What would help

- A layer cache between builds of the same project (like `--cache-from`/`--cache-to` with
  a registry, or BuildKit's cache), or a persistent cache directory that a build can mount
  (`RUN --mount=type=cache,target=/build/.build`).
- Auto-detecting a root `Dockerfile` for the container runtime without a `services` block
  in `vercel.json`. Without one, the first deploy finished in 2 s, built nothing and served
  404s.

## Run locally

```sh
swift run                # http://localhost:8080
docker build -t hello . && docker run -p 8080:8080 hello
```
