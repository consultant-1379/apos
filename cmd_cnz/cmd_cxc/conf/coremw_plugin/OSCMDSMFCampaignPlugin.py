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
#      author: xpransi
#
#      Description:This script is used for the generation of SMF campaign
# Changelog:
# - Thu Jan 18 2024 - zprapxx Moving the "changing_umask_value.sh" script to OSCONF campaign
# - Mon May 29 2023 - zprapxx As part of ciscat improvements feature added changing_umask_value.sh func
# - Wed Feb 2022 - xsigano GSNH enhancements feature
# - Thu Feb 06 2020  - zbhegna Added apache_cleanup.sh 
# - Thu June 14 2018 - xpransi First revision
#
#
###############################################################
from tcg.plugin_api.SMFCampaignPlugin import SMFCampaignPlugin
from tcg.plugin_api import SMFConstants
from tcg.plugin_api.SMFCampaignGenerationInfoProvider import SMFCampaignGenerationInfoProvider
from tcg.plugin_api.SMFPluginUtilitiesProvider import SMFPluginUtilitiesProvider
import os

def createSMFCampaignPlugin():
   return OSCMDSMFCampaignPlugin()

class OSCMDSMFCampaignPlugin(SMFCampaignPlugin):
   # initialization method
   # self: variable represents the instance of the object itself
   def __init__(self):
      super(OSCMDSMFCampaignPlugin, self).__init__()
      self.MY_COMPONENT_UID = "apos.oscmd"
      self._info = None
      self._utils = None
      self._actionType = None

   def prepare(self, csmModelInformationProvider, pluginUtilitiesProvider):
      # Here we save the references to the providers to be used later
      self._utils = pluginUtilitiesProvider
      self._info = csmModelInformationProvider

#-------------------------------------------------------------------------------------------------------------------------------------------------------------
# CLI actions that need to be executed during proc init phase
# These will be translated to a ProcInitAction doCLI in the generated campaign
# Second argument in undoCli or doCli represents arguments used with doCliCommand or undoClicommand in generated campaign
# Third argument in the tuple action is representing the Exec Environment
#---------------------------------------------------------------------------------------------------------------------------------------------------------------    
   def cliAtProcInit(self):
      self._actionType = self._info.getComponentActionType()
      result = []
      if self._info.getComponentActionType() == SMFConstants.CT_INSTALL:
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "incCmWTimeout.sh" )
         doCli = (cli, None)
         undoCli = ("/bin/true", None)
         action =(doCli,undoCli,None)
         result.append(action)
      if self._info.getComponentActionType() == SMFConstants.CT_INSTALL:
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "APGplugin",  "configure_drbd1.sh")
         doCli = (cli, None)
         undoCli = ("/bin/true", None)
         action =(doCli,undoCli,"safAmfNode=SC-1,safAmfCluster=myAmfCluster")
         result.append(action)
      if self._info.getComponentActionType() == SMFConstants.CT_INSTALL:
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "APGplugin",  "preinstall.sh")
         doCli = (cli, None)
         undoCli = ("/bin/true", None)
         action =(doCli,undoCli,"safAmfNode=SC-2,safAmfCluster=myAmfCluster")
         result.append(action)
      if (self._actionType == SMFConstants.CT_UPGRADE or self._actionType == SMFConstants.CT_NOOP or self._actionType == SMFConstants.CT_MIGRATE or self._actionType == SMFConstants.CT_INSTALL):
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "swm_version.sh" )
         undocli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "swm_version.sh" )
         doCli = (cli, "create")
         undoCli = (undocli, "delete")
         action =(doCli,undoCli,"safAmfNode=SC-1,safAmfCluster=myAmfCluster")
         result.append(action)
         action =(doCli,undoCli,"safAmfNode=SC-2,safAmfCluster=myAmfCluster")
         result.append(action)
      if (self._actionType == SMFConstants.CT_UPGRADE):
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "apos_http_sec_impact.sh" )
         undocli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "apos_http_sec_impact.sh")
         doCli = (cli, None)
         undoCli = ("/bin/true", None)
         action =(doCli,undoCli,None)
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
      undoCli = ("/bin/true", None)
      if (self._actionType == SMFConstants.CT_UPGRADE or self._actionType == SMFConstants.CT_NOOP):
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "fix_deploy_params.sh" )
         doCli = (cli, None)
         action =(doCli,undoCli,"safAmfNode=SC-1,safAmfCluster=myAmfCluster")
         result.append(action)
         action =(doCli,undoCli,"safAmfNode=SC-2,safAmfCluster=myAmfCluster")
         result.append(action)

      return result

