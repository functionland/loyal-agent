# Stage 1: Build stage
FROM arm64v8/debian:bullseye-slim AS builder

# Set non-interactive mode to avoid prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies with workarounds for libc-bin issues
RUN apt-get update && apt-get install -y \
    build-essential cmake git python3 python3-pip wget || true && \
    dpkg --configure -a && \
    apt-get install -f -y && \
    rm -rf /var/lib/apt/lists/*

# Clone repository and run install script
WORKDIR /app
RUN git clone https://github.com/Pelochus/ezrknn-llm.git && \
    cd ezrknn-llm && bash install.sh

# Copy the Python script instead of compiling it
COPY app.py /app/

# Stage 2: Runtime stage
# Use the official Python base image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy application files
COPY app.py /app/app.py
COPY models/ /app/models/
COPY entrypoint.sh /usr/bin/entrypoint.sh

# Install required libraries (if any)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libstdc++6 wget && \
    rm -rf /var/lib/apt/lists/*

# Make entrypoint script executable
RUN chmod +x /usr/bin/entrypoint.sh

# Expose necessary ports
EXPOSE 8083

# Set entrypoint
ENTRYPOINT ["/usr/bin/entrypoint.sh"]