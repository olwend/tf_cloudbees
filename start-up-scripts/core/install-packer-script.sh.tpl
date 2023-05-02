#!/bin/bash

### RETRIEVE BINARIES FROM S3 ###

if [ ! -f /tmp/${PACKAGE_NAME} ]; then
    echo "Retrieving Packer"
    aws s3 cp s3://${BINARIES_BUCKET}/hashicorp/${PACKAGE_NAME} /tmp/ --quiet
else
    echo "Packer already downloaded"
fi

### UNZIP PACKER ###
unzip -o /tmp/${PACKAGE_NAME} -d /tmp

### MOVE TO PATH ###
mv /tmp/packer /usr/local/bin/packer
    echo "packer $(packer --version) is installed"
    