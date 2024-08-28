# Container
This image adds the Docker CLI to the JNLP agent used by jenkins-kubernetes-plugin.

###Without Hosts:
docker build --no-cache -t armdocker.rnd.ericsson.se/proj-5g-cicd-dev/jenkins/jnlp-slave-docker:3.10-1 -f docker/jenkins/jnlp-slave-docker/Dockerfile .

###With Hosts:
docker build --no-cache --add-host <host1>:<ip1> --add-host <host2>:<ip2> ... --add-host <hostn>:<ipn> -t armdocker.rnd.ericsson.se/proj-5g-cicd-dev/jenkins/jnlp-slave-docker-with-hosts:3.10-1 -f docker/jenkins/jnlp-slave-docker/Dockerfile .
####Eg:
docker build --no-cache --add-host gerrit.ericsson.se:147.214.18.83 --add-host arm.lmera.ericsson.se:150.132.79.143 --add-host arm.epk.ericsson.se:136.225.199.185 --add-host armdocker.rnd.ericsson.se:136.225.199.184 --add-host arm.mo.sw.ericsson.se:132.196.28.11 --add-host proxy.ericsson.se:153.88.253.150 -t armdocker.rnd.ericsson.se/proj-5g-cicd-dev/jenkins/jnlp-slave-docker-with-hosts:3.10-1 -f docker/jenkins/jnlp-slave-docker/Dockerfile .

docker run -it  --add-host gerrit.ericsson.se:147.214.18.83 --add-host arm.lmera.ericsson.se:150.132.79.143 --add-host arm.epk.ericsson.se:136.225.199.185 --add-host armdocker.rnd.ericsson.se:136.225.199.184 --add-host arm.mo.sw.ericsson.se:132.196.28.11 --add-host proxy.ericsson.se:153.88.253.150 --rm --entrypoint /bin/bash armdocker.rnd.ericsson.se/proj-5g-cicd-dev/jenkins/jnlp-slave-docker-with-hosts-ver2:3.10-1