# -----------------------------
# Build frontend
# -----------------------------
FROM node:18 AS frontend
WORKDIR /web

COPY web/package*.json ./
RUN npm install

COPY web .
RUN npm run build   # output = dist


# -----------------------------
# Build backend
# -----------------------------
FROM golang:1.25 AS backend
WORKDIR /app

COPY . .

# Copy frontend build output
COPY --from=frontend /web/.next ./server/embed/frontend

RUN go version

RUN go build -o memos ./cmd/memos


# -----------------------------
# Final runtime image
# -----------------------------
FROM debian:bookworm-slim
WORKDIR /app

# Create required data folder
RUN mkdir -p /var/opt/memos && chmod -R 777 /var/opt/memos

# Optional: explicitly set data folder
ENV MEMOS_DATA=/var/opt/memos

COPY --from=backend /app/memos .
COPY --from=backend /app/server/embed ./embed

EXPOSE 8081

CMD ["./memos"]
