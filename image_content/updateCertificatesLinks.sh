#!/bin/bash
#*******************************************************************************
# Version 1.0
# COPYRIGHT Ericsson 2023
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
#********************************************************************************
#
# Last revision: 2023-12-12
#

# UTILITIES
_GREP=/bin/grep
_SED=/bin/sed
_CHMOD=/bin/chmod
_ECHO=/bin/echo
_TOUCH=/bin/touch
_CAT=/bin/cat
_LN=/bin/ln
_MV=/bin/mv
_RM=/bin/rm


if [ -d /var/tmp ]; then
  LOG_DIR=/var/tmp
else
  LOG_DIR=/tmp
fi
LOG=$LOG_DIR/updateCertificatesLinks.log

$_TOUCH $LOG

my_logger() {
  d=$(date)
  $_ECHO "$d $1" | tee -a $LOG
}
#
readonly dt=$(date +%s)
#
readonly script_name=$0
readonly release=$($_GREP '^# Last revision:' $script_name | $_SED 's/^# Last revision://')
readonly version=$($_GREP '^# Version' $script_name | $_SED 's/^# Version//')
if $_GREP -q "Starting" $LOG /dev/null 2>/dev/null ; then
  if $_GREP -q "Last run" $LOG ; then
    $_SED -i "s/.*Last run/$dt Last run/" $LOG
  else
    my_logger "Last run"
  fi
else
  my_logger "Starting $script_name release: $release version: $version"
fi
#
runscript_list=''
#
run_script() {
  cert=$1
  if [ -f $cert ]; then
    for rs in $runscript_list
    do
      my_logger "Processing $rs entry"
      local c=$($_ECHO "$rs" | $_SED 's/:.*//')
      local s=$($_ECHO "$rs" | $_SED 's/.*://')
      if [ "$c" == "$cert" ]; then
        if [ -f $s ]; then
          if [ ! -f $cert.run ]; then
            $_TOUCH $cert.run
          fi
          if $_GREP -q "running $s at time $dt" $LOG; then
            my_logger "skipping $s because already run at time $dt"
          else
            my_logger "running $s at time $dt"
            $_CHMOD a+x $s
            $s
          fi
        fi
      fi
    done
  fi
  if $_GREP -q "$s" $cert.run ; then
    $_SED -i "s,.*$s,$dt $s," $cert.run
  else
    $_ECHO "$dt $s" >> $cert.run
  fi
}
#
#
DEFAULT_TLS_MOUNT_PATH='/ericsson/credm/tlsMount'
if [ -z "$TLS_MOUNT_PATH" ]; then
  if ! $_GREP -q "TLS_MOUNT_PATH not defined" $LOG ; then
    my_logger "TLS_MOUNT_PATH not defined, using default value: $DEFAULT_TLS_MOUNT_PATH"
  fi
  TLS_MOUNT_PATH="$DEFAULT_TLS_MOUNT_PATH"
fi
#
# from deployment.yaml
readonly TLS_DIR=$TLS_MOUNT_PATH
readonly TLS_LOCATION=tlsStoreLocation
readonly TLS_DATA=tlsStoreData

# Update links to keystores
d=$(date)

for  _secret_mount_ in ${TLS_DIR}/*
do
    if [ -d ${_secret_mount_} ]
    then
      tlsFilename=$($_CAT ${_secret_mount_}/${TLS_LOCATION})
      cksumFile=$tlsFilename.cksum
      if [ ! -f ${tlsFilename} ]; then
        my_logger "MAKE MISSING LINK ${tlsFilename}"
        $_LN -s ${_secret_mount_}/${TLS_DATA} ${tlsFilename}
      fi
      csum=$(cksum $tlsFilename | $_SED 's/ .*//')
      if [ -f $cksumFile ]; then
        if $_GREP -q "^Checksum:" $cksumFile ; then
          csum_old=$($_GREP "^Checksum:" $cksumFile | sed 's/Checksum://')
          if [ "$csum" != "$csum_old" ]; then
            my_logger "RENEW LINK ${tlsFilename}"
            $_MV ${tlsFilename} ${tlsFilename}.old
            $_LN -s ${_secret_mount_}/${TLS_DATA} ${tlsFilename}
            $_RM ${tlsFilename}.old
            my_logger "UPDATING CKSUM LINE ON $cksumFile"
            $_SED -i "s/^Checksum:.*/Checksum:$csum/" $cksumFile
            run_script ${tlsFilename}
          fi
        else
          my_logger "ADDING CKSUM LINE ON $cksumFile"
          $_ECHO "" >> $cksumFile
          $_SED -i "1 i Checksum:$csum" $cksumFile
        fi
      else
        my_logger "CREATING CKSUM FILE $cksumFile"
        $_ECHO "Checksum:$csum" > $cksumFile
      fi
    fi
done

exit 0
