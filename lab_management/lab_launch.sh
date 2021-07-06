#!/usr/bin/env bash

##
## 01 create bridges in var
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

# create bridges
function create_bridge() {
nmcli connection add type bridge con-name ${1} ifname ${1}
nmcli connection modify ${1} stp no
nmcli connection modify ${1} ipv4.method disabled
nmcli connection modify ${1} ipv6.method ignore
nmcli connection up ${1}
}

# Body
###### STEP 01 START ######
echo "$(date)//01 BRIDGES//Building bridges..." >> ${LOG_FILE} # timestamp beginning to file

EXISTING_BRIDGES=$(nmcli connection show > ${TEMP_FILE} && cat ${TEMP_FILE})
rm ${TEMP_FILE}

for BRIDGE in ${BRIDGES[@]}; do
    if [[ ${EXISTING_BRIDGES} =~ ${BRIDGE} ]]; then
    echo "01 Bridge ${BRIDGE} already exists"
    else
    create_bridge "${BRIDGE}"
    echo "01 Bridge ${BRIDGE} created"
    fi
done

echo "$(date)//01 BRIDGES//Completed..." >> ${LOG_FILE} # timestamp beginning to file
###### STEP 01 END   ######

###### STEP 02 START ######
echo "$(date)//02 DOCKER//Starting Docker..." >> ${LOG_FILE} # timestamp beginning to file
sudo systemctl status docker.service > ${TEMP_FILE}
CHECK_DOCKER=$(cat ${TEMP_FILE} | grep "Active")
rm ${TEMP_FILE}

if [[ ${CHECK_DOCKER} =~ 'inactive' ]]; then
    echo "02 Starting Docker service"
        sudo systemctl start docker.service
else
    echo "02 Docker service is already running"
fi
echo "$(date)//02 DOCKER//Completed..." >> ${LOG_FILE} # timestamp end to file
###### STEP 02 END  ######

###### STEP 03 START ######
echo "$(date)//03 CONTAINERS//Starting Containers..." >> ${LOG_FILE} # timestamp beginning to file

ALL_CONTAINERS=$(sudo docker container ls --all)

for CONTAINER in ${CONTAINERS[@]}; do
    if [[ ${ALL_CONTAINERS} =~ ${CONTAINER} ]]; then
        echo "03 The container ${CONTAINER} exists. Checking operational state."
        CONTAINER_LINE=$(echo "${ALL_CONTAINERS}" | awk '/Up/ {print $8}') # check for Up
            if [[ ${CONTAINER_LINE} == "Up" ]]; then
            echo "03 The container ${CONTAINER} is already active."
            else
            echo "03 Container ${CONTAINER} is down, bringing up"
            sudo docker container start ${CONTAINER}
            fi
    else
        echo "03 Container ${CONTAINER} does NOT exist. Create or check the VARS files" >> ${LOG_FILE}

       
    fi
done
echo "$(date)//03 CONTAINERS//Completed..." >> ${LOG_FILE} # timestamp end to file
###### STEP 03 END  ######

###### STEP 04 START ######
echo "$(date)//04 VM//Starting VMS..." >> ${LOG_FILE} # timestamp beginning to file

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
            echo "04 VM ${VM} is already running"
            else
            echo "04 Starting VM ${VM}"
            sudo virsh start ${VM} >> /dev/null # hide on cli 
            fi
               
    else
    echo "04 VM ${VM} does NOT exist. Create or check the VM files" >> ${LOG_FILE}
    echo "04 Attempting to build ${VM} from known config"
    ./VM/${VM}.sh ${VM}  >> /dev/null # hide on cli 
    fi
done

echo "$(date)//04 VMS//Completed..." >> ${LOG_FILE} # timestamp end to file
###### STEP 04 END    ######

###### STEP 05 START  ######
echo "$(date): 05 // Modifying iptables" >> ${LOG_FILE} # timestamp end to file
echo "05 Updating iptables"
sudo iptables -I FORWARD 1 -s 10.0.0.0/8 -d 10.0.0.0/8 -j ACCEPT
echo "$(date): 05 // Complete." >> ${LOG_FILE} # timestamp end to file
###### STEP 05 END  ######