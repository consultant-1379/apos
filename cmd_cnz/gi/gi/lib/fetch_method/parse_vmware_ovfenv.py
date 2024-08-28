#!/usr/bin/env python
##
# ------------------------------------------------------------------------
#     Copyright (C) 2024 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#   parse_vmware_ovfenv.py
# Description:
#   A python script to extract all the VM configuration data from the OVF ENV
#   XML file available in VMware environment. The path where the file can be
#   found is provided as input argument.
##
# Changelog:
# - Thu Dec 14 2023 - Rajeshwari Padavala (xcsrpad)
#     Modified for Flexible naming for VNF internal networks for DPGs (VMware)
# - Thu March 1 2018 - Anjali M (xanjali)
#     Added checks on number of external network required 
# - Fri Jan 24 2018 - Anjali M (xanjali)
#     Modified with the impacts to support drop2 Network solution.
# - Fri Jan 05 2018 - Chaitanya Sunkara (xchsunk)
#     Modified with the impacts to support vCD networking for vApp networks.
# - Fri May 05 2017 - Usha Manne (xushman)
#     Modified with the impacts for support of additional custom networks.
# - Mon Dec 12 2016 - Alessio Cascone (ealocae)
#     Fixed issue with interfaces name retrieving.
# - Thu Nov 10 2016 - Alessio Cascone (ealocae)
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
MAND_INT_PORTGROUP_LIST=['PORTGROUP_APZ-A' , 'PORTGROUP_APZ-B' , 'PORTGROUP_LDE' ,'PORTGROUP_DRBD' ]  
INT_PORTGROUP_LIST=['PORTGROUP_APZ-A' , 'PORTGROUP_APZ-B' , 'PORTGROUP_LDE' ,'PORTGROUP_DRBD', 'PORTGROUP_INT-SIG' , 'PORTGROUP_AXE-DEF' ,'PORTGROUP_UPD' ,'PORTGROUP_UPD2'  ]  

### BEGIN: Declare Global Lists and variables required
net_name_list = list()
int_net_name_list = list()						  
network_info_list = list()
is_drop2 = False
is_flexible = False
portgroup_dict = {}
portgroup_dict1 = {}
unique_network=set()
missing_portgroup=set()
### END: Global Lists and variables required


#### BEGIN: DEBUG Function #######
def printList(list_to_print):
        for elem in list_to_print:
                print elem

#### END: DEBUG Function #######

# This function prints an error message and exits the script
# with a failure error code.
def abort(msg):
    print "ABORT(" + msg + ")"
    sys.exit(1)

# This function extracts the UUID value and adds it to the input data structure
def extract_uuid(items_list):
    uuid = subprocess.check_output('/usr/sbin/dmidecode -s system-uuid | tr -d [:cntrl:]', shell=True)
    if not uuid:
        abort('Empty value found for UUID!')
    items_list.append('UUID:' + uuid.lower())

# This function extracts the data about the VM properties and network and adds
# the retrieved data to the input data structure.
def extract_properties_and_network_info(xml_file, items_list):
    # Before starting to parse the input XML file, extract the logic names
    # to be used for the networks. The static networks are networks which
    # name MUST end with a specific suffix. The dynamic networks, instead,
    # can have a free name, without any specific suffix.
    static_networks_logic_names = extract_networks_logic_names_from_file(STATIC_NETWORKS_NAMES_CONFIG_FILE)
    dynamic_networks_logic_names = extract_networks_logic_names_from_file(DYNAMIC_NETWORKS_NAMES_CONFIG_FILE)

    # Before starting to parse the input XML file, extract the interfaces names
    # to be used for the networks.
    network_interfaces_names = extract_network_interfaces()

    # Parse the XML file provided as input argument and extract
    # the root <Environment> element
    document = dom.parse(xml_file)
    env_element = document.getElementsByTagName('Environment')[0]

    # Extract the list of the children nodes of the root element of the XML file.
    # When the <PropertySection> and <ve:EthernetAdapterSection> elements are
    # found, extract all the needed data.
    properties_extracted = network_info_extracted = False
    for node in env_element.childNodes:
        if node.nodeName == 'PropertySection':
            properties_extracted = extract_properties(node, items_list)
        elif node.nodeName == 've:EthernetAdapterSection':
            network_info_extracted = extract_network_info(node, items_list, static_networks_logic_names, dynamic_networks_logic_names, network_interfaces_names)

    # Check that all the information was correctly extracted
    if not properties_extracted or not network_info_extracted:
        abort('Some information was not correctly extracted!')

