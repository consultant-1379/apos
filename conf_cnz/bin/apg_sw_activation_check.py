##
# ------------------------------------------------------------------------
#     Copyright (C) 2018 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apg_sw_activation_check.py
##
# Description:
#       A script to define common functions for apos configuration scripts.
##
# Note:
#       None.
##
# Usage:
#       Check the Usage by running this with --help option
##
# Output:
#       Returns 0 if the software must be activated.
##
# Changelog:
# - Thu Dec 14 2017 - Paolo Elefante, Biagio Maione
#   First version.
#
import sys
import subprocess
import getopt
import yaml

class ExitStatus:
    """Collect all program's exit status codes"""
    #Exit codes
    OK_SW_ACTIVE = 0
    ERROR_SW_NOT_ACTIVE = 1
    INPUT_ERROR = 2
    #Template to provide more details to the user on wrong usage
    INPUT_WARNING_TEMPLATE = """\nMissing operand for option '{0}'.\nTry --help for more information."""

    #Exit code descriptions
    OK_DESCRIPTION = 'if component is active on the given configuration'
    SW_NOT_ACTIVE_DESCRIPTION = 'if component is not active on the given configuration'
    INPUT_ERROR_DESCRIPTION = 'if some of the command arguments is not valid'

class UserInput:
    """Store data provided by the user"""

    command_args    = None
    component_name  = None
    ap_type         = None
    target_env      = None
    sys_type        = None
    verbose_mode    = False

    def __init__(self, arguments):
        """Initialize parameters with the command argument list"""
        self.command_args = arguments
    
    def __del__(self):
        self.command_args = []

    class Options:
        """Collects all command options"""
        MAX_COMMAND_ARGUMENTS = 17

        COMPONENT_NAME = 'c'
        COMPONENT_NAME_LONG = 'component'
        COMPONENT_NAME_HELP = 'NAME'
        COMPONENT_NAME_HELP_DESCRIPTION = 'Mandatory. Exact component name. E.g: ADHBIN'

        AP_TYPE = 'a'
        AP_TYPE_LONG = 'ap'
        AP_TYPE_HELP = 'TYPE'
        AP_TYPE_HELP_DESCRIPTION = 'Optional. AP Type. E.g: AP1'

        TARGET_ENV = 't'
        TARGET_ENV_LONG = 'target'
        TARGET_ENV_HELP = 'ENVIRONMENT'
        TARGET_ENV_HELP_DESCRIPTION = 'Deprecated. It is ignored. Target Environment. E.g: virtual, GEP2'

        HELP = 'h'
        HELP_LONG = 'help'
        HELP_DESCRIPTION = 'display this help and exit'
        
        VERBOSE = 'v'
        VERBOSE_LONG = 'verbose'
        VERBOSE_DESCRIPTION = 'Optional. Enable verbose mode'

        SHORT_OPTION_ARGUMENT_REQUIRED = ':'
        LONG_OPTION_ARGUMENT_REQUIRED = '='

        SHORT_OPTION_LIST = COMPONENT_NAME + SHORT_OPTION_ARGUMENT_REQUIRED + \
                            AP_TYPE + SHORT_OPTION_ARGUMENT_REQUIRED + \
                            TARGET_ENV + SHORT_OPTION_ARGUMENT_REQUIRED + \
                            HELP + VERBOSE

        LONG_OPTION_LIST = [COMPONENT_NAME_LONG+LONG_OPTION_ARGUMENT_REQUIRED, \
                            AP_TYPE_LONG+LONG_OPTION_ARGUMENT_REQUIRED, \
                            TARGET_ENV_LONG+LONG_OPTION_ARGUMENT_REQUIRED, \
                            HELP_LONG+LONG_OPTION_ARGUMENT_REQUIRED, \
                            HELP_LONG, VERBOSE_LONG]

    def parse(self):
        """Parse command line arguments and set connection data"""
        try:
            opts, args = getopt.getopt(self.command_args, UserInput.Options.SHORT_OPTION_LIST, UserInput.Options.LONG_OPTION_LIST)
        except getopt.GetoptError as err:
            raise RuntimeError(err)

        for option, value in opts:
            if option in ('-' + UserInput.Options.HELP, '--' + UserInput.Options.HELP_LONG):
                self.usage()
                sys.exit(ExitStatus.OK_SW_ACTIVE)
            if option in ('-' + UserInput.Options.VERBOSE, '--' + UserInput.Options.VERBOSE_LONG):
                self.verbose_mode = True

            elif option in ('-' + UserInput.Options.COMPONENT_NAME, '--' + UserInput.Options.COMPONENT_NAME_LONG):
                if len(value) == 0:
                    raise Warning(ExitStatus.INPUT_WARNING_TEMPLATE.format('-%s|--%s' % (UserInput.Options.COMPONENT_NAME, UserInput.Options.COMPONENT_NAME_LONG)))
                self.component_name = value

            elif option in ('-' + UserInput.Options.AP_TYPE, '--' + UserInput.Options.AP_TYPE_LONG):
                if len(value) == 0:
                    raise Warning(ExitStatus.INPUT_WARNING_TEMPLATE.format('-%s|--%s' % (UserInput.Options.AP_TYPE, UserInput.Options.AP_TYPE_LONG)))
                self.ap_type = value
            elif option in ('-' + UserInput.Options.TARGET_ENV, '--' + UserInput.Options.TARGET_ENV_LONG):
                #Ignoring target env
                self.target_env = None
                #if len(value) == 0:
                #    raise Warning(ExitStatus.INPUT_WARNING_TEMPLATE.format('-%s|--%s' % (UserInput.Options.TARGET_ENV, UserInput.Options.TARGET_ENV_LONG)))
                #self.target_env = value
            else:
                # NOTE: if an option does not exist getopt fails and raises RuntimeError exception
                #       This branch is for options present in the lists UserInput.Options.SHORT_OPTION_LIST and LONG_OPTION_LIST
                error_description = "Option \"%s\" not implemented yet." % (option)
                raise NotImplementedError(error_description)

    def fetchMissingInputs(self):
        SMX_SHELF_ARCHITECTURE = 'SMX'
        SCX_SHELF_ARCHITECTURE = 'SCX'
        GEP7_HW_TYPE = 'GEP7'

        if self.ap_type is None:
            #process = subprocess.Popen(["/opt/ap/apos/bin/parmtool/parmtool get --item-list ap_type | awk -F\'=\' \'{print $2}\'"], stdout=subprocess.PIPE, shell=True)
            process = subprocess.Popen(["cat /storage/system/config/apos/aptype.conf"], stdout=subprocess.PIPE, shell=True)

            (out, err) = process.communicate()
            self.ap_type = out.split()[0]

        if self.target_env is None:
            #process = subprocess.Popen(["/opt/ap/apos/bin/parmtool/parmtool get --item-list installation_hw | awk -F\'=\' \'{print $2}\'"], stdout=subprocess.PIPE, shell=True)
            process = subprocess.Popen(["cat /storage/system/config/apos/installation_hw"], stdout=subprocess.PIPE, shell=True)
            (out, err) = process.communicate()
            hw_type = out.split()[0].split("_")[0]
            if hw_type.startswith('GEP7') is True:
                hw_type = "GEP7"

            #Note: for vAPG hw_type is set to 'VM'
            self.target_env = hw_type

            #process = subprocess.Popen(["/opt/ap/apos/bin/parmtool/parmtool get --item-list shelf_architecture | awk -F\'=\' \'{print $2}\'"], stdout=subprocess.PIPE, shell=True)
            process = subprocess.Popen(["cat /storage/system/config/apos/shelf_architecture"], stdout=subprocess.PIPE, shell=True)
            (out, err) = process.communicate()
            shelf_type = out.split()[0]
            if shelf_type == SMX_SHELF_ARCHITECTURE:
                self.target_env += shelf_type
            if shelf_type == SCX_SHELF_ARCHITECTURE and hw_type == GEP7_HW_TYPE:
                self.target_env += shelf_type
         
        if self.sys_type is None:
            process = subprocess.Popen(["cat /storage/system/config/apos/system_type"], stdout=subprocess.PIPE, shell=True)
            (out, err) = process.communicate()

            if (out != ""):
                self.sys_type = out.split()[0]
            else:
                process = subprocess.Popen(["/usr/bin/immlist -a systemType axeFunctionsId=1"], stdout=subprocess.PIPE, shell=True)
                (out, err) = process.communicate()
                system_type = out.split("=")[1].rstrip('\n')
                if system_type == "1":
                    self.sys_type = "MCP"
                elif system_type == "0":
                    self.sys_type = "SCP"

    def usage(self):
        """Print command usage"""
        usage_output = 'Usage: {0} OPTION...\n{1}\n\n{2:40}{3}\n{4:40}{5}\n{6:40}{7}\n{8:40}{9}\n{10:40}{11}\n'.format(sys.argv[0],
            ('Check if the given component name has to be activated on the specified AP system and target environment'),
            (('  -%s, --%s=%s') % (UserInput.Options.COMPONENT_NAME, UserInput.Options.COMPONENT_NAME_LONG, UserInput.Options.COMPONENT_NAME_HELP)),
            UserInput.Options.COMPONENT_NAME_HELP_DESCRIPTION,
            (('  -%s, --%s=%s') % (UserInput.Options.AP_TYPE, UserInput.Options.AP_TYPE_LONG, UserInput.Options.AP_TYPE_HELP)),
            UserInput.Options.AP_TYPE_HELP_DESCRIPTION,
            (('  -%s, --%s=%s') % (UserInput.Options.TARGET_ENV, UserInput.Options.TARGET_ENV_LONG, UserInput.Options.TARGET_ENV_HELP)),
            UserInput.Options.TARGET_ENV_HELP_DESCRIPTION,
            (('  -%s, --%s') % (UserInput.Options.HELP, UserInput.Options.HELP_LONG)),
            UserInput.Options.HELP_DESCRIPTION,
            (('  -%s, --%s') % (UserInput.Options.VERBOSE, UserInput.Options.VERBOSE_LONG)),
            UserInput.Options.VERBOSE_DESCRIPTION)

        exit_status_description = 'Exit status:\n   {0:5}{1},\n   {2:5}{3},\n   {4:5}{5}'.format(('%i' % ExitStatus.OK_SW_ACTIVE), ('%s' % ExitStatus.OK_DESCRIPTION),
            ('%i' % ExitStatus.ERROR_SW_NOT_ACTIVE), ('%s' % ExitStatus.SW_NOT_ACTIVE_DESCRIPTION),
            ('%i' % ExitStatus.INPUT_ERROR), ('%s' % ExitStatus.INPUT_ERROR_DESCRIPTION))

        example_usage = """Example:\n  {0} -c ADHBIN -a AP1 -t GEP5\n""".format(sys.argv[0])

        print('\n' + usage_output + '\n' + example_usage + '\n' + exit_status_description)


