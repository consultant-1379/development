#############################################################
#############################################################

# Set the base image: ubuntu:14.04.5
FROM armdocker.rnd.ericsson.se/proj-5g-cicd-dev/ubuntu:14.04.5

# Maintainer of the file
LABEL maintainer="Roberto Valseca Vian"

# Enable Multiverse repositories
RUN sed -i 's/^#\s*\(deb.*multiverse\)$/\1/g' /etc/apt/sources.list

# Copy scripts
ADD scripts/install_dependencies.sh /install_dependencies.sh
ADD docker/requirements.yaml /requirements.yaml

# Install necessary tools
RUN /install_dependencies.sh requirements.yaml ubuntu_14_04_5_1

# Delete unnecessary scripts
RUN rm /install_dependencies.sh
RUN rm /requirements.yaml

ENTRYPOINT "/bin/bash"