###############################################################
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
#      author: xsravan/zbhegna
#
#      Description:This script is used for the generation of SMF campaign
# Changelog:
# - Thu Jan 18 2024 - zprapxx (Moved changing_umask_value.sh script from oscmd campaign to osconf)
# - Fri Jul 28 2023 - zgxxnav ("Removal of apache2-mpm dependency")
# - Tue Apr 12 2022 - xsowmed (removed the calling of apos_delete_telnet_prot.sh script)
# - Thu Mar 03 2022 - xcsrpad ("aposchrony_enabler.sh" called in cliAtCampInit to handle
#                              chrony configuration at MI and Upgrade)
# - Tue Feb 08 2022 - xsowmed ("apos_delete_telnet_prot.sh" called in cliAtCampInit to handle
#                              deletion of telnet insecure protocol at MI)
# - Wed Dec 30 2020 - xcsrpad ("apos_block_insecure_prot.sh" called in cliAtCampInit to handle
#                              blocking of insecure protocols(ftp) at MI)
# - Fri Jun 12 2020 - zmedram ("axe_role_rule.sh" called in cliAtProcInit action to update 
#                              roles and rules in application)
# - Fri Oct 20 2019 - xnazbeg (WA added for upgrade failure due to component restart triggered by PRC)
# - Mon Apr 29 2019 - xpraupp (Added campInit action to handle security mitigations)
# - Wed Feb 20 2018 - xnazbeg (Calling the scripts in camp-init and campcomplete to handle sec_ldap
#			       n/w and cache timeout  parameters)
# - Mon Apr 23 2018 - zbhegna (added upgrade part)
# - Mon Sep 24 2018- zgxxnav ("get_passive_comp.sh" called in procwrapup action to get 
#			       passive components list)
#
###############################################################
from tcg.plugin_api.SMFCampaignPlugin import SMFCampaignPlugin
from tcg.plugin_api import SMFConstants
from tcg.plugin_api.SMFCampaignGenerationInfoProvider import SMFCampaignGenerationInfoProvider
from tcg.plugin_api.SMFPluginUtilitiesProvider import SMFPluginUtilitiesProvider
import os

def createSMFCampaignPlugin():
   return OSCONFSMFCampaignPlugin()