class ApgEnvironmentMap:
    """  """
    YAML_ENTRY_COMPONENTS = "components"
    YAML_ENTRY_KEY_COMPONENT_NAME = "name"
    YAML_ENTRY_KEY_AP_TYPE = "aptype"
    YAML_ENTRY_KEY_TARGET_ENV = "targetenv"
    YAML_ENTRY_KEY_TARGET_SYS_TYPE = "systype"

    m_doc = None

    def __init__(self):
        m_doc = None
        
    def __del__(self):
        m_doc = None

    def load(self, filename):
        """Load apg_sw_activation_table.yaml in m.doc"""
        with open(filename, 'r') as configFile:
            self.m_doc = yaml.safe_load(configFile)
            #print(yaml.dump(self.m_doc, default_flow_style = False))

    def getComponent(self, name):
        """ Build and returns a YamlComponent object that maps file entry """
        if self.m_doc == None:
            return None

        componentArray = self.m_doc[self.YAML_ENTRY_COMPONENTS]
        for singleComponent in componentArray:
            singleComponentName = singleComponent[self.YAML_ENTRY_KEY_COMPONENT_NAME]
            if singleComponentName.upper() == name.upper():
                singleComponentApTypeArray = singleComponent[self.YAML_ENTRY_KEY_AP_TYPE]
                singleComponentTargetEnvArray = singleComponent[self.YAML_ENTRY_KEY_TARGET_ENV]
                if self.YAML_ENTRY_KEY_TARGET_SYS_TYPE in singleComponent:
                    singleComponentSystemTypeArray = singleComponent[self.YAML_ENTRY_KEY_TARGET_SYS_TYPE]
                    yamlComponent = YamlComponent(singleComponentName, singleComponentApTypeArray, singleComponentTargetEnvArray, singleComponentSystemTypeArray)
                else:
                    yamlComponent = YamlComponent(singleComponentName, singleComponentApTypeArray, singleComponentTargetEnvArray)
                return yamlComponent
        
        return None

    def getYamlComponentList(self):
        """this function build and returns a YamlComponent object that maps file entry """
        if self.m_doc == None:
            return None

        yamlComponentList = list()

        componentArray = self.m_doc[self.YAML_ENTRY_COMPONENTS]
        for singleComponent in componentArray:
            singleComponentName = singleComponent[self.YAML_ENTRY_KEY_COMPONENT_NAME]
            singleComponentApTypeArray = singleComponent[self.YAML_ENTRY_KEY_AP_TYPE]
            singleComponentTargetEnvArray = singleComponent[self.YAML_ENTRY_KEY_TARGET_ENV]
            if self.YAML_ENTRY_KEY_TARGET_SYS_TYPE in singleComponent:
                singleComponentSystemTypeArray = singleComponent[self.YAML_ENTRY_KEY_TARGET_SYS_TYPE]
                yamlComponent = YamlComponent(singleComponentName, singleComponentApTypeArray, singleComponentTargetEnvArray, singleComponentSystemTypeArray)
            else:
                yamlComponent = YamlComponent(singleComponentName, singleComponentApTypeArray, singleComponentTargetEnvArray)

            yamlComponentList.append(yamlComponent)
        
        return yamlComponentList

