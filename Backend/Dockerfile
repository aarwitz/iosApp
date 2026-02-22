# ================================
# Build stage
# ================================
FROM swift:5.10-jammy AS build

WORKDIR /build

# Copy package manifests first (cache layer for dependencies)
COPY Package.swift Package.resolved* ./
RUN swift package resolve

# Copy source code
COPY Sources/ Sources/
COPY Tests/ Tests/

# Build in release mode
RUN swift build -c release \
    --static-swift-stdlib \
    -Xlinker -lstdc++

# Grab the built binary name
RUN cp $(swift build -c release --show-bin-path)/App /build/app

# ================================
# Runtime stage (minimal image)
# ================================
FROM ubuntu:22.04

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get install -y --no-install-recommends \
        libcurl4 \
        ca-certificates \
        tzdata \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the built binary from build stage
COPY --from=build /build/app ./app

# Port is injected by Railway via $PORT env var
EXPOSE 8080

# Use shell form so $PORT is expanded at runtime
CMD ./app serve --env production --hostname 0.0.0.0 --port ${PORT:-8080}
