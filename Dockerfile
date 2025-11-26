# Multi-stage build for Memos deployment on Railway

# ------------------------------------------------
# Stage 1: Build Frontend (React + Vite, NOT Next.js)
# ------------------------------------------------
FROM node:20-alpine AS frontend

WORKDIR /web

# Install pnpm (Memos uses pnpm, not npm)
RUN corepack enable && corepack prepare pnpm@latest --activate

# Copy frontend dependencies
COPY web/package.json web/pnpm-lock.yaml ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy frontend source
COPY web/ ./

# Build frontend (outputs to dist/, not .next/)
# This runs: vite build -> outputs to web/dist/
RUN pnpm build

# ------------------------------------------------
# Stage 2: Build Backend (Go)
# ------------------------------------------------
FROM golang:1.25-alpine AS backend

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache git

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy backend source
COPY . .

# Copy built frontend from previous stage
# The frontend must go to server/router/frontend/dist/
COPY --from=frontend /web/dist ./server/router/frontend/dist

# Build Go backend
# Binary name: memos, entry point: ./cmd/memos
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags="-w -s" -o memos ./cmd/memos

# ------------------------------------------------
# Stage 3: Final Runtime Image
# ------------------------------------------------
FROM alpine:latest

# Install ca-certificates for HTTPS and timezone data
RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app

# Copy Go executable
COPY --from=backend /app/memos .

# Create data directory for SQLite and uploads
RUN mkdir -p /var/opt/memos

# Expose port (Railway uses PORT env variable)
EXPOSE 5230

# Set default environment variables
ENV MEMOS_MODE=prod \
    MEMOS_ADDR=0.0.0.0 \
    MEMOS_PORT=5230 \
    MEMOS_DATA=/var/opt/memos

# Run app - Railway provides PORT, fallback to 5230
CMD sh -c './memos --mode ${MEMOS_MODE} --addr ${MEMOS_ADDR} --port ${PORT:-${MEMOS_PORT}} --data ${MEMOS_DATA}'
