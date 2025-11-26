# -----------------------------
# Build frontend
# -----------------------------
FROM node:18 AS frontend
WORKDIR /web

COPY web/package*.json ./
RUN npm install

COPY web ./
RUN npm run build   # produces dist/


# -----------------------------
# Build backend
# -----------------------------
FROM golang:1.25 AS backend
WORKDIR /app

# Copy backend source
COPY . .

# Copy frontend build into the Go embed directory
# IMPORTANT: this folder MUST match your project structure
COPY --from=frontend /web/dist ./server/embed/frontend

RUN go version

# Build the Go binary
RUN go build -o memos ./cmd/memos


# -----------------------------
# Final runtime image
# -----------------------------
FROM debian:bookworm-slim
WORKDIR /app

# Create memos data directory
RUN mkdir -p /var/opt/memos && chmod -R 777 /var/opt/memos

ENV MEMOS_DATA=/var/opt/memos

# Copy the binary
COPY --from=backend /app/memos .

# Copy the embedded frontend folder
COPY --from=backend /app/server/embed ./embed

EXPOSE 8081

CMD ["./memos"]
