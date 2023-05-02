#!/bin/bash -xe
yum-config-manager --enable rhui-REGION-rhel-server-extras rhui-REGION-rhel-server-optional
yum update -y

chage -I -1 -m 0 -M 99999 -E -1 ssm-user
chage -I -1 -m 0 -M 99999 -E -1 root