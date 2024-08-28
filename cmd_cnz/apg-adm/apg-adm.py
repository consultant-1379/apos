#!/usr/bin/python

import sys
import subprocess
import getopt
import yaml

class ExitStatus:
    """Collect all program's exit status codes"""
    #Exit codes
    SUCCESS = 0
    FAILURE = 1
    INPUT_ERROR = 2
    #Template to provide more details to the user on wrong usage
    INPUT_WARNING_TEMPLATE = """\nMissing operand for option '{0}'.\nTry --help for more information."""

    #Exit code descriptions
    OK_DESCRIPTION = 'Success'
    FAILURE_DESCRIPTION = 'Failure'
    INPUT_ERROR_DESCRIPTION = 'Invalid parameters'

class UserInput:
    """Store data provided by the user"""

    command_args        = None
    component_status    = None
    component_to_lock   = None
    component_to_unlock = None
    verbose_mode        = False

    def __init__(self, arguments):
        """Initialize parameters with the command argument list"""
        self.command_args = arguments
    
    def __del__(self):
        self.command_args = []

    class Options:
        """Collects all command options"""
        MAX_COMMAND_ARGUMENTS = 17

        GET_INFO = 'g'
        GET_INFO_LONG = 'get'
        GET_INFO_HELP = 'active|passive|locked'
        GET_INFO_HELP_DESCRIPTION = 'List all components having the given status:'

        LOCK = 'l'
        LOCK_LONG = 'lock'
        LOCK_HELP = '<COMPONENT>'
        LOCK_HELP_DESCRIPTION = 'Package name as reported in swrprint.'

        UNLOCK = 'u'
        UNLOCK_LONG = 'unlock'
        UNLOCK_HELP = '<COMPONENT>'
        UNLOCK_HELP_DESCRIPTION = 'Package name as reported in swrprint.'

        HELP = 'h'
        HELP_LONG = 'help'
        HELP_DESCRIPTION = 'Display this help and exit.'
        
        VERBOSE = 'v'
        VERBOSE_LONG = 'verbose'
        VERBOSE_DESCRIPTION = 'Optional. Execute command in VERBOSE mode.'

        SHORT_OPTION_ARGUMENT_REQUIRED = ':'
        LONG_OPTION_ARGUMENT_REQUIRED = '='

        SHORT_OPTION_LIST = GET_INFO + SHORT_OPTION_ARGUMENT_REQUIRED + \
                            LOCK + SHORT_OPTION_ARGUMENT_REQUIRED + \
                            UNLOCK + SHORT_OPTION_ARGUMENT_REQUIRED + \
                            HELP + VERBOSE

        LONG_OPTION_LIST = [GET_INFO_LONG+LONG_OPTION_ARGUMENT_REQUIRED, \
                            LOCK_LONG+LONG_OPTION_ARGUMENT_REQUIRED, \
                            UNLOCK_LONG+LONG_OPTION_ARGUMENT_REQUIRED, \
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
                sys.exit(ExitStatus.SUCCESS)
            if option in ('-' + UserInput.Options.VERBOSE, '--' + UserInput.Options.VERBOSE_LONG):
                self.verbose_mode = True

            elif option in ('-' + UserInput.Options.GET_INFO, '--' + UserInput.Options.GET_INFO_LONG):
                if len(value) == 0:
                    raise Warning(ExitStatus.INPUT_WARNING_TEMPLATE.format('-%s|--%s' % (UserInput.Options.GET_INFO, UserInput.Options.GET_INFO_LONG)))
                self.component_status = value

            elif option in ('-' + UserInput.Options.LOCK, '--' + UserInput.Options.LOCK_LONG):
                if len(value) == 0:
                    raise Warning(ExitStatus.INPUT_WARNING_TEMPLATE.format('-%s|--%s' % (UserInput.Options.LOCK, UserInput.Options.LOCK_LONG)))
                self.component_to_lock = value

            elif option in ('-' + UserInput.Options.UNLOCK, '--' + UserInput.Options.UNLOCK_LONG):
                if len(value) == 0:
                    raise Warning(ExitStatus.INPUT_WARNING_TEMPLATE.format('-%s|--%s' % (UserInput.Options.UNLOCK, UserInput.Options.UNLOCK_LONG)))
                self.component_to_unlock = value
            else:
                # NOTE: if an option does not exist getopt fails and raises RuntimeError exception
                #       This branch is for options present in the lists UserInput.Options.SHORT_OPTION_LIST and LONG_OPTION_LIST
                error_description = "Option \"%s\" not implemented yet." % (option)
                raise NotImplementedError(error_description)

        self.validate()

    def validate(self):
        """Check if all needed input parameters have been set"""
        if self.command_args == None or (self.component_status == None and self.component_to_lock == None and self.component_to_unlock == None):
            error_description = "Mandatory options are missing"
            raise Warning(error_description)

        mutuallyExclusiveOptionCounter = 0
        if self.component_status != None:
            mutuallyExclusiveOptionCounter +=1

        if self.component_to_lock != None:
            mutuallyExclusiveOptionCounter +=1

        if self.component_to_unlock != None:
            mutuallyExclusiveOptionCounter +=1

        if mutuallyExclusiveOptionCounter != 1:
            error_description = "Mutually exclusive option are requested. Check Usage."
            raise Warning(error_description)

    def fetchMissingInputs(self):
        SMX_SHELF_ARCHITECTURE = 'SMX'
        SCX_SHELF_ARCHITECTURE = 'SCX'
        GEP7_HW_TYPE = 'GEP7'
        ap = None
        hw = None
        shelf_type = None 
        env = None

        process = subprocess.Popen(["cat /storage/system/config/apos/aptype.conf"], stdout=subprocess.PIPE, shell=True)
        (out, err) = process.communicate()
        ap = out.split()[0]

        process = subprocess.Popen(["cat /storage/system/config/apos/installation_hw"], stdout=subprocess.PIPE, shell=True)
        (out, err) = process.communicate()
        hw_type = out.split()[0].split("_")[0]
        if hw_type.startswith('GEP7') is True:
            hw_type = "GEP7"
        #Note: for vAPG hw_type is set to 'VM'
        hw = hw_type
        env = hw

        process = subprocess.Popen(["cat /storage/system/config/apos/shelf_architecture"], stdout=subprocess.PIPE, shell=True)
        (out, err) = process.communicate()
        shelf_type = out.split()[0]
        if shelf_type == SMX_SHELF_ARCHITECTURE:
            env += shelf_type
        if shelf_type == SCX_SHELF_ARCHITECTURE and hw_type == GEP7_HW_TYPE:
            env += shelf_type

    def usage(self):
        """Print command usage"""
        active_description = '  * \'-g active\' shows components active on this node;'
        passive_description = '  * \'-g passive\' shows components passivated on this node configuration;'
        locked_description = '  * \'-g locked\' shows components locked via apg-adm command on this side.'

        usage_output = 'Usage:\n {0} [-l|--lock <COMPONENT>]|[-u|--unlock <COMPONENT>]|[-g|--get <STATUS>][-v|--verbose][-h|--help]\n{1}\n\n{2:40}{3}\n{4:40}{5}\n{6:40}{7}\n{8:40}{9}\n{10:40}{11}\n{12:40}{13}\n{14:40}{15}\n{16:40}{17}\n'.format('apg-adm',
            (' Check if the given component name has to be activated on the specified AP system and target environment'),
            (('  -%s, --%s=%s') % (UserInput.Options.GET_INFO, UserInput.Options.GET_INFO_LONG, UserInput.Options.GET_INFO_HELP)),
            UserInput.Options.GET_INFO_HELP_DESCRIPTION,
            '', active_description,
            '', passive_description,
            '', locked_description,
            (('  -%s, --%s=%s') % (UserInput.Options.LOCK, UserInput.Options.LOCK_LONG, UserInput.Options.LOCK_HELP)),
            UserInput.Options.LOCK_HELP_DESCRIPTION,
            (('  -%s, --%s=%s') % (UserInput.Options.UNLOCK, UserInput.Options.UNLOCK_LONG, UserInput.Options.UNLOCK_HELP)),
            UserInput.Options.UNLOCK_HELP_DESCRIPTION,
            (('  -%s, --%s') % (UserInput.Options.HELP, UserInput.Options.HELP_LONG)),
            UserInput.Options.HELP_DESCRIPTION,
            (('  -%s, --%s') % (UserInput.Options.VERBOSE, UserInput.Options.VERBOSE_LONG)),
            UserInput.Options.VERBOSE_DESCRIPTION)

        exit_status_description = 'Exit status:\n   {0:5}{1},\n   {2:5}{3},\n   {4:5}{5}'.format(('%i' % ExitStatus.SUCCESS), ('%s' % ExitStatus.OK_DESCRIPTION),
            ('%i' % ExitStatus.FAILURE), ('%s' % ExitStatus.FAILURE_DESCRIPTION),
            ('%i' % ExitStatus.INPUT_ERROR), ('%s' % ExitStatus.INPUT_ERROR_DESCRIPTION))

        example_usage1 = """Example:\n  {0} -g locked\n""".format('apg-adm')
        example_usage2 = """  {0} -l ITHBIN\n""".format('apg-adm')
        example_usage3 = """  {0} --lock ITHBIN\n""".format('apg-adm')
        example_usage4 = """  {0} -u ITHBIN\n""".format('apg-adm')
        example_usage5 = """  {0} --unlock ITHBIN\n""".format('apg-adm')

        print('\n' + usage_output + '\n' + example_usage1 + example_usage2 + example_usage3 + example_usage4 + example_usage5 + '\n' + exit_status_description + '\n')


class LockTable:
    """  """
    YAML_ENTRY_COMPONENTS = "components"
    YAML_ENTRY_NOT_LOCKABLE = "not-lockable"
    YAML_KEY_NAME = "name"
    YAML_KEY_LOCKED_FLAG = "locked"
    YAML_ENTRY_CMD = "cmd"
    m_doc = None

    def __init__(self):
        m_doc = None
        
    def __del__(self):
        m_doc = None

    def load(self):
        """Load lock_table.yaml in m.doc"""
        filename = ApgEnvironment.LOCK_TABLE_FOLDER_PATH + ApgEnvironment.LOCK_TABLE_FILENAME
        with open(filename, 'r') as configFile:
            self.m_doc = yaml.safe_load(configFile)
            #print(yaml.dump(self.m_doc, default_flow_style = False))
            #print(yaml.dump(self.m_doc, default_flow_style = True))

    def dumpToYAML(self):
        target_yaml_path = ApgEnvironment.LOCK_TABLE_FOLDER_PATH + ApgEnvironment.LOCK_TABLE_FILENAME
        unordered_dict = self.m_doc
        try:     
            with open(target_yaml_path, 'w') as yamlfile:
                try: 
                    yaml.dump(unordered_dict, yamlfile, default_flow_style=False)
                except yaml.YAMLError, message:
                    print("Syntax Error in yaml file:\n %s" % (message))
                    sys.exit(ExitStatus.FAILURE)
        except IOError:
            print target_yaml_path, "file cannot stored"
            sys.exit(ExitStatus.FAILURE)            
        return None
    
    def getComponentDn(self, index, component_name, verbose_mode):
        command = None
        retCode = ExitStatus.FAILURE
        if verbose_mode is True:
            print("[DEBUG] Executing <cat /etc/cluster/nodes/this/hostname>")
        process = subprocess.Popen(["cat /etc/cluster/nodes/this/hostname"], stdout=subprocess.PIPE, shell=True)
        (hostName,err) = process.communicate()
        if err == None:
            if verbose_mode is True:
                print("[DEBUG] Read host name: " + hostName.strip())

            retCode = ExitStatus.SUCCESS
            if hostName.strip() == "SC-2-1":
                command = self.m_doc[self.YAML_ENTRY_COMPONENTS][index][self.YAML_ENTRY_CMD][0]
            else:
                command = self.m_doc[self.YAML_ENTRY_COMPONENTS][index][self.YAML_ENTRY_CMD][1]
            #if verbose_mode is True:
            #    print("[DEBUG] cmd selected: " + command)
        else:
            print("[ERROR] Cannot read host name: " + str(err))

        return (retCode, command)

    def lock(self, component_name, verbose_mode):
        index = 0
        found = False
        for item in self.m_doc[self.YAML_ENTRY_COMPONENTS]:
            if item["name"] == component_name:
                found = True
                break
            else:
                index = index + 1

        if found is False:
            print("[ERROR] <" + component_name + "> not found")
            return (ExitStatus.INPUT_ERROR, None)

        if verbose_mode is True:
            print("[DEBUG] " + component_name + " found at index " + str(index))

        self.m_doc[self.YAML_ENTRY_COMPONENTS][index]["name"] = component_name
        self.m_doc[self.YAML_ENTRY_COMPONENTS][index]["locked"] = True

        self.dumpToYAML()
        (status, command) = self.getComponentDn(index, component_name, verbose_mode)

        return (status, command)

    def unlock(self, component_name, verbose_mode):
        index = 0
        found = False
        for item in self.m_doc[self.YAML_ENTRY_COMPONENTS]:
            if item["name"] == component_name:
                found = True
                break
            else:
                index = index + 1
        
        if found is False:
            print("[ERROR] <" + component_name + "> not found")
            return (ExitStatus.INPUT_ERROR,None)

        if verbose_mode is True:
            print("[DEBUG] " + component_name + " found at index " + str(index))

        self.m_doc[self.YAML_ENTRY_COMPONENTS][index]["name"] = component_name
        self.m_doc[self.YAML_ENTRY_COMPONENTS][index]["locked"] = False

        self.dumpToYAML()
        (status, command) = self.getComponentDn(index, component_name, verbose_mode)

        return (status, command)

    def getComponent(self, name):
        """ Build and returns a YamlLockTableComponent object that maps file entry """
        if self.m_doc == None:
            return None

        componentArray = self.m_doc[self.YAML_ENTRY_COMPONENTS]
        for singleComponent in componentArray:
            componentName = singleComponent[self.YAML_KEY_NAME]
            if componentName.upper() == name.upper():
                isLocked = singleComponent[self.YAML_KEY_LOCKED_FLAG]

                yamlComponent = YamlLockTableComponent(componentName, isLocked)
                return yamlComponent

        return None

    def getComponentList(self):
        """this function build and returns a YamlLockTableComponent object that maps file entry """
        if self.m_doc == None:
            return None

        yamlComponentList = list()

        componentArray = self.m_doc[self.YAML_ENTRY_COMPONENTS]
        for singleComponent in componentArray:
            componentName = singleComponent[self.YAML_KEY_NAME]
            isLocked = singleComponent[self.YAML_KEY_LOCKED_FLAG]
            yamlComponent = YamlLockTableComponent(componentName, isLocked)
            yamlComponentList.append(yamlComponent)
        
        return yamlComponentList

    def getLockedComponents(self):
        """this function build and returns a YamlLockTableComponent object that maps file entry """
        if self.m_doc == None:
            return None

        yamlComponentList = list()

        componentArray = self.m_doc[self.YAML_ENTRY_COMPONENTS]
        for singleComponent in componentArray:
            componentName = singleComponent[self.YAML_KEY_NAME]
            isLocked = singleComponent[self.YAML_KEY_LOCKED_FLAG]
            if isLocked is True:
                yamlComponent = YamlLockTableComponent(componentName, isLocked)
                yamlComponentList.append(yamlComponent)
        
        return yamlComponentList

    def getUnlockedComponents(self):
        """this function build and returns a YamlLockTableComponent object that maps file entry """
        if self.m_doc == None:
            return None

        yamlComponentList = list()

        componentArray = self.m_doc[self.YAML_ENTRY_COMPONENTS]
        for singleComponent in componentArray:
            componentName = singleComponent[self.YAML_KEY_NAME]
            isLocked = singleComponent[self.YAML_KEY_LOCKED_FLAG]
            if isLocked is False:
                yamlComponent = YamlLockTableComponent(componentName, isLocked)
                yamlComponentList.append(yamlComponent)
        
        return yamlComponentList

class YamlLockTableComponent:
    """APG Component defined in yaml configuration file."""
    m_name = None
    m_isLocked = None

    def __init__(self, componentName, isLocked):
        self.m_name = componentName
        self.m_isLocked = isLocked

    def __del__(self):
        pass

    def getName(self):
        """Get the component name."""
        return self.m_name

    def isLocked(self):
        """Get supported AP Types."""
        return self.m_isLocked


##########################################################
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

    def load(self):
        """Load apg_sw_activation_table.yaml in m.doc"""

        filename = ApgEnvironment.SW_ACTIVATION_TABLE_FOLDER_PATH + ApgEnvironment.SW_ACTIVATION_TABLE_FILENAME
        with open(filename, 'r') as configFile:
            self.m_doc = yaml.safe_load(configFile)
            #print(yaml.dump(self.m_doc, default_flow_style = False))

    def getComponent(self, name):
        """ Build and returns a YamlActivationTableComponent object that maps file entry """
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
                    yamlComponent = YamlActivationTableComponent(singleComponentName, singleComponentApTypeArray, singleComponentTargetEnvArray,\
                                                                 singleComponentSystemTypeArray)
                else:
                    yamlComponent = YamlActivationTableComponent(singleComponentName, singleComponentApTypeArray, singleComponentTargetEnvArray)

                return yamlComponent              
        
        return None

    def getYamlComponentList(self):
        """this function build and returns a YamlActivationTableComponent object that maps file entry """
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
                yamlComponent = YamlActivationTableComponent(singleComponentName, singleComponentApTypeArray, singleComponentTargetEnvArray,\
                                                             singleComponentSystemTypeArray)
            else:
                yamlComponent = YamlActivationTableComponent(singleComponentName, singleComponentApTypeArray, singleComponentTargetEnvArray)
            
            yamlComponentList.append(yamlComponent)
        
        return yamlComponentList

    def getActiveComponentsList(self, yamlComponentList, apType, target, systype):
        """this function build and returns a YamlActivationTableComponent object that maps file entry """
        activeComponentList = list()

        for yamlActivationTableComponent in yamlComponentList:
            name = yamlActivationTableComponent.getName()
            isAPsupported = yamlActivationTableComponent.hasApType(apType)
            isTargetSupported = yamlActivationTableComponent.hasTargetenv(target)
            isSysTypeSupported = yamlActivationTableComponent.hasSysType(systype)

            if isAPsupported is True and isTargetSupported is True and isSysTypeSupported is True:
                activeComponentList.append(yamlActivationTableComponent)

        return activeComponentList

    def getPassiveComponentsList(self, yamlComponentList, apType, target, systype):
        """this function build and returns a YamlActivationTableComponent object that maps file entry """
        passiveComponentList = list()

        for yamlActivationTableComponent in yamlComponentList:
            name = yamlActivationTableComponent.getName()
            isAPsupported = yamlActivationTableComponent.hasApType(apType)
            isTargetSupported = yamlActivationTableComponent.hasTargetenv(target)
            isSysTypeSupported = yamlActivationTableComponent.hasSysType(systype)
            if isAPsupported is False or isTargetSupported is False or isSysTypeSupported is False:
                passiveComponentList.append(yamlActivationTableComponent)

        return passiveComponentList

class YamlActivationTableComponent:
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
        """ Check entry System Type
           Returns Boolean found
        """
        found = False
        if self.m_sysTypeArray == None:
            found = True
        else:
            for entry in self.m_sysTypeArray:
                if entry.upper() == name.upper():
                    found = True
                    break
        return found

#####################################################################################
class ApgEnvironment:
    ap_type = None
    target_env = None
    sys_type = None

    ## PATHS
    LOCK_TABLE_FOLDER_PATH = '/opt/ap/apos/bin/'  
    LOCK_TABLE_FILENAME = 'lock_table.yaml'

    SW_ACTIVATION_TABLE_FOLDER_PATH = '/opt/ap/apos/conf/'
    SW_ACTIVATION_TABLE_FILENAME = 'apg_sw_activation_table.yaml'


    def __init__(self, ap_type, target_env, sys_type):
        self.ap_type = ap_type
        self.target_env = target_env
        self.sys_type = sys_type

    def __init__(self):
        self.ap_type = None
        self.target_env = None
        self.sys_type = None

    def fetchNodeDetails(self):
        SMX_SHELF_ARCHITECTURE = 'SMX'
        SCX_SHELF_ARCHITECTURE = 'SCX'
        GEP7_HW_TYPE = 'GEP7'

        if self.ap_type is None:
            process = subprocess.Popen(["cat /storage/system/config/apos/aptype.conf"], stdout=subprocess.PIPE, shell=True)
            (out, err) = process.communicate()
            self.ap_type = out.split()[0]

        if self.target_env is None:
            process = subprocess.Popen(["cat /storage/system/config/apos/installation_hw"], stdout=subprocess.PIPE, shell=True)
            (out, err) = process.communicate()
            hw_type = out.split()[0].split("_")[0]
            if hw_type.startswith('GEP7') is True:
                hw_type = "GEP7"
            
            #Note: for vAPG hw_type is set to 'VM'
            self.target_env = hw_type

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

        
#####################################################################################
def handleGetStatus(component_status, verbose_mode):
    #status: active|passive|locked
    if component_status.lower() == 'active':
        if verbose_mode is True:
            print("[DEBUG] fetch active") #active
        # get environment
        env = ApgEnvironment()
        env.fetchNodeDetails()
        if verbose_mode is True:
            print ("[DEBUG] Environemnt: (" + env.ap_type + "," + env.target_env + ")")

        # read activation table
        activationTableFile = ApgEnvironmentMap()
        activationTableFile.load()

        # filter on components not allowed on the current platform
        allComponents = activationTableFile.getYamlComponentList()
        notPassiveComponents = activationTableFile.getActiveComponentsList(allComponents, env.ap_type, env.target_env, env.sys_type)
        #if verbose_mode is True:
        #    print ("[DEBUG] # notPassiveComponents: " + str(len(notPassiveComponents)))

        #
        # Parse the lock_table.yaml
        #
        lock_table = LockTable()
        lock_table.load()

        lockedComponents = lock_table.getLockedComponents()
        #if verbose_mode is True:
        #    print ("[DEBUG] lockedComponents.size(): " + str(len(lockedComponents)))

        for lockedComponent in lockedComponents:
            ### search lockedComponent.getName() in notPassiveComponents
            if verbose_mode is True:
                print("[DEBUG] search lockedComponent.getName() in notPassiveComponents: " + lockedComponent.getName())
            for activeComp in notPassiveComponents:
                #if verbose_mode is True:
                #    print("[DEBUG] if " + activeComp.getName() + "==" + lockedComponent.getName())
                if activeComp.getName() == lockedComponent.getName():
                    if verbose_mode is True:
                        print("[DEBUG] Remove lockedComponent.getName() from notPassiveComponents: " + lockedComponent.getName())
                    notPassiveComponents.remove(activeComp)
                    break

        if verbose_mode is True:
            print("[DEBUG] ### LIST OF ACTIVE COMPONENTS ###")
            print ("[DEBUG] #Not Passive Components: " + str(len(notPassiveComponents)))
        for component in notPassiveComponents:
            print(component.getName())
        if verbose_mode is True:
            print("[DEBUG] ### END ###")

    elif component_status.lower() == 'passive':
        # get environment
        env = ApgEnvironment()
        env.fetchNodeDetails()
        if verbose_mode is True:
            print ("[DEBUG] Environment: (" + env.ap_type + "," + env.target_env + ")")

        # read activation table
        activationTableFile = ApgEnvironmentMap()
        activationTableFile.load()

        # filter on components not allowed on the current platform
        allComponents = activationTableFile.getYamlComponentList()
        result = activationTableFile.getPassiveComponentsList(allComponents, env.ap_type, env.target_env, env.sys_type)
        if verbose_mode is True:
            print("[DEBUG] ### LIST OF PASSIVE COMPONENTS ###")
        for component in result:
            print(component.getName())
        if verbose_mode is True:
            print("[DEBUG] ### END ###")

    elif component_status.lower() == 'locked':
        #
        # Parse the lock_table.yaml
        #
        lock_table = LockTable()
        lock_table.load()

        lockedComponents = lock_table.getLockedComponents()
        if verbose_mode is True:
            print("[DEBUG] ### LIST OF LOCKED COMPONENTS ###")
        for component in lockedComponents:
            print(component.getName())
        if verbose_mode is True:
            print("[DEBUG] ### END ###")
    else:
        print("ERROR")#remove
############################################################################################
def handleLock(component_name, verbose_mode):
    #
    # Parse the lock_table.yaml
    #
    lock_table = LockTable()
    lock_table.load()
    (returnCode, lock_cmd) = lock_table.lock(component_name, verbose_mode)
    if returnCode == ExitStatus.SUCCESS:
        if verbose_mode is True:
            print("[DEBUG] executing: " + lock_cmd)
        process = subprocess.Popen([lock_cmd], stdout=subprocess.PIPE, shell=True)
        (out,err) = process.communicate()
        if err == None:
            returnCode = ExitStatus.SUCCESS
        else:
            returnCode = ExitStatus.FAILURE

    return returnCode


def handleUnLock(component_name, verbose_mode):
    #
    # Parse the lock_table.yaml
    #
    lock_table = LockTable()
    lock_table.load()
    (returnCode, unlock_cmd) = lock_table.unlock(component_name, verbose_mode)
    if returnCode == ExitStatus.SUCCESS:
        if verbose_mode is True:
            print("[DEBUG] executing: " + unlock_cmd)
        process = subprocess.Popen([unlock_cmd], stdout=subprocess.PIPE, shell=True)
        (out,err) = process.communicate()
        if err == None:
            returnCode = ExitStatus.SUCCESS
        else:
            returnCode = ExitStatus.FAILURE

    return returnCode

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

    returnCode = ExitStatus.SUCCESS
    if cmd_input.component_status != None:
        handleGetStatus(cmd_input.component_status, cmd_input.verbose_mode)

    if cmd_input.component_to_lock != None:
        returnCode = handleLock(cmd_input.component_to_lock, cmd_input.verbose_mode)

    if cmd_input.component_to_unlock != None:
        returnCode = handleUnLock(cmd_input.component_to_unlock, cmd_input.verbose_mode)

    sys.exit(returnCode)

##########################################################
################## SCRIPT EXECUTION ######################
main()
##########################################################
