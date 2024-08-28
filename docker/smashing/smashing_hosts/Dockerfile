FROM armdocker.rnd.ericsson.se/proj-5g-cicd-dev/visibilityspots/smashing:1.0.2

RUN mkdir -p /app/cfg

ADD docker/smashing/smashing_hosts/hosts /app/cfg/remote_hosts
ADD docker/smashing/smashing_hosts/run_hosts.sh /run_hosts.sh

CMD ["/run_hosts.sh"]