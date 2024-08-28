FROM armdocker.rnd.ericsson.se/proj-5g-cicd-dev/jenkins/jnlp-slave-docker:3.10-1
LABEL vendor="Ericsson AB" version="3.10-1" description="JNLP agent with Docker 17.06 and hosts included"
LABEL maintainer "roberto.valseca@blue-tc.com"

# The working directory
WORKDIR /app
RUN mkdir -p /app/cfg
RUN mkdir -p /app/script

ADD docker/jenkins/jnlp-slave-docker-with-hosts/hosts /app/cfg/remote_hosts
ADD docker/jenkins/jnlp-slave-docker-with-hosts/start_jenkins_slave.sh /app/script/start_jenkins_slave.sh

ENTRYPOINT "/app/script/start_jenkins_slave.sh"