#-------------------------------------------------------------------------------------------------------------------------------------------------------------
# CLI actions that need to be executed during campaign complete phase
# These will be translated to a campCompleteAction doCLI in the generated campaign
# Second argument in undoCli or doCli represents arguments used with doCliCommand or undoClicommand in generated campaign
# Third argument in the tuple action is representing the Exec Environment
#---------------------------------------------------------------------------------------------------------------------------------------------------------------
   def cliAtCampWrapup(self):
      self._actionType = self._info.getComponentActionType()
      result = []
      undoCli = ("/bin/true", None)
      if self._info.getComponentActionType() == SMFConstants.CT_INSTALL:
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "APGplugin", "postinstall.sh" )
         doCli = (cli, None)
         action =(doCli,undoCli,"safAmfNode=SC-2,safAmfCluster=myAmfCluster")
         result.append(action)
      if (self._info.getComponentActionType() == SMFConstants.CT_UPGRADE or self._actionType == SMFConstants.CT_NOOP):
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "fix_deploy_params.sh" )
         doCli = (cli, None)
         action =(doCli,undoCli,"safAmfNode=SC-2,safAmfCluster=myAmfCluster")
         result.append(action)
      if (self._info.getComponentActionType() == SMFConstants.CT_UPGRADE):
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "apache_cleanup.sh" )
         doCli = (cli, None)
         action =(doCli,undoCli,None)
         result.append(action)
      if (self._info.getComponentActionType() == SMFConstants.CT_UPGRADE):
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "disable_log_retention.sh" )
         doCli = (cli, None)
         action =(doCli,undoCli,"safAmfNode=SC-1,safAmfCluster=myAmfCluster")
         result.append(action)
         action =(doCli,undoCli,"safAmfNode=SC-2,safAmfCluster=myAmfCluster")
         result.append(action)
      if (self._info.getComponentActionType() == SMFConstants.CT_UPGRADE or self._actionType == SMFConstants.CT_INSTALL):
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "logm_export_location.sh" )
         doCli = (cli, None)
         action =(doCli,undoCli,"safAmfNode=SC-1,safAmfCluster=myAmfCluster")
         result.append(action)
         action =(doCli,undoCli,"safAmfNode=SC-2,safAmfCluster=myAmfCluster")
         result.append(action)
      if (self._info.getComponentActionType() == SMFConstants.CT_UPGRADE):
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "gsnh_apg_upgrade.sh" )
         doCli = (cli, None)
         action =(doCli,undoCli,None)
         result.append(action)
      if (self._info.getComponentActionType() == SMFConstants.CT_INSTALL):
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "gsnh_apg_maideninstall.sh" )
         doCli = (cli, None)
         action =(doCli,undoCli,None)
         result.append(action)
      if (self._info.getComponentActionType() == SMFConstants.CT_INSTALL):
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "enable_lde_audit_rules.sh" )
         doCli = (cli, None)
         action =(doCli,undoCli,"safAmfNode=SC-1,safAmfCluster=myAmfCluster")
         result.append(action)
         action =(doCli,undoCli,"safAmfNode=SC-2,safAmfCluster=myAmfCluster")
         result.append(action)
      if (self._info.getComponentActionType() == SMFConstants.CT_UPGRADE):
         cli = os.path.join("$OSAFCAMPAIGNROOT", self.MY_COMPONENT_UID, "scripts", "rsyslog_restart.sh" )
         doCli = (cli, None)
         action =(doCli,undoCli,"safAmfNode=SC-1,safAmfCluster=myAmfCluster")
         result.append(action)
         action =(doCli,undoCli,"safAmfNode=SC-2,safAmfCluster=myAmfCluster")
         result.append(action)

      return result

