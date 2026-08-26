default['ossec']['conf']['client']['server']['port'] = 1514
default['ossec']['conf']['client']['server']['protocol'] = 'tcp'
default['ossec']['conf']['client']['server']['max_retries'] = '5'
default['ossec']['conf']['client']['server']['retry_interval'] = '10'
default['ossec']['conf']['client']['notify_time'] = 20
default['ossec']['conf']['client']['time-reconnect'] = 60
default['ossec']['conf']['client']['auto_restart'] = true
default['ossec']['conf']['client']['crypto_method'] = "aes"
default['ossec']['conf']['client']['force_reconnect_interval'] = '0'
default['ossec']['conf']['client']['ip_update_interval'] = '0'

# server.address, enrollment.manager_address and enrollment.agent_name are
# deliberately left unset here. Attribute files of a dependency are evaluated
# before those of the wrapper cookbook, and role attributes are applied later
# still, so deriving them at this point would freeze the value before a consumer
# gets a chance to override node['ossec']['address']. Raising the precedence
# does not help either: it changes which value wins for a key, not when this
# file runs. wazuh_agent::common resolves them at converge time instead.

# Enrollment configuration (ossec.conf <client> -> <enrollment>)
# https://documentation.wazuh.com/current/user-manual/reference/ossec-conf/client.html
default['ossec']['conf']['client']['enrollment']['enabled'] = true
default['ossec']['conf']['client']['enrollment']['port'] = 1515
