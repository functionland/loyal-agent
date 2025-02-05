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

# Install PyInstaller and create executable
RUN pip3 install pyinstaller
COPY app.py /app/
RUN pyinstaller --onefile --name rkllm_server /app/app.py

# Stage 2: Runtime stage
FROM arm64v8/debian:bullseye-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 libstdc++6 wget && \
    rm -rf /var/lib/apt/lists/*

# Copy artifacts from builder stage
WORKDIR /app
COPY --from=builder /app/dist/rkllm_server /usr/bin/rkllm_server

# Copy additional required files (e.g., models, entrypoint script)
COPY models/ /app/models/
COPY entrypoint.sh /usr/bin/entrypoint.sh

# Make entrypoint script executable
RUN chmod +x /usr/bin/entrypoint.sh

# Copy librknnrt.so for NPU support
COPY librknnrt.so /usr/lib/librknnrt.so
RUN chmod +x /usr/lib/librknnrt.so

# Expose necessary ports (e.g., Flask app port)
EXPOSE 8083

# Use entrypoint script for runtime configuration and execution
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
