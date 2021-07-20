#!/usr/bin/env bash

##
## 01 remove bridges in var
## 02 bring up docker
## 03 bring up containers in var
## 04 build VM's
## 05 update iptable rules
##

# Variables
LOG_FILE="./log.txt" ### LOG FILE
BRIDGES=('br111' 'br112' 'br113' 'br114' 'br115')
CONTAINERS=('nnat_ftp')
TEMP_FILE='/tmp/lab_management.txt'

# User-defined functions

# delete bridges
function delete_bridge() {
nmcli connection down ${1}
nmcli connection delete id ${1}
}

# Body
###### STEP 01 START ######
echo "$(date)//01 BRIDGES//Burning bridges..." >> ${LOG_FILE} # timestamp beginning to file

EXISTING_BRIDGES=$(nmcli connection show > ${TEMP_FILE} && cat ${TEMP_FILE})
rm ${TEMP_FILE}

for BRIDGE in ${BRIDGES[@]}; do
    if [[ ${EXISTING_BRIDGES} =~ ${BRIDGE} ]]; then
    delete_bridge "${BRIDGE}"
    echo "01 Bridge ${BRIDGE} deleted"
    
    else
    echo "01 Bridge ${BRIDGE} does not exist."
    fi
done

echo "$(date)//01 BRIDGES//Completed..." >> ${LOG_FILE} # timestamp beginning to file
###### STEP 01 END   ######

###### STEP 02 START ######
echo "$(date)//02 DOCKER//Stopping Docker..." >> ${LOG_FILE} # timestamp beginning to file
sudo systemctl stop docker.service > ${TEMP_FILE}
CHECK_DOCKER=$(cat ${TEMP_FILE} | grep "Active")
rm ${TEMP_FILE}

if [[ ${CHECK_DOCKER} =~ 'inactive' ]]; then
    echo "02 Stopping Docker service"
        sudo systemctl stop docker.service
else
    echo "02 Docker service has already stopped"
fi
echo "$(date)//02 DOCKER//Completed..." >> ${LOG_FILE} # timestamp end to file
###### STEP 02 END  ######

###### STEP 03 START ######
echo "$(date)//03 CONTAINERS//Stopping Containers..." >> ${LOG_FILE} # timestamp beginning to file

ALL_CONTAINERS=$(sudo docker container ls --all)

for CONTAINER in ${CONTAINERS[@]}; do
    if [[ ${ALL_CONTAINERS} =~ ${CONTAINER} ]]; then
        echo "03 The container ${CONTAINER} exists. Checking operational state."
        CONTAINER_LINE=$(echo "${ALL_CONTAINERS}" | awk '/Up/ {print $8}') # check for Up
            if [[ ${CONTAINER_LINE} == "Up" ]]; then
            echo "03 Container ${CONTAINER} is up, bringing down"
            sudo docker container stop ${CONTAINER}
            else
            echo "03 The container ${CONTAINER} is already inactive"
            fi
    else
        echo "03 Container ${CONTAINER} does NOT exist. delete or check the VARS files" >> ${LOG_FILE}
       
    fi
done
echo "$(date)//03 CONTAINERS//Completed..." >> ${LOG_FILE} # timestamp end to file
###### STEP 03 END  ######

###### STEP 04 START ######
echo "$(date)//04 VM//Stopping VMS..." >> ${LOG_FILE} # timestamp beginning to file

EXISTING_VMS=$(sudo virsh list --all)
# > ${TEMP_FILE} && cat ${TEMP_FILE})
#rm ${TEMP_FILE}
# LAB_VMS=($(ls -l VM | awk '/ipub/ {print $9}' | sed -e 's/\.sh//g')) # overcomplicated

LAB_VMS=($(ls VM | sed -e 's/\.sh//'))          # drop .sh from the files you found in the folder
echo "04 LAB VM files found for : ${LAB_VMS[@]}" # list

for VM in ${LAB_VMS[@]}; do
    if [[ ${EXISTING_VMS} =~ ${VM} ]]; then
    echo "04 The VM ${VM} exists. Checking operational state."
        VM_LINE=$(echo "${EXISTING_VMS}" | grep "${VM}") # check for Up
            if [[ ${VM_LINE} =~ "running" ]]; then
              echo "04 Stopping VM ${VM}"
            sudo virsh destroy ${VM} >> /dev/null # hide on cli 
            # sudo virsh undefine ${VM} >> /dev/null # hide on cli 
            else
            echo "04 VM ${VM} is already stopped"
            fi
               
    else
    echo "04 VM ${VM} does NOT exist. delete or check the VM files" >> ${LOG_FILE}
    fi
done

echo "$(date)//04 VMS//Completed..." >> ${LOG_FILE} # timestamp end to file
###### STEP 04 END    ######

###### STEP 05 START  ######
echo "$(date): 05 // Modifying iptables" >> ${LOG_FILE} # timestamp end to file
echo "05 Updating iptables"
sudo iptables -D FORWARD 1
echo "$(date): 05 // Complete." >> ${LOG_FILE} # timestamp end to file
###### STEP 05 END  ######