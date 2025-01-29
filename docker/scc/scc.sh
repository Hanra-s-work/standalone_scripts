#!/bin/bash
sudo docker run --rm -it -v "$PWD:/pwd"  ghcr.io/lhoupert/scc:master scc /pwd
