#!/usr/bin/bash
#
# Copyright (c) 2011, Joyent Inc. All rights reserved.
#

export PS4='[\D{%FT%TZ}] ${BASH_SOURCE}:${LINENO}: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
set -o xtrace
#set -o errexit

PATH=/opt/local/bin:/opt/local/sbin:/usr/bin:/usr/sbin

role=sdc
app_name=$role

CONFIG_AGENT_LOCAL_MANIFESTS_DIRS=/opt/smartdc/$role

# Include common utility functions (then run the boilerplate)
source /opt/smartdc/sdc-boot/lib/util.sh
sdc_common_setup

# Cookie to identify this as a SmartDC zone and its role
mkdir -p /var/smartdc/sdc

# Add the main bin dir to the PATH.
# Note: we do NOT want the $role/node_modules/.bin dir on the PATH because
# we install 'node-smartdc' there to have it available, but we don't want
# all those 'sdc-*' commands on the default PATH.
echo "" >>/root/.profile
echo "export MANPATH=\${MANPATH}:/opt/smartdc/${role}/man" >>/root/.profile
echo "export PATH=/opt/smartdc/$role/bin:/opt/smartdc/$role/build/node/bin:\$PATH" >>/root/.profile
echo '[[ -f $HOME/.sdc_mantaprofile ]] && source $HOME/.sdc_mantaprofile' >>/root/.profile

# Setup crontab
crontab=/tmp/$role-$$.cron
crontab -l > $crontab
[[ $? -eq 0 ]] || fatal "Unable to write to $crontab"
echo '' >>$crontab
echo '0 * * * * /opt/smartdc/sdc/tools/dump-sdc-data.sh >>/var/log/dump-sdc-data.log 2>&1' >>$crontab
echo '10 * * * * /opt/smartdc/sdc/tools/upload-sdc-data.sh >>/var/log/upload-sdc-data.log 2>&1' >>$crontab
crontab $crontab
[[ $? -eq 0 ]] || fatal "Unable import crontab"
rm -f $crontab

# Log rotation for those sdc-data scripts.
logadm -w sdc-data -C 3 -c -s 1m '/var/log/*-sdc-data.log'

# Install Amon probes for the sdc zone.
TRACE=1 /opt/smartdc/sdc/tools/sdc-amon-install

# All done, run boilerplate end-of-setup
sdc_setup_complete

exit 0