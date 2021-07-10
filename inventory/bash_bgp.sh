#!/usr/bin/bash
# This Script aims to read the devices' inventory from the JSON file,
# collect the BGP summary from those devices,
# and create a report in the vendor independent format

# Prerequsites
# jq

# Variables
INVENTORY='devices.json'
TEMP_DIR='/tmp/bash_bgp'
RESULT_DIR='output'

# User-defined functions

# pushing json device data to nodes
function collect_data() {
echo "COLLECTED  - ${1} ${2} ${3}"

# set node details based on NOS
case ${3} in
    'Cisco XR-V')
        USERNAME="cisco"
        PASSWORD="cisco"
        COMMAND="show ip bgp summary"
        ;;
    'Arista EOS')
        USERNAME="admin"
        PASSWORD="admin"
        COMMAND="show ip bgp summary"
        ;;
    'Cumulus Linux')
        USERNAME="cumulus"
        PASSWORD="CumulusLinux!"
        COMMAND="net show bgp summary"
        ;;
esac

echo "Collecting BGP status for ${1} ... "
touch "${TEMP_DIR}/${1}_raw_data.txt"
echo "command : ${COMMAND}  user : ${USERNAME} IP : ${2}"
ssh ${USERNAME}@${2} "${COMMAND}" > "${TEMP_DIR}/${1}_raw_data.txt"
}

function parse_data() {
echo "Parsing : ${1} ${2}"
touch "${RESULT_DIR}/${1}_result.yaml"
echo "${RESULT_DIR}/${1}_result.yaml"
echo "---" > "${RESULT_DIR}/${1}_result.yaml"
echo "bgp:" >> "${RESULT_DIR}/${1}_result.yaml"
echo " address_family:" >> "${RESULT_DIR}/${1}_result.yaml"
echo "   - afi: ipv4" >> "${RESULT_DIR}/${1}_result.yaml"
echo "     safi: unicast" >> "${RESULT_DIR}/${1}_result.yaml"
echo "     neighbors:" >> "${RESULT_DIR}/${1}_result.yaml"



input="${TEMP_DIR}/${1}_raw_data.txt"
while read -r LINE; do

    case ${2} in
        'Cisco XR-V')
            NEIGHBOR_IP=$(echo "${LINE}" | awk '/^[0-9]/ {print $1}')
            NEIGHBOR_ASN=$(echo "${LINE}" | awk '/^[0-9]/ {print $3}')
            NEIGHBOR_STATE=$(echo "${LINE}" | awk '/^[0-9]/ {print $10}');;
        'Arista EOS')
            NEIGHBOR_IP=$(echo "${LINE}" | awk '/^ [0-9]/ {print 1}')
            NEIGHBOR_ASN=$(echo "${LINE}" | awk '/^ [0-9]/ {print 1}')
            NEIGHBOR_STATE=$(echo "${LINE}" | awk '/^ [0-9]/ {print 1}');;
        'Cumulus Linux')
            NEIGHBOR_IP=$(echo "${LINE}" | awk '/^[0-9]/ {print $1}')
            NEIGHBOR_ASN=$(echo "${LINE}" | awk '/^[0-9]/ {print $3}')
            NEIGHBOR_STATE=$(echo "${LINE}" | awk '/^[0-9]/ {print $10}');;
    esac
    if [[ ${NEIGHBOR_IP} != '' ]]; then
        echo "LINE HERE ${LINE}"
        echo "${NEIGHBOR_IP}"
        echo "      - neighbor: ${NEIGHBOR_IP}" >> "${RESULT_DIR}/${1}_result.yaml"
        echo "        peer_as: ${NEIGHBOR_ASN}" >> "${RESULT_DIR}/${1}_result.yaml"
        echo "        state: ${NEIGHBOR_STATE}" >> "${RESULT_DIR}/${1}_result.yaml"
        else
        :
    fi
    
done < "$input"

echo "..." >> "${RESULT_DIR}/${1}_result.yaml"
}

# Main body

### STEP 01 convert json to bash ###
DEVICES_TO_CHECK=$(cat ${INVENTORY} | jq '."devices"."amount"')
echo "Found ${DEVICES_TO_CHECK} devices"

for STEP in $(seq 0 ${DEVICES_TO_CHECK}); do
HOST=$(cat devices.json | jq ".\"devices\".\"device\"[${STEP}].\"hostname\"" | sed -e 's/"//g')
IP=$(cat devices.json | jq ".\"devices\".\"device\"[${STEP}].\"IPv4\"" | sed -e's/"//g')
NOS=$(cat devices.json | jq ".\"devices\".\"device\"[${STEP}].\"nos\"" | sed -e's/"//g')

if  [[ ${HOST} != 'null' ]]; then 
    echo "JSON FOUND - ${HOST} ${IP} ${NOS}"
        if [[ ! -d "${TEMP_DIR}" ]]; then
        echo "Creating temp dir ${TEMP_DIR}"
        sudo mkdir "${TEMP_DIR}"
        sudo mkdir "${RESULT_DIR}"
        else
        :
        fi
    
    collect_data "${HOST}" "${IP}" "${NOS}" # take outputs and pipe to a file
    parse_data "${HOST}" "${NOS}" # parse into yaml
    echo ""
    else
    :
    fi
done