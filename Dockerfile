# -----------------------------
# Build frontend
# -----------------------------
FROM node:18 AS frontend
WORKDIR /web
COPY web/package*.json ./
RUN npm install
COPY web .
RUN npm run build

# -----------------------------
# Build backend
# -----------------------------
FROM golang:1.25 AS backend
WORKDIR /app
COPY . .

# Copy frontend build into backend embed folder
COPY --from=frontend /web/dist ./server/embed/frontend

# Verify Go version
RUN go version

# Build the Memos binary (correct path)
RUN go build -o memos ./cmd/memos

# -----------------------------
# Final runtime image
# -----------------------------
FROM debian:bookworm-slim
WORKDIR /app

# Copy built binary and embedded frontend
COPY --from=backend /app/memos .
COPY --from=backend /app/server/embed ./embed

EXPOSE 8081

CMD ["./memos"]