# This function extracts the list of the internal networks to be associated to
# each network interface from the provided input file.
def extract_networks_logic_names_from_file(file):
    names = list()
    config_file = open(file, 'r')
    for line in config_file:
        line = line.strip()
        names.append(line[line.find('=') + 1 : len(line)])
    return names

# This function extracts the list of the interface names to be associated to
# each network interface.
def extract_network_interfaces():
    interfaces = list()
    config_file = open(NETWORK_INTERFACES_NAMES_CONFIG_FILE, 'r')
    for line in config_file:
        interfaces.append(line.strip())
    return interfaces

# This function populates the external_net_list by mapping the port-groups name and
# networks name provided. It is triggered only in case of vCD environment.
# It returns a list in the format : APZ_Network;Portgroup_name;Network_name
# (i.e. CUST1;dvs.VMWARECDR2-aef67569-c636-ce75-aefd87622372;LI)
def populate_external_net_list(portgroup_list, net_name_list):
    ext_net_list = list()
    for portgroup in portgroup_list:
        temp = portgroup.split(':')[0]
        pg_name = portgroup.split(':')[1]
        pg_end_key = temp.rsplit('_', 1)[1]
        for network_name in net_name_list:
            temp1 = network_name.split(':')[0]
            nt_end_key = temp1.rsplit('_',1)[1]
            # For OM we put pg_end_key to OM to match with the
            # nt_end_key .
            if pg_end_key == "OMAPG":
                pg_end_key = "OM"
            if pg_end_key == nt_end_key:
                net_name = network_name.split(':')[1]
                net_name_list.append(net_name)
                ext_net_list.append(pg_end_key + ';' + pg_name + ';' + net_name)
                break
    return ext_net_list

