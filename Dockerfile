# Stage 1: Build stage
FROM arm64v8/debian:bullseye-slim AS builder

# Set non-interactive mode to avoid prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install Python and pip
RUN apt-get update && apt-get install -y \
    build-essential cmake git python3 python3-pip wget && \
    rm -rf /var/lib/apt/lists/*

# Clone repository and run install script
WORKDIR /app
RUN git clone https://github.com/Pelochus/ezrknn-llm.git && \
    cd ezrknn-llm && bash install.sh

# Copy application files
COPY app.py /app/
COPY requirements.txt /app/

# Install Python dependencies
RUN pip3 install --no-cache-dir -r /app/requirements.txt

# Stage 2: Runtime stage
FROM arm64v8/debian:bullseye-slim

# Install Python and pip
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip libstdc++6 wget && \
    rm -rf /var/lib/apt/lists/*

# Copy artifacts from builder stage
WORKDIR /app
COPY --from=builder /app/app.py /app/app.py
COPY --from=builder /app/requirements.txt /app/requirements.txt

# Install Python dependencies in runtime stage
RUN pip3 install --no-cache-dir -r /app/requirements.txt

# Copy additional required files (e.g., models, entrypoint script)
COPY models/ /app/models/
COPY entrypoint.sh /usr/bin/entrypoint.sh

# Make entrypoint script executable
RUN chmod +x /usr/bin/entrypoint.sh

# Copy librknnrt.so for NPU support
COPY librknnrt.so /usr/lib/librknnrt.so
RUN chmod +x /usr/lib/librknnrt.so

# Copy librkllmrt.so for NPU support
COPY librkllmrt.so /usr/lib/librkllmrt.so
RUN chmod +x /usr/lib/librkllmrt.so

# Copy the 'include' folder into /usr/local/include in the container
COPY include/ /usr/local/include/

# Expose necessary ports (e.g., Flask app port)
EXPOSE 8083

# Use entrypoint script for runtime configuration and execution
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
