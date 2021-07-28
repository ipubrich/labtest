#!/usr/bin/env python

# Modules
import jinja2
import json
import paramiko
import time


# Variables
paths = {
          'inventory': 'inventory/devices.json',
          'variables': 'custom_vars',
          'templates': 'jp_templates'
        }

vars_postfix = ['oc_ni']

verification = {
                 'oc_ni': {
                            'iosxr': ['show bgp ipv4 unicast summary'],
                            'eos': ['show bgp ipv4 unicast summary'],
                            'cumulus': ['net show bgp ipv4 unicast summary']
                          }
               }


# User-defined functions
def json_to_dict(path_to_JSON):
    """
    This function reads the data from the JSON file and converts it 
    to Python dictionary.
    """
    collected_data = open(path_to_JSON, 'r')
    new_dict = json.loads(collected_data.read())
    collected_data.close()

    return new_dict


def create_config(hostname, nos, config_template, l_paths):
    """
    This functions merges the device data model with Jinja2 template 
    to create final configuration.
    """
    file_with_template = open('{}/{}_{}.j2'.format(l_paths['templates'], nos, config_template), 'r')
    active_template = jinja2.Template(file_with_template.read())
    file_with_template.close()

    device_data_model = json_to_dict('{}/{}_{}.json'.format(l_paths['variables'], hostname, config_template))

    local_config = active_template.render(network_instances=device_data_model['network_instances'])

    return local_config


def config_device(connect_host, connect_user, connect_pass, 
                  connect_nos, connect_hostname, configuration,
                  operation_type):
    print('Starting {} operation for {}...'.format(operation_type, connect_hostname))

    get_connection_ready = paramiko.SSHClient()
    get_connection_ready.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    get_connection_ready.connect(hostname=connect_host, port=22, username=connect_user,  
                                 password=connect_pass,
                                 look_for_keys=False, allow_agent=False)

    active_connection = get_connection_ready.invoke_shell()
    time.sleep(1)

    for line in configuration:
        active_connection.send("{}\n".format(line))
        time.sleep(1)

        if operation_type == 'get':
            output = str(active_connection.recv(65535), encoding = 'utf-8').split('\r\n')

            for output_line in output:
                print(output_line)

    active_connection.close()

    print('{} operation for {} is done'.format(operation_type, connect_hostname))


# Body
devices = json_to_dict(paths['inventory'])

for device_entry in devices['devices']['device']:
    for postfix_entry in vars_postfix:
        device_config = create_config(device_entry['hostname'], device_entry['nos'], postfix_entry, paths)

        config_lines = device_config.splitlines()
        config_lines = list(filter(None, config_lines))

        config_device(device_entry['IPv4'], device_entry['username'], 
                      device_entry['password'], device_entry['nos'], 
                      device_entry['hostname'], config_lines, 'edit')

        config_device(device_entry['IPv4'], device_entry['username'],
                      device_entry['password'], device_entry['nos'],
                      device_entry['hostname'], verification[postfix_entry][device_entry['nos']], 'get')
