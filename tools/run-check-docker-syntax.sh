#!/bin/bash

### Temp docker syntax checker script. Doesnt really check something...
set -e
for file in $(find . -name 'Dockerfile.j2')
do
    fgrep -q FROM $file
    fgrep -q MAINTAINER $file
    fgrep -q RUN $file
done
