#!/bin/bash
#export ANSIBLE_SSH_ARGS="-F"
Red='\033[31m'
Green='\033[32m'
Orange='\033[33m'
Purple='\033[35m'
NC='\033[m'  #No color
# Nothing to change
file=osp_health_log-$(date +%F).log
echo ""
echo -e "${Orange}++++++++++++++++++++++++ Checking Services in cloud  $(date +%F_%H-%M-%S)++++++++++++++++++++++++++++++++++++++${NC}" | tee $file
echo ""
echo -e "${Green}Check Reachability of all nodes${NC}"
echo ""
ansible all -m ping|grep -v 'changed\|ansible_facts\|"discovered_interpreter_python"\|ping'
echo ""
echo -e "${Orange}Openstack Nodes Status---------------------------------------------------------- ${NC}"
echo -e "${Green}List all the nodes status of Overcloud${NC}" >> $file
echo  ""
servers=$(source ~/stackrc && openstack server list >> $file)
servers_down=$(source ~/stackrc && openstack server list | grep -i down | awk '{print $2}' ) 
if [ ! -z "$service_down" ]; then echo -e "${Red}Below mentioned Nodes are Down${NC}\n $servers_down"; else echo -e "${Green} All Nodes are in Running State${NC}"; fi
echo ""
echo -e "${Orange}Nova Service Check-------------------------------------------------------------- ${NC}" |tee -a $file
echo ""
compute_service=$(source ~/overcloudrc && openstack compute service list  >> $file)
compute_servicestatus=$(source ~/overcloudrc && openstack compute service list | grep -i down | awk '{print $2}')
if [ ! -z "$compute_servicestatus" ]; then echo -e "${Red}Below mentioned Nova services are down${NC}\n $compute_servicestatus"; else echo -e "${Green} All Nova services are in Running State${NC}"; fi
echo ""
echo -e "${Orange}Neutron agent status Check ------------------------------------------------------ ${NC}" |tee -a $file
echo ""
network_agent=$(source ~/overcloudrc && openstack network agent list >> $file)
network_agent_down_ID=$(source ~/overcloudrc && openstack network agent list | grep -i 'down' | awk '{print $2}' )
if [ ! -z "$network_agent_down_ID" ]; then echo -e "${Red}Below mentioned Neutron agents are down${NC}\n $network_agent_down_ID"; else echo -e "${Green} All Neutron agents are in Running State${NC}"; fi
echo ""
echo -e "${Orange}Cinder service agent status Check------------------------------------------------- ${NC}"|tee -a $file
echo ""
volume_service_down=$(source ~/overcloudrc && openstack volume service list | grep -i 'down' | sort )
volume_service=$(source ~/overcloudrc && openstack volume service list >> $file)
if [ ! -z "$volume_service_down" ]; then echo -e "${Red}Below mentioned Cinder Service Agents are down${NC}\n $volume_service_down"; else echo -e "${Green} All Cinder Service Agents are in Running State${NC}"; fi
echo ""
echo -e "${Orange}Corosync Cluster Check------------------------------------------------------------- ${NC}"|tee -a $file 
echo "Checks if all corosync members have joined the cluster and cluster health  ----------"
#echo "All members should be in joined state and the ring status should be active with no faults"
echo ""
#ansible 'controller' -m command -a "corosync-cmapctl "
echo ""
ansible 'controller' -m shell -a 'corosync-cfgtool -s ' |tee -a $file
echo ""
echo -e "${Orange}Pacemaker Cluster Check ------------------------------------------------------------ ${NC}"|tee -a $file
echo ""
ansible 'controller' -m command -a "pcs status cluster">> $file
pcs_cluster=$(ansible 'controller' -m command -a "pcs status cluster"|grep -i "offline\|inactive\|stopped")
if [ ! -z "$pcs_cluster" ]; then echo -e "${Red}Below mentioned clusters are down${NC}\n $pcs_cluster"; else echo -e "${Green} PCS cluster is in active state${NC}"; fi
echo ""
echo -e "${Orange}Pacemaker service Check ------------------------------------------------------------- ${NC}"|tee -a $file
#pacemaker_service=$(ansible 'controller' -m shell -a "crm_mon --group-by-node --inactive -1 | grep -v 'Started\|Master\|Slave\|online\|Resources'") 
pacemaker_service=$(ansible 'controller' -m shell -a "crm_mon --group-by-node --inactive -1 | grep -i 'No inactive resources'")
ansible 'controller' -m command -a "crm_mon --group-by-node --inactive -1 " >> $file
if [ ! -z "$pacemaker_service" ]; then echo -e "${Green}Pacemaker services are in active state${NC}"; else echo -e "${Red} Pacemaker services are in down state, Please verify log file${NC}"; fi
echo ""
echo -e "${Orange} List all down interfaces in Linux bond 0 on all Computes and Controllers --------------${NC}"|tee -a $file 
echo ""
ansible all -m shell -a "ip a|grep -i down|grep -i bond0"|grep -v 'non-zero return code\|FAILED' >> $file
bond0=$(ansible all -m shell -a "ip a|grep -i down|grep -i bond0"|grep -v 'non-zero return code\|FAILED')
if [ ! -z "$bond0" ]; then echo -e "${Red}Below interfaces are down${NC}\n $bond0"; else echo -e "${Green} All interfaces are UP${NC}"; fi
echo ""
echo -e "${Orange} List all down interfaces in Linux bond 1 on all Computes and Controllers --------------${NC}" |tee -a $file 
echo ""
bond1=$(ansible all -m shell -a "ip a|grep -i down|grep -i bond1"|grep -v 'non-zero return code\|FAILED')
if [ ! -z "$bond1" ]; then echo -e "${Red}Below interfaces are down${NC}\n $bond1"; else echo -e "${Green} All interfaces are UP${NC}"; fi
ansible all -m shell -a "ip a|grep -i down|grep -i bond1"|grep -v 'non-zero return code\|FAILED'>> $file
echo -e "${Orange} Bond0 Configuration of Controllers --------------${NC}" >> $file 
ansible 'controller' -m command -a "grep -i  'Slave Interface\|MII Status\|Aggregator ID' /proc/net/bonding/bond0 " >> $file
echo -e "${Orange} Bond1 Configuration of Controllers ---------------${NC}">> $file
ansible 'controller' -m command -a "grep -i 'Slave Interface\|MII Status\|Aggregator ID' /proc/net/bonding/bond1 ">> $file
echo -e "${Orange} Bond0 Configuration of Compute -----------------${NC}">> $file
ansible 'compute' -m command -a "grep -i  'Slave Interface\|MII Status\|Aggregator ID' /proc/net/bonding/bond0 ">> $file
echo -e "${Orange} Bond1 Configuration of Compute ------------------${NC}">> $file
ansible 'compute' -m command -a "grep -i  'Slave Interface\|MII Status\|Aggregator ID' /proc/net/bonding/bond1">> $file
#echo "--------- Looking for disk space usage for instances on Hypervisors hypervisor ------------------------------------------------------------"
#echo
#ansible 'compute' -m shell -a 'df -h | grep nova '
echo ""
echo -e "${Green}++++++++++++ System checks completed +++++++++++++++++++++${NC}"
echo ""
echo -e "${Purple}\033[4mPLEASE READ $file FOR MORE DETAILS\033[0m${NC}"
