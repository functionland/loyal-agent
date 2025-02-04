# Stage 1: Build stage
FROM debian:bullseye-slim AS builder

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential cmake git python3 python3-pip wget && \
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
FROM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache python3 bash libstdc++ libc6-compat wget

# Copy artifacts from builder stage
WORKDIR /app
COPY --from=builder /app/dist/rkllm_server /usr/bin/rkllm_server

# Copy additional required files (e.g., models, entrypoint script)
COPY models/ /app/models/
COPY entrypoint.sh /usr/bin/entrypoint.sh

# Make entrypoint script executable
RUN chmod +x /usr/bin/entrypoint.sh

# Download librknnrt.so for NPU support with retry logic
RUN wget --tries=3 --retry-connrefused -q https://github.com/rockchip-linux/rknpu2/raw/master/runtime/RK3588/Linux/librknn_api/aarch64/librknnrt.so -O /usr/lib/librknnrt.so && \
    chmod +x /usr/lib/librknnrt.so

# Expose necessary ports (e.g., Flask app port)
EXPOSE 8083

# Use entrypoint script for runtime configuration and execution
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
