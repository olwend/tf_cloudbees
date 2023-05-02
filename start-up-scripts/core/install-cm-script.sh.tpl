#!/bin/bash

### RETRIEVE BINARIES FROM S3 ###
if [ ! -f /tmp/${RPM_NAME}.noarch.rpm ]; then
    echo "Retrieving the RPM"
    aws s3 cp s3://${BINARIES_BUCKET}/core/${RPM_NAME}.noarch.rpm /tmp/ --quiet
else
    echo "RPM already downloaded"
fi

### INSTALL THE RPM ###
if ! rpm -q java-11-openjdk-devel; then
    echo "Installing JAVA"
    yum install -y java-11-openjdk-devel
fi

if ! rpm -q cloudbees-core-cm; then
    echo "Installing Cloudbees Core CM"
    yum install -y /tmp/${RPM_NAME}.noarch.rpm
fi


### UPDATE JAVA ARGS ###
echo "Retrieving the sysconfig file"
aws s3 cp s3://${BINARIES_BUCKET}/core/cloudbees-core-cm /tmp/ --quiet
sudo cp /tmp/cloudbees-core-cm /etc/sysconfig/cloudbees-core-cm
sudo chmod 644 /etc/sysconfig/cloudbees-core-cm
echo "Copying sysconfig file"

### START THE SERVICE ###
systemctl start cloudbees-core-cm
### OUTPUT STATUS ###
systemctl status cloudbees-core-cm --quiet


