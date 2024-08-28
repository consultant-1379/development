FROM jenkinsci/jnlp-slave:2.62
LABEL vendor="Ericsson AB" version="2.62" description="JNLP agent with Docker 17.06"
LABEL maintainer "jesus.javier.arauz@ericsson.com"
USER root

# Install the required packages.
ADD scripts/install_dependencies.sh /install_dependencies.sh
ADD docker/requirements.yaml /requirements.yaml
# Install Dependencies.
RUN /install_dependencies.sh /requirements.yaml jenkins_slave
## Remove scripts.
RUN rm /install_dependencies.sh
RUN rm /requirements.yaml

ADD https://download.docker.com/linux/static/stable/x86_64/docker-17.06.0-ce.tgz /tmp/
RUN if [ -e /tmp/docker-17.06.0-ce.tgz ]; then  tar -zxvf /tmp/docker-17.06.0-ce.tgz -C /tmp/; rm -f /tmp/docker-17.06.0-ce.tgz; fi
RUN mv /tmp/docker/docker* /usr/local/bin/
RUN rm -rf /tmp/docker/
RUN groupadd docker
RUN usermod -aG docker jenkins

#USER jenkins
