# Use Python 3.11 on Alpine for smaller image size
FROM python:3.11-alpine

# Set working directory
WORKDIR /app

# Install system dependencies for psycopg2
RUN apk add --no-cache \
    postgresql-dev \
    gcc \
    musl-dev \
    linux-headers

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create non-root user
RUN addgroup -g 1001 -S python && \
    adduser -S python -u 1001 && \
    chown -R python:python /app

# Switch to non-root user
USER python

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:8000/health || exit 1

# Start application
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
