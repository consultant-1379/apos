#!/usr/bin/env python
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#   parse_vmware_ovfenv.py
# Description:
#   A python script to extract all the VM configuration data from the user_data
#   file available in openstack environment. The path where the file can be
#   found is provided as input argument.
##
# Changelog:
# - Tue Oct 23 2018 - Pranshu Sinha (XPRANSI)
#     Changed as per HOT changes due to PC-APZ comments.
# - Tue Sep 18 2018 - Bavana Harika (XHARBAV)
#     First version.
##

import subprocess
import sys
import xml.dom.minidom as dom
import re
from string import maketrans
from collections import Counter

### BEGIN: Common variables
GETINFO_COMMON_FOLDER = '/opt/ap/apos/bin/gi/lib/common'
STATIC_NETWORKS_NAMES_CONFIG_FILE = GETINFO_COMMON_FOLDER + '/staticNetworks'
DYNAMIC_NETWORKS_NAMES_CONFIG_FILE = GETINFO_COMMON_FOLDER + '/dynamicNetworks'
NETWORK_INTERFACES_NAMES_CONFIG_FILE = GETINFO_COMMON_FOLDER + '/networkInterfaces'
ME_ID = ''
###   END: Common variables

# This function prints an error message and exits the script
# with a failure error code.
def abort(msg):
    print "ABORT(" + msg + ")"
    sys.exit(1)

# This function extracts user_data property value from xml file.
def extract_data(file, items_list):
    INSTANCE_NAME = extract_instancename(file)
    document = dom.parse(file)
    properties = document.getElementsByTagName('Property')
    for property in properties:
    	interface_name = ''
    	interface_value = ''
	nic_value = ''
        property_name = property.getAttribute('oe:key')
        property_value = property.getAttribute('oe:value')
	if (property_name.find("MAC") == -1) and (property_name.find("vnic") == -1) :
            items_list.append(property_name + '=' + property_value)
	if (property_name.find("MAC") != -1):
	    interface_name = property_name.split('_')[1]
	    subproperties = document.getElementsByTagName('Property')
	    for subproperty in subproperties:
	        if subproperty.getAttribute('oe:key') == 'net_'+interface_name.lower():
	            interface_value = subproperty.getAttribute('oe:value')		
	        if subproperty.getAttribute('oe:key') == 'vnic_'+interface_name.lower():
	            nic_value = subproperty.getAttribute('oe:value')
		if interface_value and nic_value:
                    if ( (property_name.find("AP-A") != -1) and (INSTANCE_NAME.find("AP-A_VM") != -1) ) or ( (property_name.find("AP-B") != -1) and (INSTANCE_NAME.find("AP-B_VM") != -1) ) :
		        items_list.append('mac=' + property_value + ',network=' + interface_value + ',vnic=' + nic_value)		
    		        interface_value = ''
		        nic_value = ''
					
			
# This function extracts Instance Name  value from xml file.
def extract_instancename(file):
    instanceName = ''
    document = dom.parse(file)
    properties = document.getElementsByTagName('Property')
    for property in properties:
        if property.getAttribute('oe:key') == 'AP_VM':
            instanceName = property.getAttribute('oe:value')
    if not instanceName:
        abort('Empty value found for instanceName property')
    return instanceName


		
def extract_network_interfaces():
    interfaces = list()
    config_file = open(NETWORK_INTERFACES_NAMES_CONFIG_FILE, 'r')
    for line in config_file:
        interfaces.append(line.strip())
    return interfaces



#                                              __    __   _______   _   __    _
#                                             |  \  /  | |  ___  | | | |  \  | |
#                                             |   \/   | | |___| | | | |   \ | |
#                                             | |\  /| | |  ___  | | | | |\ \| |
#                                             | | \/ | | | |   | | | | | | \   |
#                                             |_|    |_| |_|   |_| |_| |_|  \__|

# Check the number of input arguments
if len(sys.argv) != 2:
    abort('Incorrect number of arguments provided')
configuration_items = list()
# Extract me_name property value from user_data file
extract_data(sys.argv[1], configuration_items )


# Then, print all the retrieved data to the standard output
for item in configuration_items:
    print item

# End of file

