#!/bin/bash

docker run --rm -ti --name=ctop --volume=/var/run/docker.sock:/var/run/docker.sock quay.io/vektorlab/ctop