class YamlComponent:
    """APG Component defined in yaml configuration file."""
    m_name = None
    m_apTypeArray = None
    m_targetEnvArray = None
    m_sysTypeArray = None

    def __init__(self, name, apTypeArray, targetEnvArray, sysTypeArray=None):
        self.m_name = name
        self.m_apTypeArray = apTypeArray
        self.m_targetEnvArray = targetEnvArray
        self.m_sysTypeArray = sysTypeArray

    def __del__(self):
        pass

    def getName(self):
        """Get the component name."""
        return self.m_name

    def getSupportedApTypes(self):
        """Get supported AP Types."""
        return self.m_apTypeArray

    def getSupportedTargets(self):
        """Get supported targets."""
        return self.m_targetEnvArray

    def getSupportedSysTypes(self):
        """Get supported system types"""
        return self.m_sysTypeArray


    def hasApType(self, name):
        """ Check entry AP type 
            Returns Boolean found  
        """
        found = False
        for entry in self.m_apTypeArray:
            if entry.upper() == name.upper():
                found = True
                break 
        return found

    def hasTargetenv(self, name):
        """ Check entry Target Environment 
            Returns Boolean found  
        """
        found = False
        for entry in self.m_targetEnvArray:
            if entry.upper() == name.upper():
                found = True
                break 
        return found

    def hasSysType(self,name):
        found = False
        if self.m_sysTypeArray == None:
            found = True
        else:
            for entry in self.m_sysTypeArray:
                if entry.upper() == name.upper():
                    found = True
                    break
        return found


    def isSysTypePresent(self):
        if self.m_sysTypeArray == None:
           return False
        else:
           return True


