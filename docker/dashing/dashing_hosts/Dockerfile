FROM frvi/dashing

RUN mkdir -p /app/cfg

ADD docker/dashing/dashing_hosts/hosts /app/cfg/remote_hosts
ADD docker/dashing/dashing_hosts/run_hosts.sh /run_hosts.sh

CMD ["/run_hosts.sh"]