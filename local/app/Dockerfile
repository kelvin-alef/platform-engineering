# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /src

# Copy go.mod first to leverage Docker cache
COPY go.mod ./
RUN go mod download

# Copy application source code
COPY main.go ./

# Build static binary
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/server .

# Run stage
FROM alpine:3.19

RUN apk --no-cache add curl

WORKDIR /app

COPY --from=builder /app/server .

EXPOSE 8080

CMD ["./server"]
