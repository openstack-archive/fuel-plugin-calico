#!/bin/sh

PWD=`pwd`

FUEL_VERSION=`rpm -q --info fuel | tr -s \[:space:\] | grep 'Version :' | awk -F': ' '{print $2}'`
if [ $FUEL_VERSION == '9.0.0' ] ; then
# Implement minor patch to l23network (included into 9.1, but not present in 9.0)
# For additional information see Openstack Bug #1590735
# or Change-Id: I89ef5630ab2dfd373b8cd4b7db481278c659db75

cd /etc/puppet/modules/l23network
patch -N -p4 <<EOF
diff --git a/deployment/puppet/l23network/lib/puppetx/l23_network_scheme.rb b/deployment/puppet/l23network/lib/puppetx/l23_network_scheme.rb
index 4f80daf..a2c1049 100644
--- a/deployment/puppet/l23network/lib/puppetx/l23_network_scheme.rb
+++ b/deployment/puppet/l23network/lib/puppetx/l23_network_scheme.rb
@@ -101,7 +101,13 @@
     transformations = org_tranformations.reject{|x| x[:action]=='override'}
     org_tranformations.select{|x| x[:action]=='override'}.each do |ov|
       next if ov[:override].nil?
-      tr_index = transformations.index{|x| x[:name]==ov[:override]}
+      pm = ov[:override].match(/patch-([\w\-]+)\:([\w\-]+)/)
+      if !pm.nil? and pm.size == 3
+        # we should override patch, to search patch use bridge names
+        tr_index = transformations.index{|x| x[:action]=='add-patch' and (x[:bridges]==[pm[1],pm[2]] or x[:bridges]==[pm[2],pm[1]])}
+      else
+        tr_index = transformations.index{|x| x[:name]==ov[:override]}
+      end
       next if tr_index.nil?
       ov.reject{|k,v| [:override, :action].include? k}.each do |k,v|
         if k == :'override-action' and v.to_s!=''
EOF
rc=$?
if [ $rc -gt 1 ] ; then
  echo
  echo "Can't patch l23network module. Chech whether 'patch' utility installed."
  echo "rc=$rc"
  echo
  echo "Use 'yum install -y patch' if not found"
  echo
  exit $rc
fi

fi
cd $PWD
