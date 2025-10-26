# Build stage
FROM rust:slim-trixie AS builder

WORKDIR /app

# Copy manifests
COPY Cargo.toml ./

# Create a dummy main.rs to build dependencies (for caching)
RUN mkdir src && echo "fn main() {}" > src/main.rs

# Build dependencies (this layer will be cached)
RUN cargo build --release

# Remove the dummy build artifacts
RUN rm -rf src target/release/zetteln-server* target/release/deps/zetteln_server*

# Copy actual source code
COPY src ./src

# Build the actual application
RUN touch src/main.rs && cargo build --release

# Runtime stage
FROM debian:bookworm-slim

# Install OpenSSL, CA certificates, and wget for healthcheck
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the built binary from builder
COPY --from=builder /app/target/release/zetteln-server /app/zetteln-server

EXPOSE 8080

CMD ["/app/zetteln-server"]
