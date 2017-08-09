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
# Script Name: lxdops_deps.sh
# Description: This script will install all required packages 
# Author: Chintamani Bhagwat
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

#apt-get update
which ipcalc || apt-get install ipcalc -y
which shellinaboxd || apt-get install shellinabox -y
which rinetd || apt-get install rinetd -y 
