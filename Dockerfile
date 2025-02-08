# Stage 1: Build Stage (oven/bun:1.1.44-alpine, ARM64)
FROM oven/bun:1.1.44-alpine AS builder

# Set working directory and copy necessary files
WORKDIR /app

# COPY files
COPY . .

# Install Git and dependencies, then build the project
RUN --mount=type=cache,target=/var/cache/apk \
    apk update && apk add --no-cache git

RUN --mount=type=cache,target=/root/.bun \
    --mount=type=cache,target=/root/.cache/bun \
    bun install

RUN bun run build

# Stage 2: NGINX Unprivileged Setup (1.27.3-alpine-slim, ARM64)
FROM nginxinc/nginx-unprivileged:1.27.3-alpine-slim AS final

# Set working directory for NGINX and copy built files from the build stage
WORKDIR /usr/share/nginx/html
COPY --from=builder /app/docs/.vitepress/dist /usr/share/nginx/html/docs

# Copy custom NGINX configuration
COPY nginx/nginx.conf /etc/nginx/nginx.conf

# Copy custom redirects NGINX configuration
COPY nginx/redirects.conf /etc/nginx/conf.d/redirects.conf

# Expose port 80
EXPOSE 80

# Start NGINX
CMD ["nginx", "-g", "daemon off;"]
