# Wazuh - Chef (fork)

This repository is a fork of [wazuh/wazuh-chef](https://github.com/wazuh/wazuh-chef), which has been **archived (public archive)** by the upstream maintainers and is no longer maintained.

This fork maintains **wazuh_agent** and **wazuh_manager** cookbooks only for internal use. The following components from the original repository have been removed and are not maintained:

- elastic-stack (Elasticsearch + Kibana)
- opendistro (Open Distro for Elasticsearch)
- filebeat
- filebeat-oss

## Cookbooks

* [Wazuh Agent](cookbooks/wazuh_agent)
* [Wazuh Manager](cookbooks/wazuh_manager)

## Using an older Wazuh version

By default, the cookbooks install the latest supported Wazuh version. To install an older version, override the version attributes:

```ruby
node['wazuh']['patch_version'] = "4.13.1"
node['wazuh']['minor_version'] = "4.13"
```

## Installation

### Use through Berkshelf

Include the desired cookbooks in your `Berksfile`:

```ruby
cookbook "wazuh_agent", git: "https://github.com/hiboma/wazuh-chef.git", rel: 'cookbooks/wazuh_agent'
cookbook "wazuh_manager", git: "https://github.com/hiboma/wazuh-chef.git", rel: 'cookbooks/wazuh_manager'
```

You can specify tags, branches, and revisions. More info on https://docs.chef.io/berkshelf.html

### Secrets

The following describes how to define the needed JSON files to generate an encrypted data bag.

**Important**: If API user secret is declared it will be installed. Otherwise, the default user will be *foo:bar*.

#### api.json

It contains the username and password that will be installed for Wazuh API authentication. It is required by the manager.

Example of a configuration file `api_configuration.json` before encryption:

```json
{
 "id": "api",
 "htpasswd_user": "<YOUR USER>",
 "htpasswd_passcode": "<YOUR PASSWORD>"
}
```

### Using Data Bags

To transfer credentials securely, Chef provides *[data_bags](https://docs.chef.io/data_bags.html)* that allow encrypting sensitive data before communication.

The following process describes an example of how to create secrets and data bags to encrypt data.

* Install a key or generate one (with OpenSSL for example) on your Workstation: `openssl rand -base64 512 | tr -d '\r\n' > /tmp/encrypted_data_bag_secret`

* Create the required secret by using: `knife data bag from file wazuh_secrets ./api_configuration.json --secret-file /tmp/encrypted_data_bag_secret -z`

* Upload your new secrets with `knife upload /`

* Before installing Wazuh Manager, copy the key to `/etc/chef/encrypted_data_bag_secret` (default path) or specify the key path in `knife.rb` and `config.rb`.

### Using Chef Vault

Chef Vault provides an easier way to manage Data bags and configure them. To configure it you can follow these steps:

* Configure `knife.rb` or `config.rb` and add `knife[:vault_mode] = 'client'` to make the workstation transfer vault to the server.

* Create the vault with:

```
knife vault create wazuh_secrets api '{"id": "api", "htpasswd_user": "user", "htpasswd_passcode": "password"}' -A "username" -C "manager-1"
```

Where `-A` defines the workstation users authorized to modify/edit the vault and `-C` defines the nodes that have access to the defined vault.

You can check Chef Official Documentation about [Chef Vault](https://docs.chef.io/chef_vault.html) for detailed info.

## Agent registration

To connect an agent with the manager, modify `wazuh-chef/roles/wazuh_agent.json` with the manager IP address:

```
"address": "<YOUR MANAGER IP ADDRESS>"
```

Since Wazuh 4.0, by default, the agent registers automatically against the manager through enrollment. Configuration details can be found on [Enrollment section](https://documentation.wazuh.com/current/user-manual/reference/ossec-conf/client.html#reference-ossec-client).

## License and copyright

Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)

## References

* [Wazuh website](http://wazuh.com)
* [Wazuh documentation](http://documentation.wazuh.com)
* [Upstream repository (archived)](https://github.com/wazuh/wazuh-chef)
