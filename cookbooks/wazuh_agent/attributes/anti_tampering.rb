# Cookbook Name:: wazuh-agent
# Attributes:: anti_tampering
# Author:: Wazuh <info@wazuh.com

# Anti-tampering configuration (added in Wazuh 4.10.0)
# Prevents unauthorized uninstallation of the agent on Linux
# https://documentation.wazuh.com/current/user-manual/reference/ossec-conf/anti-tampering.html
default['ossec']['conf']['anti_tampering'] = {
  'enabled' => false
}
