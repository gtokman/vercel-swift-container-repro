# Adapted from Hummingbird's template, as our production server's is.
FROM swift:6.3-noble AS build

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get install -y libjemalloc-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Dependencies first, compiled against a stub source, so this layer stays cached until
# Package.swift or Package.resolved change. With a layer cache, a change to Sources/ only
# recompiles our own module. Without one, every deploy pays the full build.
COPY Package.* ./
RUN swift package resolve
RUN mkdir -p Sources/HelloServer \
    && echo 'print("stub")' > Sources/HelloServer/main.swift \
    && swift build -c release --product HelloServer --static-swift-stdlib -Xlinker -ljemalloc \
    && rm -rf Sources

COPY Sources ./Sources
RUN swift build -c release --product HelloServer --static-swift-stdlib -Xlinker -ljemalloc

WORKDIR /staging
RUN cp "$(swift build -c release --show-bin-path)/HelloServer" ./

FROM ubuntu:noble

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q install -y libjemalloc2 ca-certificates tzdata libcurl4 \
    && rm -r /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /staging /app
ENV PORT=8080
EXPOSE 8080
ENTRYPOINT ["./HelloServer"]