# This function extracts the data about the VM properties and adds it in the
# input data structure.
def extract_properties(element, items_list):
    # All the properties are stored into a <Property> element.
    # Extract all this kind of elements and add their data to the input list.
    global int_portgroup_list						 
    property_found = False
    portgroup_list = list()
    int_portgroup_list = list()						   
    pg_name_list = list()
    int_pg_name_list = list()						 
    nw_name_list = list()

    for property in element.getElementsByTagName('Property'):
        property_name = property.getAttribute('oe:key')
        property_value = property.getAttribute('oe:value')
        items_list.append('PROPERTIES:' + property_name + '=' + property_value)

        # Below code is introduced to retrieve port group names in case of vCD.
        # Save in "portgroup_list" the list of port-group sub-string in format
        # property_name:property_value
        # NOTE: Only the port-groups related to the APG networks are considered
        if "PORTGROUP_CUST" in property_name:
            # Check if the property_value is empty.
            # if empty the property is not added to the portgroup_list
            if property_value:
                portgroup_list.append(property_name + ":" + property_value)
                pg_name_list.append(property_value)
        elif "PORTGROUP_OM" in property_name:
            # Check if the property value is empty.
            # if empty the property is not added to the portgroup_list
            if property_value:
                # For OM we use as internal property_name the string PORTGROUP_OMAPG
                # this to have a length that is aligned to the property name of CUST networks
                portgroup_list.append("PORTGROUP_OMAPG:" + property_value)
                pg_name_list.append(property_value)
                # For the OM network the name is still fixed.
                net_name_list.append("NETWORK_NAME_OM" + ":" + ME_ID + "_OM")
                nw_name_list.append("OM")
                property_found = True
        # Save in "net_name_list" the list of logical network name in format
        # property_name:property_value
        # NOTE: Only the network name related to the APG networks are considered
        elif "NETWORK_NAME_CUST" in property_name:
            # Check if the property_value is empty.
            # if empty the property is not added to the net_name_list
            net_name_list.append(property_name + ":" + property_value)
            if property_value:
                nw_name_list.append(property_value)
        elif property_name in MAND_INT_PORTGROUP_LIST:
            # Check if the property_value is empty.
            # if empty the property is not added to the portgroup_list
            if property_value:                
                int_portgroup_list.append(property_name + ":" + property_value)
                int_pg_name_list.append(property_value)
                portgroup_dict[property_name]=property_value
                portgroup_dict1[property_name]=property_value
            property_found = True

    # Check if the number of PORTGROUP_NAME properties filled match withthe number of
    # NETWORK_NAME properties filled
    if len(pg_name_list) != len(nw_name_list):
        abort('Number of PORTGROUP_NAME properties filled don\'t match with the number of NETWORK_NAME properties filled')
    global NUMBER_OF_PROPERTIES_NETWORK_FILLED
    NUMBER_OF_PROPERTIES_NETWORK_FILLED = len(pg_name_list)
    
    # Check if Port-Group list, int_port-group list and Network name list have duplicated element
    if len(pg_name_list) != len(set(pg_name_list)):
        pg_counter = Counter(pg_name_list)
        pg_dupes = [key for (key,value) in pg_counter.iteritems() if value > 1 and key]
        abort_msg = "Duplicate port-group values found: " + ', '.join(pg_dupes)
        abort(abort_msg)
    if len(int_pg_name_list) != len(set(int_pg_name_list)):
        int_pg_counter = Counter(int_pg_name_list)
        int_pg_dupes = [key for (key,value) in int_pg_counter.iteritems() if value > 1 and key]
        abort_msg = "Duplicate internal network port-group values found: " + ', '.join(int_pg_dupes)
        abort(abort_msg)
    if len(nw_name_list) != len(set(nw_name_list)):
        nw_counter = Counter(nw_name_list)
        nw_dupes = [key for (key,value) in nw_counter.iteritems() if value > 1 and key]
        abort_msg = "Duplicate network name values found: " + ', '.join(nw_dupes)
        abort(abort_msg)

    # If the portgroup_list is empty we assume that the deployment is performed
    # according the DROP1 network solution, therefore is used the old parser algorithm
    # for the APG external networks
    if portgroup_list:
        global is_drop2
        is_drop2 = True
        MIN_DYNAMIC_NETWORKS_REQUIRED = 3
        MAX_DYNAMIC_NETWORKS_ALLOWED = 5
        if len(portgroup_list) < MIN_DYNAMIC_NETWORKS_REQUIRED or len(portgroup_list) > MAX_DYNAMIC_NETWORKS_ALLOWED:
             abort('Incorrect number of dynamic networks found: Maximum Allowed: ' + str(MAX_DYNAMIC_NETWORKS_ALLOWED) + ' Minimum Required: ' + str(MIN_DYNAMIC_NETWORKS_REQUIRED) + ' found ' + str(len(portgroup_list)) + '!')

        # Order the portgroup_list from the longest to the shortest
        portgroup_list.sort(key = lambda portgroup_list: property_value)

        # Fill the global list "network_info_list" with the information related
        # to the PORTGROUP_NAME and NETWORK_NAME fetched from the <PropertySection>
        global network_info_list
        network_info_list = populate_external_net_list(portgroup_list, net_name_list)
    if int_portgroup_list:
        global is_flexible
        is_flexible = True
        if len(portgroup_dict) != len(set(portgroup_dict.values())):
            abort("Portgroup values for internal networks are not unique")
        for portgroup_property in portgroup_dict.keys():
            if portgroup_property in MAND_INT_PORTGROUP_LIST:
                missing_portgroup.add(portgroup_property)

        if (len(missing_portgroup) < 4)  :
            abort("Portgroup values for "+str(set(MAND_INT_PORTGROUP_LIST)-missing_portgroup)+" networks missing")
# Order the int_portgroup_list from the longest to the shortest
          
        int_portgroup_list=sorted(int_portgroup_list,key=lambda x:-len((x.split(":")[1])))
    return property_found

