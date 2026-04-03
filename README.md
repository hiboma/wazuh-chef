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

## Agent registration

To connect an agent with the manager, modify `wazuh-chef/roles/wazuh_agent.json` with the manager IP address:

```
"address": "<YOUR MANAGER IP ADDRESS>"
```

Since Wazuh 4.0, by default, the agent registers automatically against the manager through enrollment. Configuration details can be found on [Enrollment section](https://documentation.wazuh.com/current/user-manual/reference/ossec-conf/client.html#reference-ossec-client).

## License and copyright

Wazuh App Copyright (C) 2019 Wazuh Inc. (License Apache 2.0)

## References

* [Wazuh website](http://wazuh.com)
* [Wazuh documentation](http://documentation.wazuh.com)
* [Upstream repository (archived)](https://github.com/wazuh/wazuh-chef)
