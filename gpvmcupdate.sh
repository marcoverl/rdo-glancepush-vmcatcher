#! /bin/bash
################################################################################
#                                                                              #
#                              gpvmcupdate.sh                                  ##                                                                              #
################################################################################
#
# author:    verlato@pd.infn.it
# date:      Friday 20 June 2014, 14:25 (UTC+0100)
# Copyright (c) 2014 INFN - "Istituto Nazionale di Fisica Nucleare" - Italy
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License. 
#
# usage: gpvmcupdate.sh
#
# purpose:
#  * to inform glancepush of images updates by using 
#    $VMCATCHER_EVENT_DC_IDENTIFIER as vmcatcher index
#    and automatically create the meta, test and
#    transform files for glancepush
#  * conversion from VMDK v3 (not supported by qemu-kvm 
#    version of RDO) to qcow2 v2 for those images published 
#    in AppDB marketplace in OVA format is implemented
#    (VirtualBox-4.3 required) 

metadir=/etc/glancepush/meta
testdir=/etc/glancepush/test
transformdir=/etc/glancepush/transform
spooldir=/var/spool/glancepush
rundir=/var/run/glancepush
vmcmapping=/etc/gpvmcmapping

source $vmcmapping

[ -z "$VMCATCHER_CACHE_DIR_CACHE" -o -z "$VMCATCHER_EVENT_DC_TITLE" -o -z "$VMCATCHER_EVENT_DC_IDENTIFIER" ] && { echo "some vmcatcher environment variables are not set"; exit 1; }

image=${vmcmapping["$VMCATCHER_EVENT_DC_IDENTIFIER"]}

# creating appropriate glancepush files
if [ "${VMCATCHER_EVENT_HV_FORMAT,,}" = "ova" ]; then
cat <<EOF >$metadir/$image
comment="$VMCATCHER_EVENT_DC_TITLE"
is_public="yes"
is_protected="yes"
disk_format="qcow2"
container_format="bare"
EOF
else
cat <<EOF >$metadir/$image
comment="$VMCATCHER_EVENT_DC_TITLE"
is_public="yes"
is_protected="yes"
disk_format="${VMCATCHER_EVENT_HV_FORMAT,,}"
container_format="bare"
EOF
fi
cat <<EOF >$testdir/$image
#! /bin/bash -xe
source /tmp/lib
check_iosched
check_no_embedded_swap
check_uptodate
check_no_passwords
check_no_ssh_keys
EOF
if [ "${VMCATCHER_EVENT_HV_FORMAT,,}" = "ova" ]; then
cat <<EOF >$transformdir/$image
#! /bin/sh
x=(\`tar xv\`)
VBoxManage clonehd \${x[1]} --format VDI \${x[1]}.vdi > /dev/null
/usr/bin/qemu-img convert -p -O qcow2 -c \${x[1]}.vdi \${x[1]}.qcow2 > /dev/null
cat \${x[1]}.qcow2
rm -f \${x[0]} \${x[1]} \${x[1]}.vdi \${x[1]}.qcow2 > /dev/null
EOF
else
cat <<EOF >$transformdir/$image
#! /bin/sh
cat
EOF
fi
# put images on the spool
echo "file=${VMCATCHER_CACHE_DIR_CACHE}${VMCATCHER_EVENT_DC_IDENTIFIER}" > "$spooldir/$image"
