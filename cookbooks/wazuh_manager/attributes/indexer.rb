# Cookbook Name:: wazuh-manager
# Attributes:: indexer
# Author:: Wazuh <info@wazuh.com

# Wazuh Indexer connection configuration (required for vulnerability-detection since 4.8.0)
# https://documentation.wazuh.com/current/user-manual/reference/ossec-conf/indexer.html
default['ossec']['conf']['indexer'] = {
  'enabled' => false,
  'hosts' => {
    'host' => 'https://0.0.0.0:9200'
  },
  'ssl' => {
    'certificate_authorities' => {
      'ca' => '/etc/filebeat/certs/root-ca.pem'
    },
    'certificate' => '/etc/filebeat/certs/filebeat.pem',
    'key' => '/etc/filebeat/certs/filebeat-key.pem'
  }
}
