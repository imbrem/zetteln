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
mkdir -p "$TARGET"
# Copy to a temp location then atomically move to avoid partial content
cp -a /static/. "$TARGET.tmp"
# Remove old backup if it exists
rm -rf "$TARGET.old"
# Move current to .old (if exists), then move .tmp to current
if [ -d "$TARGET" ] && [ "$(ls -A $TARGET 2>/dev/null)" ]; then
  mv "$TARGET" "$TARGET.old" 2>/dev/null || true
fi
mv "$TARGET.tmp" "$TARGET"
rm -rf "$TARGET.old"
echo "[client] Population complete."
EOF

RUN chmod +x /usr/local/bin/populate.sh

ENTRYPOINT ["/usr/local/bin/populate.sh"]
