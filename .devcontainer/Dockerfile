# Use the Arista AVD image as the base
FROM ghcr.io/aristanetworks/avd/universal:python3.12-avd-v6.1.0

# 1. Install system dependencies as root
USER root
RUN apt-get update && apt-get install -y \
    acl xz-utils iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# 2. Python Tools
RUN pip3 install --no-cache-dir passlib
RUN pip install --upgrade pip
RUN pip install --no-cache-dir eos-downloader

# 3. Install Containerlab (Creates clab_admins group)
RUN curl -sL https://get.containerlab.dev | bash

# 4. The "Security Sync"
# We explicitly add the user to the groups AFTER install.
# We also create 'docker' group just in case it's missing in the base image.
RUN groupadd -f docker && \
    usermod -aG docker,clab_admins avd && \
    echo "avd ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/avd

# Set the default user back to avd (or change to ansible if you prefer)
USER avd