class OSCONFSMFCampaignPlugin(SMFCampaignPlugin):
   # initialization method
   # self: variable represents the instance of the object itself
   def __init__(self):
      super(OSCONFSMFCampaignPlugin, self).__init__()
      self.MY_COMPONENT_UID = "apos.osconf"
      self._info = None
      self._utils = None
      self._actionType = None

   def prepare(self, csmModelInformationProvider, pluginUtilitiesProvider):
      # Here we save the references to the providers to be used later
      self._utils = pluginUtilitiesProvider
      self._info = csmModelInformationProvider

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
#-------------------------------------------------------------------------------------------------------------------------------------------------------------
# CLI actions that need to be executed during proc init phase
# These will be translated to a ProcInitAction doCLI in the generated campaign
# Second argument in undoCli or doCli represents arguments used with doCliCommand or undoClicommand in generated campaign
# Third argument in the tuple action is representing the Exec Environment
#---------------------------------------------------------------------------------------------------------------------------------------------------------------
   def cliAtProcInit(self):
      self._actionType = self._info.getComponentActionType()
      result = []
      undoCli = ("/bin/true", None)
      if (self._actionType == SMFConstants.CT_INSTALL or self._actionType == SMFConstants.CT_UPGRADE or self._actionType == SMFConstants.CT_MIGRATE):
          cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "campaign_helper.sh" )
          doCli = (cli, "init")
          action =(doCli,undoCli,None)
          result.append(action)
      if self._info.getComponentActionType() == SMFConstants.CT_INSTALL:
          cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "apos_preinstall.sh")
          doCli = (cli, "init")
          action =(doCli,undoCli,"safAmfNode=SC-1,safAmfCluster=myAmfCluster")
          result.append(action)
          action =(doCli,undoCli,"safAmfNode=SC-2,safAmfCluster=myAmfCluster")
          result.append(action)
      if (self._actionType == SMFConstants.CT_INSTALL or self._actionType == SMFConstants.CT_UPGRADE):          
          cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "aposchrony_enabler.sh") 
          doCli = (cli, "init")
          action =(doCli,undoCli,"safAmfNode=SC-1,safAmfCluster=myAmfCluster")
          result.append(action)
      if self._info.getComponentActionType() == SMFConstants.CT_INSTALL:
          cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "apos_conf_wrapper.sh")
          doCli = (cli, None)
          action =(doCli,undoCli,"safAmfNode=SC-1,safAmfCluster=myAmfCluster")
          result.append(action)
          action =(doCli,undoCli,"safAmfNode=SC-2,safAmfCluster=myAmfCluster")
          result.append(action)
      if (self._actionType == SMFConstants.CT_INSTALL):
          cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "create_cr_class.sh" )
          doCli = (cli, "init")
          action =(doCli,undoCli,None)
          result.append(action)
      if self._info.getComponentActionType() == SMFConstants.CT_INSTALL:
          cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "apos_finalize_sysconf.sh" )
          doCli = (cli, "init")
          action = (doCli,undoCli,"safAmfNode=SC-1,safAmfCluster=myAmfCluster")
          result.append(action)
          action =(doCli,undoCli,"safAmfNode=SC-2,safAmfCluster=myAmfCluster")
          result.append(action)
      if self._info.getComponentActionType() == SMFConstants.CT_UPGRADE:
          cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "apos_roles_rules.sh")
          doCli = (cli, "init")
          action =(doCli,undoCli,"safAmfNode=SC-1,safAmfCluster=myAmfCluster")
          result.append(action)
      if self._info.getComponentActionType() == SMFConstants.CT_UPGRADE:
          cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "axe_roles_rules.sh")
          doCli = (cli, "init")
          action =(doCli,undoCli,"safAmfNode=SC-1,safAmfCluster=myAmfCluster")
          result.append(action)
      if self._info.getComponentActionType() == SMFConstants.CT_UPGRADE:
          cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "apos_storage_attribute.sh")
          doCli = (cli, "init")
          action =(doCli,undoCli,"safAmfNode=SC-1,safAmfCluster=myAmfCluster")
          result.append(action)
      if (self._actionType == SMFConstants.CT_INSTALL or self._actionType == SMFConstants.CT_UPGRADE):
          cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "optimized_lde_brf_configuration.sh")
          doCli = (cli, "init")
          action =(doCli,undoCli,None)
          result.append(action)
      if self._actionType == SMFConstants.CT_UPGRADE:
          cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "optimized_lde_brf_backup_folder.sh")
          doCli = (cli, "init")
          action =(doCli,undoCli,"safAmfNode=SC-1,safAmfCluster=myAmfCluster")
          result.append(action)
          action =(doCli,undoCli,"safAmfNode=SC-2,safAmfCluster=myAmfCluster")
          result.append(action)

      return result
#-------------------------------------------------------------------------------------------------------------------------------------------------------------
# CLI actions that need to be executed during campaign complete phase
# These will be translated to a campCompleteAction doCLI in the generated campaign
# Second argument in undoCli or doCli represents arguments used with doCliCommand or undoClicommand in generated campaign
# Third argument in the tuple action is representing the Exec Environment, None represents SC-1,"safAmfNode=SC-2,safAmfCluster=myAmfCluster" represents SC-2
#---------------------------------------------------------------------------------------------------------------------------------------------------------------    
   def cliAtCampComplete(self):
      self._actionType = self._info.getComponentActionType()
      result = []
      undoCli = ("/bin/true", None)
      if self._info.getComponentActionType() == SMFConstants.CT_INSTALL:
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "tz_sync.sh")
         doCli = (cli, None)
         action = (doCli,undoCli,"safAmfNode=SC-1,safAmfCluster=myAmfCluster")
         result.append(action)
      if (self._actionType == SMFConstants.CT_UPGRADE or self._actionType == SMFConstants.CT_NOOP or self._actionType == SMFConstants.CT_MIGRATE or self._actionType == SMFConstants.CT_INSTALL):
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "aposcfg_apgtype.sh")
         doCli = (cli, None)
         action =(doCli,undoCli,None)
         result.append(action)      
      if (self._actionType == SMFConstants.CT_INSTALL or self._actionType == SMFConstants.CT_UPGRADE or self._actionType == SMFConstants.CT_MIGRATE):
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "get_passive_comp.sh" )
         doCli = (cli, "init")
         action =(doCli,undoCli,None)
         result.append(action)
      if (self._actionType == SMFConstants.CT_UPGRADE or self._actionType == SMFConstants.CT_NOOP):
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "apos_security_mitigations.sh" )
         doCli = (cli, "clear")
         action =(doCli,undoCli,None)
         result.append(action)
      if (self._actionType == SMFConstants.CT_UPGRADE ):
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "apos_update_secldap_param.sh" )
         doCli = (cli, "init")
         action =(doCli,undoCli,None)
         result.append(action)
      if (self._actionType == SMFConstants.CT_UPGRADE ):
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "apos_prc_fix.sh" )
         doCli = (cli, "reset")
         action =(doCli,undoCli,None)
         result.append(action)
      if (self._actionType == SMFConstants.CT_INSTALL ):
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "apos_block_insecure_prot.sh")
         doCli = (cli, None)
         action = (doCli,undoCli,"safAmfNode=SC-1,safAmfCluster=myAmfCluster")
         result.append(action)
      if (self._info.getComponentActionType() == SMFConstants.CT_UPGRADE or self._actionType == SMFConstants.CT_INSTALL):
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "changing_umask_value.sh" )
         doCli = (cli, None)
         action =(doCli,undoCli,"safAmfNode=SC-1,safAmfCluster=myAmfCluster")
         result.append(action)
         action =(doCli,undoCli,"safAmfNode=SC-2,safAmfCluster=myAmfCluster")
         result.append(action)
      return result


