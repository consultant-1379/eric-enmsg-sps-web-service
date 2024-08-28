#!/bin/bash
#----------------------------------------------------------------------------
#############################################################################
# COPYRIGHT Ericsson 2021
# The copyright to the computer program herein is the property of
# conditions stipulated in the agreement/contract under which the
# program have been supplied.
#############################################################################
#----------------------------------------------------------------------------

# HTTP Pre-processing script

readonly GLOBAL_PROPERTIES="/ericsson/tor/data/global.properties"
readonly CREDM_DATA_XML="/ericsson/credm/data/xmlfiles/CredM-CLI-CertRequest-httpd.xml"
UI_PRES_SERVER_VALUE=""

echo "EXECUTION PRE-START SCRIPT for CredM-CLI-CertRequest-httpd.xml"
now=$(date +"%T")
echo "Current time : $now"
echo "-------------------"

echo "EXECUTION SCRIPTS IN PRE_START for CredM-CLI-CertRequest-httpd.xml at $now"

# READ FROM GLOBAL PROPERTIES
echo "check global.properties"
if [ -f "$GLOBAL_PROPERTIES" ]; then
    UI_PRES_SERVER_VALUE=$(grep UI_PRES_SERVER $GLOBAL_PROPERTIES | cut -d '=' -f 2-)
    echo "UI_PRES_SERVER value from $GLOBAL_PROPERTIES : $UI_PRES_SERVER_VALUE"
    if [ -z "$UI_PRES_SERVER_VALUE" ]; then
       echo "UI_PRES_SERVER not found in $GLOBAL_PROPERTIES"
       exit 1
    fi
else
    echo "$GLOBAL_PROPERTIES NOT FOUND"
    exit 1
fi

# CHECK THE PRESENCE of XML FILE AND UPDATE IT
echo "check and update CredM-CLI-CertRequest-httpd.xml"
if [ -f "$CREDM_DATA_XML" ]; then
    echo "Updating $CREDM_DATA_XML"
    cp ${CREDM_DATA_XML} /tmp/CredM-CLI-CertRequest-httpd.xml
    cat /tmp/CredM-CLI-CertRequest-httpd.xml | sed -e "s/FQDN/${UI_PRES_SERVER_VALUE}/g" >${CREDM_DATA_XML} 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "$CREDM_DATA_XML file updated succesfully"
    else
        echo "$CREDM_DATA_XML file update FAILED"
        rm /tmp/CredM-CLI-CertRequest-httpd.xml
        exit 1
    fi
    rm /tmp/CredM-CLI-CertRequest-httpd.xml
else
    echo "$CREDM_DATA_XML NOT FOUND"
    exit 1
fi

echo "END PRE-START SCRIPT for CredM-CLI-CertRequest-httpd.xml"
exit 0

