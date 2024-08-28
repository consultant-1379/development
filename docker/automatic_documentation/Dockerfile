#############################################################
# Dockerfile to create an image with a container that generate
# HTML documentation automatically and upload it to OpenALM
# Base image: ubuntu:14.04.5-1
#############################################################

FROM armdocker.rnd.ericsson.se/proj-5g-cicd-dev/ubuntu:14.04.5-1

# Maintainer and vendor
LABEL maintainer="alberto.quintanaheras@altran.com"
LABEL vendor="Ericsson AB" version=${SD_RELEASE} description="Automatic documentation generator"

WORKDIR /home
RUN mkdir -p scripts
RUN mkdir -p 5gcicd

# Enable Multiverse repositories
RUN sed -i 's/^#\s*\(deb.*multiverse\)$/\1/g' /etc/apt/sources.list

ADD scripts/install_dependencies.sh .
ADD docker/requirements.yaml .

# Install necessary tools
RUN ./install_dependencies.sh ./requirements.yaml automatic_documentation_generator

# Delete unnecessary scripts
RUN rm ./install_dependencies.sh
RUN rm ./requirements.yaml

# Script to download from ARM
ADD scripts/arm/arm_download_file.sh ./scripts/arm_download_file.sh

# Install raml2html
RUN apt-get update && apt-get install -y texlive-latex-base texlive-latex-recommended texlive-latex-extra texlive-fonts-recommended latexmk
RUN npm install raml2html@3.0.1 -g
RUN npm cache clean -f
RUN npm install -g n
RUN n stable
RUN ln -s /usr/bin/nodejs /usr/bin/node

# Install sphinx, selenium and python plugins
RUN pip install sphinx selenium pyyaml xvfbwrapper pyvirtualdisplay

WORKDIR /home/scripts
ADD docker/automatic_documentation/run_generate_doc.sh ./run_generate_doc.sh
ADD docker/automatic_documentation/configuration.yaml ./configuration.yaml
ADD docker/automatic_documentation/constants.py ./constants.py
ADD docker/automatic_documentation/generate_docs.py ./generate_docs.py
ADD docker/automatic_documentation/upload_documents.py ./upload_documents.py
ADD docker/automatic_documentation/hosts ./hosts.new

ENTRYPOINT "/home/scripts/run_generate_doc.sh"

