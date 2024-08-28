#------------------------------------------------------------------------------#
# ROJ 208 323                                                                  #
# OIDs to be used in a SCB-based EGEM magazine.                                #
#------------------------------------------------------------------------------#
# NOTES: - This file is intended to be sourced by the shelfmngr routines so it #
#        MUST be compliant with the bash syntax.                               #
#        - The right values of the variables below MUST match one of the       #
#        following conditions:                                                 #
#          1) they have to be strong-quoted (single-quoted)                    #
#          2) the $ character MUST be prefixed by the \ (backslash) character  #
#------------------------------------------------------------------------------#

export OID_GET_BOOTDEV='.1.3.6.1.4.1.193.154.2.1.2.2.1.1.2.${slot}.128'
export OID_GET_BAUDRATE='.1.3.6.1.4.1.193.154.2.1.2.2.1.1.2.${slot}.128'
export OID_GET_MAC_BASE='.1.3.6.1.4.1.193.154.2.1.2.1.1.1.2.${slot}'
export OID_GET_MAC_ETH3='.1.3.6.1.4.1.193.154.2.1.2.1.1.1.3.${slot}'
export OID_GET_MAC_ETH4='.1.3.6.1.4.1.193.154.2.1.2.1.1.1.4.${slot}'
export OID_GET_MASTER='.1.3.6.1.4.1.193.154.2.1.2.1.1.1.12.${slot}'
export OID_GET_PRODUCTID='.1.3.6.1.4.1.193.154.2.1.2.1.1.1.5.${slot}'

export OID_SET_BOOTDEV='.1.3.6.1.4.1.193.154.2.1.2.2.1.1.2.${slot}.128'
export OID_SET_BAUDRATE='.1.3.6.1.4.1.193.154.2.1.2.2.1.1.2.${slot}.128'
export OID_SET_MASTER='.1.3.6.1.4.1.193.154.2.1.2.1.1.1.12.${slot}'
export OID_SET_POWER_ON='.1.3.6.1.4.1.193.154.2.1.2.1.1.1.11.${slot}'
export OID_SET_POWER_OFF='.1.3.6.1.4.1.193.154.2.1.2.1.1.1.10.${slot}'
export OID_SET_REBOOT='.1.3.6.1.4.1.193.154.2.1.2.1.1.1.9.${slot}'

# GEP5 revision
export OID_GET_BOOTDEV_v5='.1.3.6.1.4.1.193.154.2.1.2.1.1.1.28.${slot}'
export OID_GET_MAC_BASE_v5='.1.3.6.1.4.1.193.154.2.1.2.1.1.1.2.${slot}'
export OID_GET_MAC_ETH3_v5='.1.3.6.1.4.1.193.154.2.1.2.1.1.1.3.${slot}'
export OID_GET_MAC_ETH4_v5='.1.3.6.1.4.1.193.154.2.1.2.1.1.1.4.${slot}'
export OID_GET_MASTER_v5='.1.3.6.1.4.1.193.154.2.1.2.1.1.1.12.${slot}'
export OID_GET_PRODUCTID_v5='.1.3.6.1.4.1.193.154.2.1.2.1.1.1.5.${slot}'
export OID_GET_GPR_RAM_REG='.1.3.6.1.4.1.193.154.2.1.2.2.1.1.2.${slot}.64'

export OID_SET_BOOTDEV_v5='.1.3.6.1.4.1.193.154.2.1.2.1.1.1.28.${slot}'
export OID_SET_MASTER_v5='.1.3.6.1.4.1.193.154.2.1.2.1.1.1.12.${slot}'
export OID_SET_POWER_ON_v5='.1.3.6.1.4.1.193.154.2.1.2.1.1.1.11.${slot}'
export OID_SET_POWER_OFF_v5='.1.3.6.1.4.1.193.154.2.1.2.1.1.1.10.${slot}'
export OID_SET_REBOOT_v5='.1.3.6.1.4.1.193.154.2.1.2.1.1.1.9.${slot}'
export OID_SET_BIOS_IMAGE='.1.3.6.1.4.1.193.154.2.1.2.1.1.1.19.${slot}'