# This function extracts the data about the VM network and adds it in the
# input data structure.
def extract_network_info(element, items_list, static_networks_logic_names, dynamic_networks_logic_names, network_interfaces_names):
    # All the network related information is stored into a <ve:Adapter> element.
    # Extract all this kind of elements and add their data to the input list.
    MAX_DYNAMIC_NETWORKS_ALLOWED = 4
    MIN_DYNAMIC_NETWORKS_REQUIRED = 2
    networks_found = 0
    dynamic_networks = list()
    static_networks = list()						

    #In case of drop2 solution OM network shall be considered as dynamic network
    if is_drop2:
       static_networks_logic_names.remove('OM')

    for adapter in element.getElementsByTagName('ve:Adapter'):
        # Extract MAC address value for this network
        mac_address = adapter.getAttribute('ve:mac')
        if not mac_address:
            abort('Empty MAC address value found!')

        # Extract the name of the network associated to the interface.
        # The retrieved name is something having the following format:
        #     prefix_logicName
        # where 'logicName' is a string identifying the type of traffic for which the
        # network is used, and 'prefix' is a string identifying the vAPZ.
        network_name = adapter.getAttribute('ve:network')
        if not network_name:
            abort('Empty network name value found!')

        # Extract the logic name for the network, using the previously retrieved name
        logic_name = get_ext_network_name(network_name, dynamic_networks_logic_names)
        
        if logic_name:
            # Dynamic network found: save the needed info and go to the next one
            dynamic_networks.append(network_name + ';' + mac_address)
            continue
        else :	  
            if "OM" in network_name:
                # Dynamic network found: save the needed info and go to the next one
                dynamic_networks.append(network_name + ';' + mac_address)
                continue	  
		# Extract the logic name for the network, using the previously retrieved name
        logic_name = get_network_internal_name(network_name, static_networks_logic_names)
        if is_flexible:
			# static network found: save the needed info and go to the next one
            static_networks.append(network_name + ';' + mac_address)
        else: 
			# Append me_id to logicName to get network name for static Networks
			network_name = ME_ID + "_" + logic_name

			# Extract the interface name (in the format ethX) starting from the calculated logic name
			interface_name = get_interface_from_logic_name(logic_name, network_interfaces_names)
			if not interface_name:
				abort('Failed to retrieve the interface name for the name: ' + logic_name)

			# Create the entry into the list of the configuration items
			items_list.append('NETINFO:' + logic_name + ';' + network_name + ';' + interface_name + ';' + mac_address);
			networks_found = networks_found + 1							
    if is_flexible:
       # Sort the list of found static networks, based on the network name
       static_networks.sort(key = len, reverse = True)

       # Extract the information for the internal networks mapped to port groups
       extract_internal_network_info(items_list, static_networks, network_interfaces_names, static_networks_logic_names)
    else:
	# Check that all the mandatory networks were correctly found
       networks_to_find = len(static_networks_logic_names)
       if networks_found != networks_to_find:
            abort('Incorrect number of static networks found: Expected ' + str(networks_to_find) + ' found ' + str(networks_found) + '!')
    # Check that the right number of dynamic networks were found
    dynamic_networks_found = len(dynamic_networks)

    if is_drop2:
        if dynamic_networks_found != NUMBER_OF_PROPERTIES_NETWORK_FILLED:
           abort('Number of port-group found in <EthernetAdapterSection> different from number of networks provided in properties section')
        MIN_DYNAMIC_NETWORKS_REQUIRED = 3
        MAX_DYNAMIC_NETWORKS_ALLOWED = 5
    if dynamic_networks_found < MIN_DYNAMIC_NETWORKS_REQUIRED or dynamic_networks_found > MAX_DYNAMIC_NETWORKS_ALLOWED:
        abort('Incorrect number of dynamic networks found: Maximum Allowed: ' + str(MAX_DYNAMIC_NETWORKS_ALLOWED) + ' Minimum Required: ' + str(MIN_DYNAMIC_NETWORKS_REQUIRED) + ' found ' + str(dynamic_networks_found) + '!')

    # Sort the list of found dynamic networks, based on the network name
    dynamic_networks.sort()

    if is_drop2:
        # Extract the information for the dynamic networks (drop 2 solution)
        extract_dynamic_network_info(items_list, dynamic_networks, network_interfaces_names)

        # Check that the OM network is present in the item_list
        # OM network is a mandatory network for APG. If not present EXIT with error
        om_count = 0
        for item in items_list:
            om_network_name = item.split(';')[0]
            if "NETINFO:OM" == om_network_name:
                om_count += 1
        if om_count != 1:
            abort('OM network not found')
    else:
        # Extract the information for the dynamic networks (drop 1 solution)
        idx = 0
        while idx < dynamic_networks_found:
            logic_name = dynamic_networks_logic_names[idx]
            interface_name = get_interface_from_logic_name(logic_name, network_interfaces_names)
            items = dynamic_networks[idx].split(';')
            network_name = items[0]
            mac_address = items[1]
            items_list.append('NETINFO:' + logic_name + ';' + network_name + ';' + interface_name + ';' + mac_address);
            idx = idx + 1

    return True