##########################################################
def main():
    #
    # Fetch target environments (AP type and HW/environemnt type), to be developed
    # 
    cmd_input = UserInput(sys.argv[1:])
    try:
        cmd_input.parse()
    except (Warning, NotImplementedError) as warn:
        print("%s: %s" % (warn.__class__.__name__, warn))
        sys.exit(ExitStatus.INPUT_ERROR)
    except (RuntimeError, ValueError) as err:
        cmd_input.usage()
        sys.exit(ExitStatus.INPUT_ERROR)
    
    #Fetch from local node ap type, hw type and shelf architecture, system_type
    cmd_input.fetchMissingInputs()

    #
    #Parse the apg_sw_activation_table.yaml
    #
    apg_conf = ApgEnvironmentMap()

    FILEPATH_OF_APG_SW_ACTIVATION_TABLE = '/opt/ap/apos/conf/'
    FILENAME_APG_SW_ACTIVATION_TABLE = 'apg_sw_activation_table.yaml' 
    apg_conf.load(FILEPATH_OF_APG_SW_ACTIVATION_TABLE + FILENAME_APG_SW_ACTIVATION_TABLE)

    #
    #Get Yaml Component : Component name, AP type, Target Environment 
    #
    component = apg_conf.getComponent(cmd_input.component_name)

    #
    #Returns proper exit code whether the Component has to be activated or  
    #checking the Yaml component info against the fetched AP type and Target environemt 
    #
    if component == None:
        print("error: component " + cmd_input.component_name + " not found")
        sys.exit(ExitStatus.ERROR_SW_NOT_ACTIVE)

    else:
        apTypeFound = component.hasApType(cmd_input.ap_type)
        if apTypeFound is True:
            targetenvFound = component.hasTargetenv(cmd_input.target_env)
            if targetenvFound is True:
                # Check a special case
                if cmd_input.ap_type == "AP2"	and cmd_input.target_env == "VM":
                    print("error: component " + cmd_input.component_name + " not found")
                    sys.exit(ExitStatus.ERROR_SW_NOT_ACTIVE)

                if component.isSysTypePresent():
                    sysTypeFound = component.hasSysType(cmd_input.sys_type)
                    if sysTypeFound is False:
                        print ("error: System type " + cmd_input.sys_type + " not found")
                        sys.exit(ExitStatus.ERROR_SW_NOT_ACTIVE)

                # Check if component is locked
                process = subprocess.Popen(["python /opt/ap/apos/bin/apg-adm.py -g locked"], stdout=subprocess.PIPE, shell=True)
                (out,err) = process.communicate()
                print(out)
                if cmd_input.component_name in out:
                    print("component is locked: SW NOT to be activated")
                    #Return exit code : 1 (SW NOT to be activated)
                    sys.exit(ExitStatus.ERROR_SW_NOT_ACTIVE)
                else:
                    # Return exit code : 0 (SW to be activated)
                    print ("component = " + cmd_input.component_name + " to be activated on " + cmd_input.ap_type + " and " + cmd_input.target_env)
                    sys.exit(ExitStatus.OK_SW_ACTIVE)
            else:
                print ("error: target " + cmd_input.target_env + " not found")
                # Return exit code : 1 (SW NOT to be activated)
                sys.exit(ExitStatus.ERROR_SW_NOT_ACTIVE)
        else:
            print ("error: AP type " + cmd_input.ap_type + " not found")
            # Return exit code : 1 (SW NOT to be activated)
            sys.exit(ExitStatus.ERROR_SW_NOT_ACTIVE)

##########################################################
################## SCRIPT EXECUTION ######################
main()
##########################################################
