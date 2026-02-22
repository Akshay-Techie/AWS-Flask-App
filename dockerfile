# Use official lightweight Python image
FROM python:3.11-slim

# Set working directory inside container
WORKDIR /app

# Copy main.py into container
COPY main.py .

# Copy templates folder (contains index.html) into container
COPY templates/ templates/

# Install Flask
RUN pip install flask

# Expose port 5000
EXPOSE 5000

# Run the app
CMD ["python", "main.py"]