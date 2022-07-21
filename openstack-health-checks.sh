#!/bin/bash

#export ANSIBLE_SSH_ARGS="-F"


#Enter the path to the openstack rc file below
source /home/stackrc/overcloudrc

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "+++++++++++++++++++++++++++++++++++++++++ Checking Services in cloud +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

echo "--------- Corosync Cluster Check ------------------------------------------------------------------------------------------------"
echo "--------- Checks if all corosync members have joined the cluster and cluster health  --------------------------------------------"
echo "--------- All members should be in joined state and the ring status should be active with no faults------------------------------"
ansible 'controller' -m shell -a "sudo corosync-cmapctl | grep members" -i inventory
echo
ansible 'controller' -m shell -a "sudo corosync-cfgtool -s" -i inventory
echo
echo "--------- Pacemaker Cluster Check ------------------------------------------------------------------------------------------------"
echo "--------- Checks if all pacemaker members have joined the cluster and cluster health  --------------------------------------------"
echo
ansible 'controller' -m shell -a "sudo pcs cluster status" -i inventory
echo
echo "--------- Pacemaker service Check ------------------------------------------------------------------------------------------------"
echo "--------- Checks for inactive resources group by OS Controllers and failed services  ------ -------------------------------------------------"
ansible 'controller' -m shell -a "sudo crm_mon --group-by-node --inactive -1 | grep -v Started" -i inventory
echo
echo "--------- openstack container service Check -----------------------------------------------------------------------------"
echo "--------- List service marked as failed  ------------------------------------------------------------------------------"
#ansible 'controller' -m shell -a "sudo podman ps| grep failed" -i inventory.yaml
echo
echo "--------- Nova Service Check -----------------------------------------------------------------------------------------------------"
echo "--------- Check for any down Nova Services ---------------------------------------------------------------------------------------"
echo
openstack compute service list | grep down | sort
echo
echo "--------- Neutron agent status Check ---------------------------------------------------------------------------------------------"
echo "--------- Checks for any hypervisors/netnodes with any Neutron agents down -------------------------------------------------------"
echo
openstack network agent list | grep -v ':-)' | sort
echo
echo
echo "--------- Cinder service agent status Check --------------------------------------------------------------------------------------"
echo "--------- Checks for any cinder services showing own -----------------------------------------------------------------------------"
openstack volume service list | grep down
echo
echo "--------- Looking for down interfaces in Linux bond 0 on OS Controllers -------------------------------------------------------------"
echo "--------- No output means no interface is down ------------------------------------------------------------------------------------"
echo
ansible 'controller' -m shell -a "cat /proc/net/bonding/bond0 | grep -i 'link'| egrep '1'" -i inventory.yaml
echo
echo "--------- Looking for down interfaces in Linux bond 1 on OS Controllers -------------------------------------------------------------"
echo "--------- No output means no interface is down ------------------------------------------------------------------------------------"
echo
ansible 'controller' -m shell -a "cat /proc/net/bonding/bond1 | grep -i 'link'| egrep '1'" -i inventory.yaml
echo
echo "--------- Looking for down interfaces in Linux bond 0 on Hypervisors -------------------------------------------------------------"
echo "--------- No output means no interface is down ------------------------------------------------------------------------------------"
echo
ansible 'compute' -m shell -a "cat /proc/net/bonding/bond0 | grep -i 'link'| egrep '1'" -i inventory.yaml
echo
echo "--------- Looking for down interfaces in Linux bond 1 on Hypervisors -------------------------------------------------------------"
echo "--------- No output means no interface is down ------------------------------------------------------------------------------------"
echo
ansible 'compute' -m shell -a "cat /proc/net/bonding/bond1 | grep -i 'link'| egrep '1'" -i inventory.yaml
echo
#echo "--------- Looking for disk space usage for instances on Hypervisors hypervisor ------------------------------------------------------------"
#echo
#ansible 'hypervisors' -m shell -a 'df -h | grep nova' -i inventory.yaml
#echo
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++ System checks completed +++++++++++++++++++++++++++++++++++++++++++++++++++++"