# This function extracts the data about the VM external network according the parser algorithm
# to use for drop2 network solution introduced for vCloud Director
# The info extracted are added to the input data structure "items_list"
# - The input parameter "dynamic_network" is a list containing the information about
#   APG external networks extracted from <EternetAdapterSection> of ovf-env.xml file
#   element of this list have the following format:
#   network_name;MAC_addresses
# - The input parameter "network_interfaces_names" contains the interfaces name to
#   associate to the network
def extract_dynamic_network_info(items_list, dynamic_network, network_interfaces_names):

    # Temp list used case multiple port-group found in <EternetAdapterSection>
    matches_found_list = list()

    # Search in the network_info_list
    # The network_info_list contains the info related to the APG external network
    # extracted from the <PropertySection> of ovf-env.xml file
    # The element of this list are in following format:
    # APZ_NAME:PORTGROUP_NAME:NETWORK_NAME (i.e. CUST1:dvs.VDSCDR-2345:CDR1)
    for item in network_info_list:
        #START: Temporary variables
        number_of_matches = 0
        string_to_add = ""
        element_to_remove = ""
        matches_found_list = []
        #END: Temporary variables

        # For each item in network_info_list fetch APZ_NAME, PORTGROUP_SUBSTRING
        # and NETWORK_LOGICAL_NAME
        apz_name = item.split(';')[0]
        pg_subString = item.split(";")[1].encode('UTF8')
        net_name = item.split(';')[2]
        pg_regex_string = r'(.*)' + re.escape(pg_subString.encode('UTF8')) + r'(.*)'

        # Identify in the MAC addresses of PORTGROUP
        for line in dynamic_network:
            if re.search(pg_regex_string, line):
                # Number of matches found
                number_of_matches += 1
                # Store in the temp list the dynamic network that match with the
                # port group sub-string
                matches_found_list.append(line)

                # Start to save (in a temporary variable string_to_add )
                # the information to add in the output struct "items_list"
                # This information will be really stored only in case only
                # one match is found
                logic_name = apz_name
                interface_name = get_interface_from_logic_name(logic_name, network_interfaces_names)
                network_name = net_name
                mac_address = line.split(';')[1]
                string_to_add = 'NETINFO:' + logic_name + ';' + network_name + ';' + interface_name + ';' + mac_address

                # Save in a temporary variable the line of dynamic_network_list
                # that match with the port-group sub-string.
                # In case of only one match is found, this will be removed from
                # the dynamic_network_list to avoid to process it, in the next iteration
                element_to_remove = line

        # Only one match found.
        if number_of_matches == 1:

            # Add the info identified in the previous for in the output structure
            items_list.append(string_to_add)
            # Remove from dynamic_network list the element already processed and
            # stored in the output structure
            dynamic_network.remove(element_to_remove)
        # Multiple matches found
        elif number_of_matches > 1:
            # Re-initialize the temporary variables. Their value is not more valid now
            string_to_add = ""
            element_to_remove = ""

            # Temporary variable
            count = 0

            input_string="-.:;@!'*^$#"
            output_string="@@@@@@@@@@@"
            trantab = maketrans(input_string,output_string)

            for line_match in matches_found_list:
                # Replace any special characters in the port-group sub-string whit
                # the character '@'
                pg_search_pattern = pg_subString.translate(trantab)
                # Fetch only the first part of sub-string
                pg_string = pg_search_pattern.split('@')[0]
                # Define the temporary regExp string to search
                pg_regex_temp = r'(.*)' + pg_string + r'(.*)'

                searchObj = re.search(pg_regex_temp, line_match)
                temp = searchObj.group(2).encode('UTF8').translate(trantab).split('@')[1]
                # Define the new pattern to use
                new_pg_search_pattern = pg_string + "@" + temp
                # Define the regExp string to search
                pg_regex_new = r'\b' + pg_search_pattern + r'\b'

                if re.search(pg_regex_new, new_pg_search_pattern):
                    count += 1

                    # Start to save (in a temporary variable string_to_add )
                    # the information to add in the output struct "items_list"
                    # This information will be really stored only in case only
                    # one match is found
                    logic_name = apz_name
                    interface_name = get_interface_from_logic_name(logic_name, network_interfaces_names)
                    network_name = net_name
                    mac_address = line_match.split(';')[1]
                    string_to_add = 'NETINFO:' + logic_name + ';' + network_name + ';' + interface_name + ';' + mac_address

                    # Save in a temporary variable the line of dynamic_network_list
                    # that match with the port-group sub-string.
                    # In case of only one match is found, this will be removed from
                    # the dynamic_network_list to avoid to process it, in the next iteration
                    element_to_remove = line_match
            if count == 1:
                # Add the info identified in the previous for in the output structure
                items_list.append(string_to_add)
                # Remove from dynamic_network list the element already processed and
                # stored in the output structure
                dynamic_network.remove(element_to_remove)
            else:
                # In case multiple port-groups found in <EternetAdapterSection>
                # the script exit with error.
                abort_msg = "Multiple port-groups found for " + pg_subString + ". Please specify a different sub-string or the exact port-group name."
                abort(abort_msg)
        else:
            # In case no port-group is found in <EternetAdapterSection> the script
            # exit with error.
            abort_msg = "No Port-group found for " + pg_subString + ". Please verify the port-group name on infrastructure and enter the correct value in the property section"
            abort(abort_msg)
    return True		
	
