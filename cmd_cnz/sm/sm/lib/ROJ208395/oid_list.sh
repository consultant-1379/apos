#------------------------------------------------------------------------------#
# ROJ 208 395                                                                  #
# OIDs to be used in a SCX-based EGEM2 magazine.                                #
#------------------------------------------------------------------------------#
# NOTES: - This file is intended to be sourced by the shelfmngr routines so it #
#        MUST be compliant with the bash syntax.                               #
#        - The right values of the variables below MUST match one of the       #
#        following conditions:                                                 #
#          1) they have to be strong-quoted (single-quoted)                    #
#          2) the $ character MUST be prefixed by the \ (backslash) character  #
#------------------------------------------------------------------------------#

export OID_GET_BOOTDEV='.1.3.6.1.4.1.193.177.2.2.1.3.3.1.1.3.${slot}.512'
export OID_GET_BAUDRATE='.1.3.6.1.4.1.193.177.2.2.1.3.3.1.1.3.${slot}.512'
export OID_GET_MAC_BASE='.1.3.6.1.4.1.193.177.2.2.1.3.1.1.1.20.${slot}'
export OID_GET_MASTER='1.3.6.1.4.1.193.177.2.2.1.2.1.8.0'
export OID_GET_AUTONOMOUS='.1.3.6.1.4.1.193.177.2.2.1.2.1.7.0'
export OID_GET_PRODUCTID_ROJ='.1.3.6.1.4.1.193.177.2.2.1.3.1.1.1.2.${slot}'
export OID_GET_PRODUCTID_RSTATE='.1.3.6.1.4.1.193.177.2.2.1.3.1.1.1.3.${slot}'
export OID_GET_PRODUCTID_PNAME='.1.3.6.1.4.1.193.177.2.2.1.3.1.1.1.4.${slot}'
export OID_GET_PRODUCTID_SERIAL='.1.3.6.1.4.1.193.177.2.2.1.3.1.1.1.5.${slot}'
export OID_GET_PRODUCTID_DATE='.1.3.6.1.4.1.193.177.2.2.1.3.1.1.1.6.${slot}'
export OID_GET_PRODUCTID_VENDOR='.1.3.6.1.4.1.193.177.2.2.1.3.1.1.1.7.${slot}'

export OID_SET_BOOTDEV='.1.3.6.1.4.1.193.177.2.2.1.3.3.1.1.3.${slot}.512'
export OID_SET_BAUDRATE='.1.3.6.1.4.1.193.177.2.2.1.3.3.1.1.3.${slot}.512'
export OID_SET_MASTER='.1.3.6.1.4.1.193.177.2.2.1.2.1.3.0'
export OID_SET_POWER_ON='.1.3.6.1.4.1.193.177.2.2.1.3.1.1.1.43.${slot}'
export OID_SET_POWER_OFF='.1.3.6.1.4.1.193.177.2.2.1.3.1.1.1.43.${slot}'
export OID_SET_REBOOT='.1.3.6.1.4.1.193.177.2.2.1.3.1.1.1.12.${slot}'

# GEP5 revision
export OID_GET_BOOTDEV_v5='.1.3.6.1.4.1.193.177.2.2.1.3.1.1.1.48.${slot}'
export OID_GET_MAC_BASE_v5='.1.3.6.1.4.1.193.177.2.2.1.3.1.1.1.20.${slot}'
export OID_GET_MASTER_v5='1.3.6.1.4.1.193.177.2.2.1.2.1.8.0'
export OID_GET_AUTONOMOUS_v5='.1.3.6.1.4.1.193.177.2.2.1.2.1.7.0'
export OID_GET_PRODUCTID_ROJ_v5='.1.3.6.1.4.1.193.177.2.2.1.3.1.1.1.2.${slot}'
export OID_GET_PRODUCTID_RSTATE_v5='.1.3.6.1.4.1.193.177.2.2.1.3.1.1.1.3.${slot}'
export OID_GET_PRODUCTID_PNAME_v5='.1.3.6.1.4.1.193.177.2.2.1.3.1.1.1.4.${slot}'
export OID_GET_PRODUCTID_SERIAL_v5='.1.3.6.1.4.1.193.177.2.2.1.3.1.1.1.5.${slot}'
export OID_GET_PRODUCTID_DATE_v5='.1.3.6.1.4.1.193.177.2.2.1.3.1.1.1.6.${slot}'
export OID_GET_PRODUCTID_VENDOR_v5='.1.3.6.1.4.1.193.177.2.2.1.3.1.1.1.7.${slot}'
export OID_GET_GPR_RAM_REG='.1.3.6.1.4.1.193.177.2.2.1.3.3.1.1.3.${slot}.256'

export OID_SET_BOOTDEV_v5='.1.3.6.1.4.1.193.177.2.2.1.3.1.1.1.48.${slot}'
export OID_SET_MASTER_v5='.1.3.6.1.4.1.193.177.2.2.1.2.1.3.0'
export OID_SET_POWER_ON_v5='.1.3.6.1.4.1.193.177.2.2.1.3.1.1.1.43.${slot}'
export OID_SET_POWER_OFF_v5='.1.3.6.1.4.1.193.177.2.2.1.3.1.1.1.43.${slot}'
export OID_SET_REBOOT_v5='.1.3.6.1.4.1.193.177.2.2.1.3.1.1.1.12.${slot}'

export OID_SET_BIOS_IMAGE='.1.3.6.1.4.1.193.177.2.2.1.3.1.1.1.24.${slot}'
export OID_SET_BIOS_POINTER='.1.3.6.1.4.1.193.177.2.2.1.3.1.1.1.23.${slot}'
export OID_SET_GPR_RAM_REG='.1.3.6.1.4.1.193.177.2.2.1.3.3.1.1.3.${slot}.256'
