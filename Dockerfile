# ------------------------------------------------
# Build Frontend (Next.js)
# ------------------------------------------------
FROM node:18 AS frontend
WORKDIR /web

# Install dependencies
COPY web/package*.json ./
RUN npm install

# Copy the rest of frontend source
COPY web ./

# Build frontend
RUN npm run build

# ------------------------------------------------
# Build Backend (Go)
# ------------------------------------------------
FROM golang:1.25 AS backend
WORKDIR /app

# Copy backend source
COPY . .

# Copy Next.js build output into Go embed directory
COPY --from=frontend /web/.next ./server/embed/frontend/.next
COPY --from=frontend /web/public ./server/embed/frontend/public

# Build Go backend
RUN go mod tidy
RUN go build -o app .

# ------------------------------------------------
# Final Runtime Image
# ------------------------------------------------
FROM debian:bookworm-slim

WORKDIR /app

# Copy Go executable
COPY --from=backend /app/app .

# Expose backend port
EXPOSE 8081

# Run app
CMD ["./app"]