#-------------------------------------------------------------------------------------------------------------------------------------------------------------
# CLI actions that need to be executed during campaign initialization phase
# These will be translated to a campCompleteAction doCLI in the generated campaign
# Second argument in undoCli or doCli represents arguments used with doCliCommand or undoClicommand in generated campaign
# Third argument in the tuple action is representing the Exec Environment, None represents SC-1
#---------------------------------------------------------------------------------------------------------------------------------------------------------------
   def cliAtCampInit(self):
      self._actionType = self._info.getComponentActionType()
      result = []
      if (self._actionType == SMFConstants.CT_UPGRADE or self._actionType == SMFConstants.CT_NOOP or self._actionType == SMFConstants.CT_MIGRATE):
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "apg_swpkg_folder_change.sh" )
         doCli = (cli, None)
         undoCli = ("/bin/true", None)
         action =(doCli,undoCli,None)
         result.append(action)
      if (self._actionType == SMFConstants.CT_UPGRADE or self._actionType == SMFConstants.CT_NOOP or self._actionType == SMFConstants.CT_MIGRATE):
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "apos_drbdstatus.sh" )
         doCli = (cli, None)
         undoCli = ("/bin/true", None)
         action =(doCli,undoCli,None)
         result.append(action)
      if (self._actionType == SMFConstants.CT_UPGRADE or self._actionType == SMFConstants.CT_NOOP):
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "apos_security_mitigations.sh" )
         doCli = (cli, "apply")
         undoCli = ("/bin/true", None)
         action =(doCli,undoCli,None)
         result.append(action)
      if (self._actionType == SMFConstants.CT_UPGRADE):
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "apos_store_secldap_param.sh")
         doCli = (cli, None)
         undoCli = ("/bin/true", None)
         action =(doCli,undoCli,None)
         result.append(action)
      if (self._actionType == SMFConstants.CT_UPGRADE):
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "apos_prc_fix.sh")
         doCli = (cli, "set")
         undoCli = (cli, "reset")
         action =(doCli,undoCli,None)
         result.append(action)
      if (self._actionType == SMFConstants.CT_UPGRADE):
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "apos_apache_wa.sh")
         doCli = (cli, None)
         action =(doCli,undoCli,"safAmfNode=SC-1,safAmfCluster=myAmfCluster")
         result.append(action)
         action =(doCli,undoCli,"safAmfNode=SC-2,safAmfCluster=myAmfCluster")
         result.append(action)
      if (self._actionType == SMFConstants.CT_UPGRADE):
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "apos_ha_wa.sh")
         doCli = (cli, None)
         action =(doCli,undoCli,"safAmfNode=SC-1,safAmfCluster=myAmfCluster")
         result.append(action)
         action =(doCli,undoCli,"safAmfNode=SC-2,safAmfCluster=myAmfCluster")
         result.append(action)
      return result

#------------------------------------------------------------------------------------------------------------------
# Callback actions that need to be executed during Campign Rolling phase
# callbackAtCampaignRollback method return list of campaign rollback actions that need to be executed
#------------------------------------------------------------------------------------------------------------------
   def callbackAtCampaignRollback(self):
      self._actionType = self._info.getComponentActionType()
      result = []
      if (self._actionType == SMFConstants.CT_UPGRADE or self._actionType == SMFConstants.CT_NOOP):
         callbacklabel = "OsafSmfCbkUtil-Cmd"
         callbacktimeout = 100000000000
         stringToPass = "/bin/true"
         actions = (callbacklabel,callbacktimeout,stringToPass)
         result.append(actions)

      return result
