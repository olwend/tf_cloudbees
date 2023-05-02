#!/bin/bash

### YUM INSTALL GIT ###
    echo "Installing Git"
    yum install git -y 
    echo "$(git --version) is installed"