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
# Script Name: lxd_cont_shell.sh
# Description: This script enables container access over web browser using 
#               shellinabox package 
# Author: Chintamani Bhagwat
# Email : chintamanib@valueaddsofttech.com
################################################################################

# Function for error checking
error_check()
{
    if [ $? -ne 0 ]
    then
	echo 
        echo "ERROR: The script $0 failed at $BASH_COMMAND"
    else
        echo "The script $0 is executed successfully"
    fi
}
trap error_check EXIT
set -e
#set -x
usage()
{
    echo -e "\n\tUsage:"
    echo -e "\tTo enable shell access over web browser"
    echo -e "\t\t./lxd_cont_shell.sh --enable --container <container> --hostport <host port>"
    echo -e "\n\tTo disable shell access over web browser"
    echo -e "\t\t./lxd_cont_shell.sh --disable --container <container>\n"
}

# Checking for number of arguments
if [ $# -lt 5 ]
then
    if [[ "$1" == "--help" || -z "$1" ]]
    then
        usage 
        exit
    else
        usage
        exit 1
    fi
    usage
    exit 1
fi

# Variables 
enableshell=false
disableshell=false

while [ "$1" != "" ]; do
    case $1 in
        --enable )  enableshell=true
                    ;;
        --disable ) disableshell=true
                    ;;
        --container ) shift
                    container=$1
                    ;;
        --hostport )shift
                    hostport=$1
                    ;;
        --help )    echo ""
                    usage
                    exit
                    ;;
        * )         echo ""
                    usage
                    exit 1
    esac
    shift
done

user=root
group=root
shellinabox_pid_dir=./shellinabox/processes

if [[ ( -z $container ) || ( -z $hostport ) ]]
then
    echo -e "ERROR:Missing parameters"
    #usage
    exit
fi

mkdir -p $shellinabox_pid_dir
if [ "$enableshell" == "true" ] 
then
    # Check for existing shellinabox process 
    if ls $shellinabox_pid_dir | grep -w "${container}.pid" >> /dev/null 2>&1; 
    then
        SHELLPID=`cat ${shellinabox_pid_dir}/${container}.pid`
        HOSTPORT=`ps -ef | grep $SHELLPID | awk {'print $17'} | sed '/^$/d' | uniq`
        echo "ERROR: Shell process is already running at $HOSTPORT"
        exit
    fi  

    # Enable shellinabox for container
    contip=`lxc list | grep -w $container | awk {'print $6'}`
    if ipcalc $contip | grep INVALID\ ADDRESS >> /dev/null 2>&1;
    then
        contip=""
    fi
    if [ -z $contip ] 
    then
        echo "ERROR: Unable to get $container IP address";
    else
        #echo "lxc ip address - $contip"
        #{</dev/tcp/localhost/$hostport} >> /dev/null 2>&1       
        if [ $? -eq 0 ]
        then
            echo "ERROR:Host port - $hostport is already in use"
            exit 1
        else
            shellinaboxd -b -u $user -g $group -s /:SSH:$contip -p $hostport --pidfile=${shellinabox_pid_dir}/${container}.pid
            ufw allow $hostport >> /dev/null 2>&1
            echo "SUCCESS: Shell is enabled for $container on host port $hostport"
        fi
    fi
fi
# Disable shellinabox for container
if [ "$disableshell" == "true" ]
then
    if [ -f ${shellinabox_pid_dir}/${container}.pid ]
    then
        pid=`cat ${shellinabox_pid_dir}/${container}.pid`
        #echo "Killing process - $pid"
        kill -9 $pid
    else
        echo "ERROR: $container - shellinabox pidfile not found "
        exit
    fi
    rm ${shellinabox_pid_dir}/${container}.pid
    #echo "Removing entry from $portmappingfile file"
    ufw deny $hostport >> /dev/null 2>&1
    echo "SUCCESS: Shell is disabled for $container"
fi
