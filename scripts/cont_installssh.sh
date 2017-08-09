#!/bin/bash

# This script is part of "lxdops" 
# Copyright (C) 2017 Chintamani Bhagwat
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

################################################################################
# Script Name: cont_installssh.sh
# Description: This script install ssh server on container and enables ssh
# Author: Chintamani Bhagwat
################################################################################

# Supported osfamily list - 
#   centos
#   ubuntu
#   debian
#   alpine

# Initiating variables
DEFAULTPASS="LXD1234"

# Function for error checking 
error_check()
{
    if [ $? -ne 0 ]
    then
        echo "ERROR: The script $0 failed at $BASH_COMMAND"
    else
        echo "The script $0 is executed successfully"
    fi
}
trap error_check EXIT
set -e 

# Print help for usage 
usage()
{
        echo "Usage:"
        echo -e "  ./cont_installssh.sh --container <container> --osfamily <OSfamily>"
        echo -e "  Supported OS families - centos,ubuntu,debian,alpine"
        echo ""
}

# Checking number of parameters
if [ $# -lt 4 ]
then
    if [ "$1" == "--help" ]
    then
        usage 
        exit
    else
        usage
        exit 1
    fi 
fi


while [ "$1" != "" ]
do
    case $1 in
        --container )     shift
                        container=$1
                        ;;
        --osfamily )    shift
                        osfamily=$1
                        ;;
        * )             usage
                        exit 1
    esac
    shift
done

# Check if container exists 
if lxc list | grep -w $container >> /dev/null 2>&1;
then
    echo "Container $container exists "
    if lxc list | grep -w $container | grep RUNNING >> /dev/null 2>&1;
    then
         echo "Container $container is up "
    else 
         echo "ERROR: Container $container is not running"
         exit 1 
    fi
else
    echo "ERROR: Container $container does not exits"
    exit 1
fi


# Enabling ssh on centos
#lxc exec $container -- cat /etc/*release | grep -i centos >> /dev/null 2>&1
#if [ $? -eq 0 ]
OSNOTFOUND=0
if [ "$osfamily" == "centos" ]
then
    #lxc exec $container -- yum install epel-release -y >> /dev/null 2>&1
    lxc exec $container -- yum install openssh-server -y >> /dev/null 2>&1
    lxc exec $container -- chkconfig sshd on >> /dev/null 2>&1
    #lxc exec $lxdhost -- sed '/UseDNS/c\UseDNS\ no' -i /etc/ssh/sshd_config
    lxc exec $container -- service sshd start >> /dev/null 2>&1
    lxc exec $container -- chpasswd  < <(echo "root:${DEFAULTPASS}") >> /dev/null 2>&1
    exit
elif [ "$osfamily" == "ubuntu" -o "$osfamily" == "debian" ]
then
    lxc exec $container -- apt-get update >> /dev/null 2>&1
    lxc exec $container -- apt-get install openssh-server -y >> /dev/null 2>&1
    #lxc exec $lxdhost -- sed '/UseDNS/c\UseDNS\ no' -i /etc/ssh/sshd_config
    lxc exec $container -- service ssh start  >> /dev/null 2>&1
    lxc exec $container -- update-rc.d ssh defaults >> /dev/null 2>&1
    lxc exec $container --  chpasswd  < <(echo "root:${DEFAULTPASS}") >> /dev/null 2>&1
    exit
elif [ "$osfamily" == "alpine" ]
then
    lxc exec $container -- apk update >> /dev/null 2>&1
    lxc exec $container -- apk add openssh >> /dev/null 2>&1
    lxc exec $container -- apk add bash >> /dev/null 2>&1
    #lxc exec $lxdhost -- sed '/UseDNS/c\UseDNS\ no' -i /etc/ssh/sshd_config
    lxc exec $container -- /etc/init.d/sshd start >> /dev/null 2>&1
    lxc exec $container -- chpasswd  < <(echo "root:${DEFAULTPASS}") >> /dev/null 2>&1
    exit
else
    echo "OS Family is not supported. Supported OS families - centos,ubuntu,debian,alpine"
    exit 1 
fi
