# Use the existing gno image as the base image
FROM ghcr.io/gnolang/gno:latest AS base

# Copy the setup script into the container
COPY ./setup.sh .

# Make the script executable
RUN chmod +x ./setup.sh

# Run the setup
CMD ["./setup.sh"]