# This function extracts the data about the VM internal network according the parser algorithm
# to use for flexible internal network portroup mapping solution introduced for vmware
# The info extracted are added to the input data structure "items_list"
# - The input parameter "static_network" is a list containing the information about
#   APG internal networks extracted from <EternetAdapterSection> of ovf-env.xml file
#   element of this list have the following format:
#   network_name;MAC_addresses
# - The input parameter "network_interfaces_names" contains the interfaces name to
#   associate to the network
def extract_internal_network_info(items_list, static_network, network_interfaces_names,static_networks_logic_names):
		   
    # Temp list used case multiple port-group found in <EternetAdapterSection>    
    matches_found_list = list()

    # Search in the network_info_list
    # The network_info_list contains the info related to the APG external network
    # extracted from the <PropertySection> of ovf-env.xml file
    # The element of this list are in following format:
    # APZ_NAME:PORTGROUP_NAME:NETWORK_NAME (i.e. CUST1:dvs.VDSCDR-2345:CDR1)
    for item in int_portgroup_list:
        #START: Temporary variables
        number_of_matches = 0
        string_to_add = ""
        element_to_remove = ""
        matches_found_list = []
        #END: Temporary variables
        # For each item in network_info_list fetch APZ_NAME, PORTGROUP_SUBSTRING
        # and NETWORK_LOGICAL_NAME
        apz_name = item.split(':')[0]
       
        pg_subString = item.split(":")[1].encode('UTF8')
        network_name = item.split(':')[0]
        pg_regex_string = r'(.*)' + re.escape(pg_subString.encode('UTF8')) + r'(.*)'
        # Identify in the MAC addresses of PORTGROUP
        for line in static_network:
            if re.search(pg_regex_string, line):
                # Number of matches found
                number_of_matches += 1
                # Store in the temp list the dynamic network that match with the
                # port group sub-string
                matches_found_list.append(line)
                # Start to save (in a temporary variable string_to_add )
                # the information to add in the output struct "items_list"
                # This information will be really stored only in case only
                # one match is found
																					  
                logic_name = get_network_internal_name(network_name, static_networks_logic_names)
                interface_name = get_interface_from_logic_name(logic_name, network_interfaces_names)
                mac_address = line.split(';')[1]
                network_name1 = ME_ID + "_" + logic_name
                string_to_add = 'NETINFO:' + logic_name + ';' + network_name1 + ';' + interface_name + ';' + mac_address
													
																  
														
																		   
	 

                # Save in a temporary variable the line of dynamic_network_list
                # that match with the port-group sub-string.
                # In case of only one match is found, this will be removed from
                # the dynamic_network_list to avoid to process it, in the next iteration
                element_to_remove = line

        # Only one match found.
        if number_of_matches == 1:
											  
															 
						   
							 
											
												
		
																			  
																	  

            # Add the info identified in the previous for in the output structure
            items_list.append(string_to_add)
            # Remove from static_network list the element already processed and
            # stored in the output structure
            static_network.remove(element_to_remove)
        # Multiple matches found
        elif number_of_matches > 1:
            # Re-initialize the temporary variables. Their value is not more valid now
            string_to_add = ""
            element_to_remove = ""

            # Temporary variable
            count = 0

            input_string="-.:;@!'*^$#"
            output_string="@"*len(input_string)
            trantab = maketrans(input_string,output_string)

            for line_match in matches_found_list:
                # Replace any special characters in the port-group sub-string whit
                # the character '@'
                pg_search_pattern = pg_subString.translate(trantab)
                # Fetch only the first part of sub-string
                pg_string = pg_search_pattern.split('@')[0]
                # Define the temporary regExp string to search
                pg_regex_temp = r'(.*)' + pg_string + r'(.*)'

                searchObj = re.search(pg_regex_temp, line_match)
                temp = searchObj.group(2).encode('UTF8').translate(trantab).split('@')[1]
                # Define the new pattern to use
                new_pg_search_pattern = pg_string + "@" + temp
                # Define the regExp string to search
                pg_regex_new = r'\b' + pg_search_pattern + r'\b'

                if re.search(pg_regex_new, new_pg_search_pattern):
                    count += 1

                    # Start to save (in a temporary variable string_to_add )
                    # the information to add in the output struct "items_list"
                    # This information will be really stored only in case only
                    # one match is found
                    logic_name = get_network_internal_name(network_name, static_networks_logic_names)
                    interface_name = get_interface_from_logic_name(logic_name, network_interfaces_names)
                    mac_address = line.split(';')[1]
                    network_name1 = ME_ID + "_" + logic_name
                    string_to_add = 'NETINFO:' + logic_name + ';' + network_name1 + ';' + interface_name + ';' + mac_address

                    # Save in a temporary variable the line of dynamic_network_list
                    # that match with the port-group sub-string.
                    # In case of only one match is found, this will be removed from
                    # the dynamic_network_list to avoid to process it, in the next iteration
                    element_to_remove = line_match
            if count == 1:
                # Add the info identified in the previous for in the output structure
                items_list.append(string_to_add)
                # Remove from static_network list the element already processed and
                # stored in the output structure
                static_network.remove(element_to_remove)
            else:
                # In case multiple port-groups found in <EternetAdapterSection>
                # the script exit with error.
                abort_msg = "Multiple port-groups found for " + pg_subString + ". Please specify a different sub-string or the exact port-group name."
                abort(abort_msg)
        else:
            # In case no port-group is found in <EternetAdapterSection> the script
            # exit with error.
            abort_msg = "No Port-group found for " + pg_subString + ". Please verify the port-group name on infrastructure and enter the correct value in the property section"
            abort(abort_msg)
    return True


