# The base image is Ubuntu 16.04
FROM armdocker.rnd.ericsson.se/proj_kds/erikube/client

LABEL maintainer="veronica.gomez.gomez@ericsson.com"
LABEL vendor="Ericsson AB" description="Nightly Jenkins builder"

ENV APPS_ROOT="/apps"
RUN mkdir -p ${APPS_ROOT}/scripts
RUN mkdir -p ${APPS_ROOT}/cfg

# Get the s6-overlay package
ADD https://github.com/just-containers/s6-overlay/releases/download/v1.11.0.1/s6-overlay-amd64.tar.gz /tmp/
RUN if [ -e /tmp/s6-overlay-amd64.tar.gz ]; then tar -zxvf /tmp/s6-overlay-amd64.tar.gz -C /; rm -f /tmp/s6-overlay-amd64.tar.gz; fi

#RUN yum -y update
RUN yum --enablerepo=base clean metadata
RUN yum makecache fast
RUN yum -y install yum-cron git glibc glibc-common glibc-devel gcc gnutls make zip unzip install python-devel libxml2-devel libxslt-devel libffi-devel openssl-devel

ADD docker/night-trigger/known_hosts ${APPS_ROOT}/cfg/known_hosts

ADD docker/night-trigger/crontab /etc/cron.d/nightly-jenkins
RUN chmod 644 /etc/cron.d/nightly-jenkins
RUN chmod 644 /etc/crontab

ADD env/cfg/kubernetes/admin.conf /kubecluster/admin.conf
ADD docker/night-trigger/scripts/jenkins.sh ${APPS_ROOT}/scripts/jenkins.sh
RUN chmod 775 ${APPS_ROOT}/scripts/jenkins.sh

RUN cat /etc/crontab >> /etc/cron.d/nightly-jenkins
RUN cat /etc/crontab >> /var/spool/cron/nightly-jenkins

#Installing and configuring supervisord, to make sure crond works
ADD docker/night-trigger/cfg/supervisord.conf /etc/supervisord.conf
RUN yum -y install python-setuptools
RUN easy_install pip
RUN pip install supervisor

#Installing a compatible version of helm
RUN rm -f /usr/bin/helm
RUN wget https://storage.googleapis.com/kubernetes-helm/helm-v2.4.2-linux-amd64.tar.gz -P /tmp/
RUN if [ -e /tmp/helm-v2.4.2-linux-amd64.tar.gz ]; then tar -zxvf /tmp/helm-v2.4.2-linux-amd64.tar.gz -C /tmp/; rm -f /tmp/helm-v2.4.2-linux-amd64.tar.gz; fi
RUN mv /tmp/linux-amd64/helm /usr/bin/
RUN rm -r -f /tmp/linux-amd64

WORKDIR ${APPS_ROOT}

CMD ["/usr/bin/supervisord", "-n"]


