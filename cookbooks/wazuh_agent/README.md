# Wazuh Agent cookbook

These cookbooks install and configure a Wazuh Agent on specified nodes.

Currently, the agent is automatically registered using enrollment. check the [documentation](https://documentation.wazuh.com/current/user-manual/registering/) for further information. The manager address has to be declared in the `node['ossec']['address']` attribute; it has no default and the converge fails if it is left unset.

`node['ossec']['address']` is the single place to set the manager address. Both `<server><address>` and the `<enrollment><manager_address>` used for re-registration are resolved from it, so overriding it from a role, a wrapper cookbook or a node attribute is enough. To enroll against a different host than the one the agent reports to, set `node['ossec']['conf']['client']['enrollment']['manager_address']` explicitly and it is left as-is.

### Attributes

* ``versions.rb`` contains version attributes to make it easier when it comes to bump version
* The rest of files contains all the default configuration files in order to generate *ossec.conf* 

Check ['ossec.conf']( https://documentation.wazuh.com/current/user-manual/reference/ossec-conf/index.html) documentation to see all configuration sections.

### Usage

Create a role following the ['wazuh_agent'](https://github.com/wazuh/wazuh-chef/roles/wazuh_agent.json) role structure and specify your desired configuration attributes. Note that **address** is mandatory.

Assign the current role to desired nodes and run ```chef-client``` on them.

For example:

```
{
    "name": "wazuh_agent",
    "description": "Wazuh agent",
    "json_class": "Chef::Role",
    "default_attributes": {
    },
    "override_attributes": {
      "ossec": {
        "address": "wazuh-manager.example.com"
      }
    },
    "chef_type": "role",
    "run_list": [
      "recipe[wazuh_agent::agent]"
    ],
    "env_run_lists": {
    }
}
```

### Recipes

#### agent.rb

Register agent by using agent enrollment. Also authd method is available but not enabled by default. You can declare the desired fields to customize the registration process. 

#### common.rb

It generates the ossec.conf file using Gyoku and restarts the wazuh-agent service

#### repository.rb

Declares repository of Wazuh and GPG keys based on different installations.

### References

Check https://documentation.wazuh.com/current/user-manual/agents/index.html for more information about Wazuh-Agent.

