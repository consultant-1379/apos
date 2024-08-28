###########################################################################
#
#      COPYRIGHT Ericsson 2018
#      All rights reserved.
#
#      The Copyright to the computer program(s) herein
#      is the property of Ericsson 2018.
#      The program(s) may be used and/or copied only with
#      the written permission from Ericsson 2018 or in
#      accordance with the terms and conditions stipulated in
#      the agreement/contract under which the program(s) have
#      been supplied.
#
#      author: zbhegna
#
#      Description:This script is used for the generation of SMF campaign
#
##########################################################################

from tcg.plugin_api.SMFCampaignPlugin import SMFCampaignPlugin
from tcg.plugin_api import SMFConstants
from tcg.plugin_api.SMFCampaignGenerationInfoProvider import SMFCampaignGenerationInfoProvider
from tcg.plugin_api.SMFPluginUtilitiesProvider import SMFPluginUtilitiesProvider
import os
def createSMFCampaignPlugin():
   return OSEXTSMFCampaignPlugin()

class OSEXTSMFCampaignPlugin(SMFCampaignPlugin):
   # initialization method
   # self: variable represents the instance of the object itself
   def __init__(self):
      super(OSEXTSMFCampaignPlugin, self).__init__()
      self.MY_COMPONENT_UID = "apos.osext"
      self._info = None
      self._utils = None
      self._actionType = None

   def prepare(self, csmModelInformationProvider, pluginUtilitiesProvider):
      # Here we save the references to the providers to be used later
      self._utils = pluginUtilitiesProvider
      self._info = csmModelInformationProvider
#-------------------------------------------------------------------------------------------------------------------------------------------------------------
# CLI actions that need to be executed during procedure initiation phase
# These will be translated to a procInitAction doCLI,undoCli in the generated campaign
#-------------------------------------------------------------------------------------------------------------------------------------------------------------
   def cliAtProcInit(self):
      script_arg = "set"
      return self.cliAtActions(script_arg)

#-------------------------------------------------------------------------------------------------------------------------------------------------------------
# CLI actions that need to be executed during procedure Wrapup  phase
# These will be translated to a procWrapupAction doCLI,undoCli in the generated campaign
#------------------------------------------------------------------------------------------------------------------------------------------------------------
   def cliAtCampInit(self):
      self._actionType = self._info.getComponentActionType()
      result = []
      if (self._actionType == SMFConstants.CT_UPGRADE):
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "apos_copy_remove_rpms_script.sh")
         doCli = (cli, "set")
         undoCli = (cli, "reset")
         action =(doCli,undoCli,None)
         result.append(action)
      return result

   def cliAtProcWrapup (self):
      script_arg = "default"
      return self.cliAtActions(script_arg)


   def cliAtActions(self,script_arg):
      self._actionType = self._info.getComponentActionType()
      result = []
      cli_script = "swup_update_smfclitimeout.sh" 
      if (self._actionType == SMFConstants.CT_UPGRADE or self._actionType == SMFConstants.CT_MIGRATE): 
         result.append(self.makeActions(cli_script,script_arg))
         return result

#----------------------------------------------------------------------------------------------------------------------------------------------------------
# makeActions method is to return CLI actions
# Second argumenet in undoCli or doCli represents arguments used with doCliCommand or undoClicommand in generated campaign
# Third argument in the tuple action is representing the Exec Environment, None represents SC-1
#------------------------------------------------------------------------------------------------------------------------------------------------------------
   def makeActions(self,script,args):
      undoCli = ("/bin/true",None)
      cli = os.path.join("$OSAFCAMPAIGNROOT",self.MY_COMPONENT_UID,"scripts",script)
      doCli = (cli,args)
      action = (doCli,undoCli,None)
      return action


