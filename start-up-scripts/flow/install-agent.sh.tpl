#!/bin/bash

# Vars 
AGENT_USER=flow-agent
ADMIN_USERNAME=admin
ADMIN_PASSWORD="I8JW5CNOCzLWWbV+rsxVz8NFALSQbXVOcQdKEGSrjns="

# Create the users 
echo "Creating users"
useradd -m $AGENT_USER

### RETRIEVE BINARIES FROM S3 ###
echo "Retreiving S3 binaries"
aws s3 cp s3://${BINARIES_BUCKET}/${FLOW_AGENT_BINARY_NAME} /tmp/binaries/${FLOW_AGENT_BINARY_NAME} --quiet
find /tmp/binaries/ -type f -exec chmod +x {} \;

### INSTALL AGENT ###
echo "Installing the app"
/tmp/binaries/${FLOW_AGENT_BINARY_NAME} \
    --mode silent \
    --installAgent \
    --unixAgentUser root \
    --unixAgentGroup root \
    --agentAllowRootUser \
    --remoteServerCreateResource \
    --remoteServer "${FLOW_SERVER_IP}" \
    --remoteServerUser "$ADMIN_USERNAME" \
    --remoteServerPassword "$ADMIN_PASSWORD"

### Change wrapper port
cat >> /opt/electriccloud/electriccommander/conf/agent/wrapper.conf <<EOL
wrapper.port=34000
wrapper.jvm.port.min=34000
wrapper.jvm.port.max=34999
EOL

### Restart the service 
/etc/init.d/commanderAgent restart

### Get aws instance id and region and tags.
INSTANCEID="`wget -qO- http://instance-data/latest/meta-data/instance-id`"
REGION="`wget -qO- http://instance-data/latest/meta-data/placement/availability-zone | sed -e 's:\([0-9][0-9]*\)[a-z]*\$:\\1:'`"
INSTANCETYPE="`aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCEID" "Name=key,Values=InstanceType" --region $REGION --output=text | cut -f5`"
MODULENAME="`aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCEID" "Name=key,Values=ModuleName" --region $REGION --output=text | cut -f5`"

### Move agent to the correct resource pool
COMMANDER_SERVER="${FLOW_SERVER_IP}"
/opt/electriccloud/electriccommander/bin/ectool login "$ADMIN_USERNAME" "$ADMIN_PASSWORD"
/opt/electriccloud/electriccommander/bin/ectool modifyResourcePool $MODULENAME-$INSTANCETYPE --resourceNames `hostname`