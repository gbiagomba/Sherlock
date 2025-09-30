# Use the official Rust image as a base image
FROM rust:latest AS builder

# Install nmap (or any other tools the Rust program might use)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates pkg-config libssl-dev make git curl wget unzip \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory inside the container
WORKDIR /usr/src/sherlock

# Copy the Cargo.toml and Cargo.lock files first (to cache dependencies)
COPY Cargo.toml Cargo.lock ./

# Fetch dependencies, caching them
RUN cargo fetch

# Copy the rest of the project files into the container
COPY . .
RUN cargo build --release

FROM debian:stable-slim AS runner
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates git curl unzip nmap gobuster golang && rm -rf /var/lib/apt/lists/*
ENV GOPATH=/root/go PATH=/root/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
# Install httpx, nuclei, and amass
RUN go install github.com/projectdiscovery/httpx/cmd/httpx@latest && \
    go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest && \
    go install github.com/owasp-amass/amass/v3/...@latest
WORKDIR /app
COPY --from=builder /usr/src/sherlock/target/release/sherlock /usr/local/bin/sherlock
COPY rsc /app/rsc
ENTRYPOINT ["sherlock"]
