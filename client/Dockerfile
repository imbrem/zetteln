# Build stage
FROM oven/bun:1 AS builder

# Cache buster argument
ARG CACHEBUST=1

WORKDIR /app

# Copy package files
COPY package.json bun.lock ./

# Install dependencies
RUN bun install --frozen-lockfile

# Copy source code
COPY . .

# Build the static site
RUN bun run build

# Output stage - just the built files
### Final data image: small runtime that contains only the built static files
FROM alpine:3.18 AS data

# Install a tiny shell for the entrypoint
RUN apk add --no-cache ca-certificates

# Copy built static files into the image at /static
COPY --from=builder /app/build /static

# Entrypoint: copy static files from the image into the mounted target (/srv/www)
# then exit successfully. This makes the container a one-shot data populator.
RUN cat > /usr/local/bin/populate.sh <<'EOF'
#!/bin/sh
set -e
# Target dir where the volume is mounted (Caddy expects /srv/www)
TARGET=/srv/www

echo "[client] Populating $TARGET from image static assets..."
# Clean up any leftover temp directory from previous failed runs
rm -rf "$TARGET.tmp"
# Copy to a temp location then atomically move into place
cp -a /static/. "$TARGET.tmp/"
mv -f "$TARGET.tmp" "$TARGET"
echo "[client] Population complete."
EOF

RUN chmod +x /usr/local/bin/populate.sh

ENTRYPOINT ["/usr/local/bin/populate.sh"]
