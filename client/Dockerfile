# Build stage
FROM oven/bun:1 AS builder

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
FROM scratch AS export
COPY --from=builder /app/build /
