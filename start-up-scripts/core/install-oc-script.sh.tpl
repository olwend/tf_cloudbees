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

if ! rpm -q cloudbees-core-oc; then
    echo "Installing Cloudbees Core OC"
    yum install -y /tmp/${RPM_NAME}.noarch.rpm
fi

### UPDATE JAVA ARGS ###
    echo "Retrieving the sysconfig file"
    aws s3 cp s3://${BINARIES_BUCKET}/core/cloudbees-core-oc /tmp/ --quiet
    sudo cp /tmp/cloudbees-core-oc /etc/sysconfig/cloudbees-core-oc
    sudo chmod 644 /etc/sysconfig/cloudbees-core-oc
    echo "Copying sysconfig file"

### START THE SERVICE ###
systemctl start cloudbees-core-oc

### OUTPUT STATUS ###
systemctl status cloudbees-core-oc --quiet

