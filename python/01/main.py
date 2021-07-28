#!/usr/bin/env python

# Modules
# allows operating system calls
import os 
import json
import pprint

# Variables
path_inventory_str = "./inventory"

# Functions

# This function reads the filenames in the inventory
def get_inventory(file_path_str: str) -> dict:
    devices_list = os.listdir(path=file_path_str)
    print(devices_list)
    print(file_path_str)
    result = {}     # convert output of filenames to dict
    
    for device_str in devices_list:
        # print(device_str.split('.')) # outputs the file extension tho
        # one way to do it    result[device_str.split('.')[0]] = {}
        # result.update({device_str.split('.')[0]: {}})

        f = open(f"{file_path_str}/{device_str}", "r") # open all files
        # print(f.read())
        #convert  to dict
        if device_str.split('.')[1] == "json":
            #result.update({device_str.split('.')[0]: json.loads(f.read())})
        f.close()

    return result

# Body
inventory = get_inventory(file_path_str=path_inventory_str)

print(inventory)