# This function extracts the name of the interface from the provided network
# internal name.
def get_interface_from_logic_name(logic_name, network_interfaces_names):
    interface_name = ''
    for name in network_interfaces_names:
        pattern = '_' + logic_name.replace('-', '') + '_'
        if pattern in name:
            interface_name = name[name.find('=') + 1 : len(name)]
    return interface_name

# This function extracts the logic name for the provided network name.
def get_network_internal_name(network_name, network_logic_names):
    internal_name = ''
    for name in network_logic_names:
        if name in network_name:
            internal_name = name
        else : 
             for portgroup_name in portgroup_dict1.keys():
                if portgroup_dict1[portgroup_name] in network_name:
                    internal_name = portgroup_name.rsplit('_', 1)[1]
                    del portgroup_dict1[portgroup_name]
                if internal_name:
                    break
    return internal_name
# This function extracts the logic name for the provided network name for external networks
def get_ext_network_name(network_name, network_logic_names):
    internal_name = ''
    for name in network_logic_names:
        if name in network_name:
            internal_name = name
    return internal_name
# This function extracts me_name property value from xml file.
def extract_meid(file):
    meid = ''
    document = dom.parse(file)
    properties = document.getElementsByTagName('Property')
    for property in properties:
        if property.getAttribute('oe:key') == 'me_name':
            meid = property.getAttribute('oe:value')
    if not meid:
        abort('Empty value found for me_name property')
    return meid


#                                              __    __   _______   _   __    _
#                                             |  \  /  | |  ___  | | | |  \  | |
#                                             |   \/   | | |___| | | | |   \ | |
#                                             | |\  /| | |  ___  | | | | |\ \| |
#                                             | | \/ | | | |   | | | | | | \   |
#                                             |_|    |_| |_|   |_| |_| |_|  \__|

# Check the number of input arguments
if len(sys.argv) != 2:
    abort('Incorrect number of arguments provided')

# First, extract the UUID information
configuration_items = list()
extract_uuid(configuration_items)

# Extract me_name property value from ovf-env.xml file
ME_ID = extract_meid(sys.argv[1])

# Second, extract all the remaining information
extract_properties_and_network_info(sys.argv[1], configuration_items)

# Then, print all the retrieved data to the standard output
for item in configuration_items:
    print item

# End of file
