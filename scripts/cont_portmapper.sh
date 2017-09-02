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
# Script Name: cont_portmapper.sh
# Description: This script provides following functions
#               - Adding lxc container port to host port mapping
#               - Removing lxc container port to host port mapping
#               - Listing all current lxc container to host port mappings
# Author: Chintamani Bhagwat
# Email : chintamanib@valueaddsofttech.com
################################################################################

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


# Functions 
usage()
{
    echo -e "\n\tUsage : "
    echo -e "\t--list"
    echo -e "\t\tTo list all port mappings "
    echo -e "\n\t--add"
    echo -e "\t\tTo add port mapping. This needs additional parameters as listed below, "
    echo -e "\t\t--container <Container name>\n\t\t--contport <Container Port>\n\t\t--hostport <Host Port>\n\t\t--portdesc \"<Add port description>\""
    echo -e "\n\t--remove"
    echo -e "\t\tTo remove port mapping. This needs additional parameters as listed below, "
    echo -e "\t\t--container <Container name>\n\t\t--contport <Container Port>\n\t\t--hostport <Host Port>"
    #echo "ERROR:Incorrect Syntax"
    exit
}

# Checking for number of arguments 
if [ $# -lt 1 ]
then
	usage
    exit 1
else
    if [ "$1" == "--help" ]
    then
        usage
        exit
    fi
fi

addmapping=false
removemapping=false

while [ "$1" != "" ]; do
    case $1 in
        --add )     addmapping=true
                    ;;
        --remove )  removemapping=true
                    ;;
        --container )   shift
                    container=$1
                    ;;
        --contport ) shift
                    contport=$1
                    ;;
        --hostport ) shift
                    hostport=$1
                    ;;   
        --portdesc ) shift
                    portdesc=$1
                    ;;
        --list )    listmappings=true
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

# Check if container exists
container_status()
{
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
}



# To add port mapping 
if [ "$addmapping" == "true" ]
then
    container_status
    if </dev/tcp/localhost/$hostport >> /dev/null 2>&1;
    then
        echo "ERROR:Host port is already in use"
        exit 1
    fi
    contip=`lxc list | grep -w $container | awk {'print $6'}`
    if ipcalc $contip | grep INVALID\ ADDRESS >> /dev/null 2>&1; 
    then
        contip=""
    fi
        
    #echo "Adding port mapping "
    if [[ ( -z $contip ) || ( -z $contport) || ( -z $hostport ) ]]
    then
        echo -e "ERROR:Missing parameters"
        exit 1
        #usage
    fi 
    if  cat /etc/rinetd.conf | grep -w $contip | grep -w $contport >> /dev/null 2>&1;
    then
        echo "ERROR:Container port $contport is already in use"
        exit 1
    fi
    if cat /etc/rinetd.conf | grep 0.0.0.0 | awk {'print $2'} | grep -w $hostport >> /dev/null 2>&1 ;
    then
        echo "ERROR:Host port $hostport is already in use"
        exit 1
    fi
    echo "0.0.0.0 $hostport $contip $contport \"$portdesc\"" >> /etc/rinetd.conf 
    ufw allow $hostport >> /dev/null 2>&1
    systemctl restart rinetd.service >> /dev/null 2>&1
    echo "SUCCESS:Port mapping added successfully"
fi

# To remove port mapping 
if [ "$removemapping" == "true" ]
then
    container_status
    contip=`lxc list | grep -w $container | awk {'print $6'}`
    #echo "Removing port mapping"
    if [[ ( -z $contip ) || ( -z $contport ) || ( -z $hostport ) ]]
    then
        echo -e "ERROR:Missing parameters"
        #usage
        exit 1
    fi
    if  cat /etc/rinetd.conf | grep -w $contip | grep -w $contport >> /dev/null 2>&1;
    then
        echo ""
        sed '/'"$contip"'\ '"$contport"'/d' -i /etc/rinetd.conf
        ufw deny $hostport
        systemctl restart rinetd.service
        echo "SUCESS:Port mapping removed successfully"
    else
        echo "ERROR:LXC Port mapping not found "
        exit 1
    fi
fi 

if [ "$listmappings" == "true" ]
then
    cat /etc/rinetd.conf | grep 0.0.0.0
fi

# Write mappings to port_mapping.txt file 
#sed '/portforwarding/d' -i $portmappingfile
#cat /etc/rinetd.conf | grep 0.0.0.0 | sed 's/^/portforwarding\ /g' >> $portmappingfile
#for IP in `cat /etc/rinetd.conf | grep 0.0.0.0 | awk {'print $3'}`
#do
#    if lxc list | grep $IP >> /dev/null 2>&1;
#    then
#
#        CNTRNAME=`lxc list | grep $IP | awk {'print $2'}`
#        sed 's/'"$IP"'/'"$CNTRNAME"'/g' -i $portmappingfile
#    else
#        sed '/'"$IP"'/d' -i $portmappingfile
#    fi
#done
#sed 's/\ /:/g' -i $portmappingfile


