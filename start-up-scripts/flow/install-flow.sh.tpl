#!/bin/bash

# Vars 
INSTALL_DIR=/opt/electriccloud/electriccommander
JDBC_URL=http://dev.mysql.com/get/Downloads/Connector-J
JDBC_VERSION=5.1.49

# Create the users 
useradd -m flow
useradd -m flow-agent

### RETRIEVE BINARIES FROM S3 ###
echo "Retreiving S3 binaries"
/bin/aws s3 cp s3://${BINARIES_BUCKET}/ /tmp/binaries/ --quiet --recursive
find /tmp/binaries/ -type f -exec chmod +x {} \;

### MOUNT DISK ###
if !(grep -qs "/data" /proc/mounts)
then
  echo "Mounting data directory"
  mkfs -t xfs /dev/nvme1n1
  mount /dev/nvme1n1 /data
  NEW_VOLUME_UUID=`lsblk /dev/nvme1n1 -n -o UUID`
  echo "UUID=$NEW_VOLUME_UUID /data xfs defaults 0 2" >> /etc/fstab
fi

### FLOW SERVER INSTALL ###
echo "Installing flow server"
/tmp/binaries/${FLOW_BINARY_NAME} \
  --mode silent \
  --installServer \
  --installAgent \
  --installDatabase \
  --installWeb \
  --installRepository \
  --dataDirectory /data/flow \
  --unixServerUser flow \
  --unixServerGroup users

### JDBC Install ###
echo "Copying JDBC"
wget $JDBC_URL/mysql-connector-java-$JDBC_VERSION.tar.gz -O /tmp/mysql-connector.tar.gz 
tar -xvzf /tmp/mysql-connector.tar.gz
mv /tmp/mysql-connector-java-$JDBC_VERSION/mysql-connector-java-$JDBC_VERSION.jar $INSTALL_DIR/mysql-connector-java.jar

### AGENT BINARY ###
echo "Adding the agent binary"
mv /tmp/binaries/${FLOW_AGENT_BINARY_NAME} /opt/electriccloud/electriccommander/${FLOW_AGENT_BINARY_NAME}

### WAIT FOR FLOW SERVER ###
until /opt/electriccloud/electriccommander/bin/ectool --format json getServerStatus | grep  -q '"serverState" : "running"'
do
  echo "Waiting for server to start"
  sleep 30
done

### USER MANAGEMENT ###
echo "Completing user management steps"
/opt/electriccloud/electriccommander/bin/ectool login admin changeme # Login to ectools as admin

# INSIGHTS_PASSWORD=$(openssl rand -base64 32)
# echo "$INSIGHTS_PASSWORD" > /tmp/insights.txt
# /opt/electriccloud/electriccommander/bin/ectool createUser "insights" --password $INSIGHTS_PASSWORD # Create insights user

ADMIN_PASSWORD=$(openssl rand -base64 32)
#echo "$ADMIN_PASSWORD" > /tmp/flow.txt
/opt/electriccloud/electriccommander/bin/ectool modifyUser "admin" --password "I8JW5CNOCzLWWbV+rsxVz8NFALSQbXVOcQdKEGSrjns=" --sessionPassword changeme # Change admin password

### DEVOPS INSIGHTS INSTALL ###
echo "Installing DevOps Insights"
/tmp/binaries/${FLOW_INSIGHTS_BINARY_NAME} \
  --mode silent \
  --dataDirectory /data/flow \
  --unixServerUser flow \
  --unixServerGroup users \
  --remoteServer localhost:8443 \
  --remoteServerUser admin \
  --remoteServerPassword $ADMIN_PASSWORD