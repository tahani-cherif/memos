# -----------------------------
# Build frontend
# -----------------------------
FROM node:18 AS frontend
WORKDIR /web

# Install dependencies
COPY web/package*.json ./
RUN npm install

# Copy frontend source and build
COPY web .
RUN npm run build

# -----------------------------
# Build backend
# -----------------------------
FROM golang:1.25 AS backend
WORKDIR /app

# Copy backend source
COPY . .

# Copy frontend build into backend embed folder
COPY --from=frontend /web/dist ./server/embed/frontend

# Verify Go version
RUN go version

# Build Memos binary (CLI entry point)
RUN go build -o memos ./cmd/memos

# -----------------------------
# Final runtime image
# -----------------------------
FROM debian:bookworm-slim
WORKDIR /app

# Install CA certificates (needed for HTTPS)
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

# Copy built binary and embedded frontend
COPY --from=backend /app/memos .
COPY --from=backend /app/server/embed ./embed

# Expose Memos port
EXPOSE 8081

# Set environment variable for production mode by default
ENV MEMOS_MODE=prod

# Run Memos
CMD ["./memos", "--mode", "prod", "--addr", "0.0.0.0", "--port", "8081"]
