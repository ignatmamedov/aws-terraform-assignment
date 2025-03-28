FROM alpine:3.15

# Define a build argument with a default script name
ARG SEED_SCRIPT=add_data.sh
ENV SEED_SCRIPT=${SEED_SCRIPT}

# Install necessary packages
RUN apk add --no-cache curl bash

WORKDIR /seed-application

# Copy the seeding script and data file into the image
COPY ${SEED_SCRIPT} .
COPY data.md .

# Ensure the seeding script is executable
RUN chmod +x ${SEED_SCRIPT}

# Execute the script with data.md as an argument
CMD ["/bin/sh", "-c", "/seed-application/${SEED_SCRIPT} data.md"]
