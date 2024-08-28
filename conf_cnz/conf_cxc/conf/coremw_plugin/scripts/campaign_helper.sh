#!/bin/bash

procInit() {
    # Specify the fictional MDF model type APOS-COM_R1 and APOS-IMM_R1.
    # Other APG components will deliver models by using the 
    # convention APOS-COM_R1-model.config and APOS-IMM_R1-model.config.
    # In this way:
    #   1) APOS will deliver MP files and IMM Class definitions and top IMM instances.
    #   2) All the rest will deliver MP files and IMM files once APOS models have been delivered.
    cmw-modeltype-link "APOS-COM_R1 COM_R1"
    cmw-modeltype-link "APOS-IMM_R1 IMM_R1"
}

procWrapup() {
    /bin/true
}

case $1 in
    init)
        procInit
        ;;
    wrapup)
        procWrapup
        ;;
esac
