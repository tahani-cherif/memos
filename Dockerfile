# Build frontend
FROM node:18 AS frontend
WORKDIR /web
COPY web/package*.json ./
RUN npm install
COPY web .
RUN npm run build

# Build backend
FROM golang:1.25 AS backend
WORKDIR /app
COPY . .
COPY --from=frontend /web/dist ./server/embed/frontend
RUN go version
RUN go build -o memos ./server/cmd/memos

# Final image
FROM debian:bookworm-slim
WORKDIR /app
COPY --from=backend /app/memos .
COPY --from=backend /app/server/embed ./embed
EXPOSE 8081
CMD ["./memos"]
