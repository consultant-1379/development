FROM armdocker.rnd.ericsson.se/proj-5g-cicd-dev/golang:latest
LABEL maintainer "veronica.gomez.gomez@ericsson.com"

# Install the required packages.
ADD scripts/Jenkins/purge_images.go /purge_images.go

ENTRYPOINT ["go run /purge_images.go"]
