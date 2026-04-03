# Cookbook Name:: wazuh-manager
# Attributes:: auth
# Author:: Wazuh <info@wazuh.com

# Registration service - Authd settings (Manager)
default['ossec']['conf']['auth'] = {
    'disabled' => false,
    'port' => 1515,
    'use_source_ip' => false,
    'purge' => true,
    'use_password' => false,
    'ciphers' => 'HIGH:!ADH:!EXP:!MD5:!RC4:!3DES:!CAMELLIA:@STRENGTH',
    'ssl_verify_host' => false,
    'ssl_manager_cert' => "#{node['ossec']['dir']}/etc/sslmanager.cert",
    'ssl_manager_key' => "#{node['ossec']['dir']}/etc/sslmanager.key",
    'ssl_auto_negotiate' => false,
    'force' => {
        'enabled' => true,
        'after_registration_time' => '0',
        'key_mismatch' => true,
        'disconnected_time' => {
            '@enabled' => true,
            'content!' => '1h'
        }
    }
}