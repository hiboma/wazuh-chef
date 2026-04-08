# Wazuh roles

1. **wazuh_agent**: Wazuh Agent

## Important attributes

### wazuh-manager

**How to bind a specific IP address to manager?**

In case you have a non single-node installation and want to bind a specific IP address to the manager,
the following attributes must be overridden:

* ```node['api']['ip']```: the IP address bound to the API
* ```node['api']['port']```: the port bound to the API
