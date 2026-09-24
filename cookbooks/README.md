
Wazuh cookbooks
====================================

Requirements
------------
#### Platforms
Tested on Ubuntu and CentOS, but should work on any Unix/Linux platform supported by Wazuh. Installation by default is done from packages.

These cookbooks don't configure Windows systems yet. For manual agent installation on Windows, check the [documentation](https://documentation.wazuh.com/current/installation-guide/wazuh-agent/wazuh_agent_package_windows.html)

Attributes
----------

All default attributes files are defined in the ```attributes/``` folder of each cookbook. Chef applies attributes from all attribute files regardless of which recipes were executed. It's important to mention that Chef will load ```default.rb``` first and then will proceed alphabetically. 

### ossec.conf

OSSEC's configuration is mainly read from an XML file called `ossec.conf`. You can directly control the contents of this file using node attributes under `node['ossec']['conf']`. These attributes are mapped to XML using Gyoku. See the [Gyoku site](https://github.com/savonrb/gyoku) for details on how this works.

Values `true` and `false`  are automatically mapped to `"yes"` and `"no"` as OSSEC expects the latter.

`ossec.conf` makes use of XML attributes so you can generally construct nested hashes in the usual fashion. Where an attribute is required, you can do it like this:

```ruby
default['ossec']['conf']['all']['syscheck']['directories'] = [
  { '@check_all' => true, 'content!' => '/bin,/sbin' },
  '/etc,/usr/bin,/usr/sbin'
]
```

This produces:

```xml
<syscheck>
  <directories check_all="yes">/bin,/sbin</directories>
  <directories>/etc,/usr/bin,/usr/sbin</directories>
</syscheck>
```

## Customize Installation

**Important note:** Gyoku will hash the defined attributes and the ```ossec.conf``` file will only contain the declared attributes, via default attributes or overridden ones. Any other information will be overwritten and deleted from the file.

If you want to add new fields to customize your installation, you can declare it as a default attribute in its respective .rb file in the attributes folder or add it manually to the role.

For example: To enable cluster configuration, the following line would be replaced in ```/cookbooks/wazuh_manager/attributes/cluster.rb ``` file:

`````` ruby
default['ossec']['conf']['cluster'] = {
  ...
  'disabled' => false
}
``````

This will transform the **disabled** field from:

```xml
<cluster>
  <name>wazuh</name>
  <node_name>manager_01</node_name>
  <node_type>master</node_type>
  <key>ugdtAnd7Pi9myP7CVts4qZaZQEQcRYZa</key>
  <port>1516</port>
  <bind_addr>0.0.0.0</bind_addr>
  <nodes>
    <node>master</node>
  </nodes>
  <hidden>no</hidden>
  <disabled>yes</disabled>
</cluster>
```

To:

```xml
<cluster>
  <name>wazuh</name>
  <node_name>manager_01</node_name>
  <node_type>master</node_type>
  <key>ugdtAnd7Pi9myP7CVts4qZaZQEQcRYZa</key>
  <port>1516</port>
  <bind_addr>0.0.0.0</bind_addr>
  <nodes>
    <node>master</node>
  </nodes>
  <hidden>no</hidden>
  <disabled>no</disabled>
</cluster>
```

In case you want to customize your installation using roles, you can declare attributes like this: 

```json
{
  "name": "wazuh_server",
  "description": "Wazuh Server Role",
  "json_class": "Chef::Role",
  "default_attributes": {
    "ossec": {
        "cluster":{
            "disabled" : "false"
        }
    }
  },
  "override_attributes": {

  },
  "chef_type": "role",
  "run_list": [
    "recipe[wazuh_manager::default]"
  ],
  "env_run_lists": {

  }
}
```

The same example applies for the rest of cookbooks and their own attributes.

You can get more info about attributes and how they work on the Chef documentation: https://docs.chef.io/attributes.html

### System log collection

System logs reach Wazuh either from journald or from the files rsyslog writes from it. Both carry the same records, so collecting both ingests every kernel, sshd and systemd event twice on a host where rsyslog is running. Collecting only the files leaves a silent gap on a host without rsyslog, because Wazuh does not report a missing `localfile` path. The cookbooks cannot tell which applies, so the choice is made with these attributes, in both `wazuh_agent` and `wazuh_manager`:

| Attribute | Debian/Ubuntu | RHEL family |
|---|---|---|
| `['ossec']['system_logs']['journald']` | `true` | `false` |
| `['ossec']['system_logs']['syslog_files']` | `false` | `true` |
| `['ossec']['system_logs']['syslog_file_locations']` | `/var/log/syslog`, `/var/log/auth.log`, `/var/log/kern.log` | `/var/log/messages`, `/var/log/secure`, `/var/log/maillog` (manager: `messages`, `secure`) |

The Debian/Ubuntu default matches upstream Wazuh, which skips the rsyslog files on a host that has `journalctl`. On a host where rsyslog is running and you prefer the files, switch the paths in a role or a wrapper cookbook:

```json
"default_attributes": {
  "ossec": {
    "system_logs": {
      "journald": false,
      "syslog_files": true
    }
  }
}
```

The RHEL-family default assumes rsyslog as well. Some of those images ship without it, for example Amazon Linux 2023 and minimal RHEL 9 images, in which case `/var/log/messages` and `/var/log/secure` do not exist and `journald: true, syslog_files: false` is the setting to use.

The matching `<localfile>` entries are appended to `ossec.conf` at converge time, so do not list them in `['ossec']['conf']['localfile']` as well. An entry already listed there with the same location is not added a second time.

If you override `['ossec']['conf']['localfile']` and that list contains `journald` or the rsyslog files, move the choice to `system_logs` and remove those entries from your list. Otherwise a source you left in the list stays collected next to the one `system_logs` selects. The converge logs a warning when a location listed there is turned off in `system_logs`.

The converge fails when both paths are disabled, when either flag is anything other than `true` or `false`, or when `syslog_files` is enabled and `syslog_file_locations` is empty or contains a blank entry. Enabling both is allowed and logs a warning.

### Centralized Configuration

You can set up your Wazuh [Centralized Configuration](https://documentation.wazuh.com/current/user-manual/reference/centralized-configuration.html#centralized-configuration-process) with Chef.

In order to achieve this, the following steps are required:

##### Enable the `agent.conf` configuration

The easiest way to achieve this is to modify the Wazuh Manager attributes in the role

```json
{
  "name": "wazuh_server",
  "description": "Wazuh Server Role",
  "json_class": "Chef::Role",
  "default_attributes": {
    "ossec": {
        "centralized_configuration":{
            "enabled" : "yes",
            "path": "/var/ossec/etc/shared/default"
        }
      }
    },
  "override_attributes": {

  },
  "chef_type": "role",
  "run_list": [
    "recipe[wazuh_manager::default]"
  ],
  "env_run_lists": {

  }
}
```

This will render all `['ossec']['centralized_configuration']['conf']['agent_config']` variables and convert them to XML using Gyoku.

For example, the following attribute:

```ruby
default['ossec']['centralized_configuration']['conf']['agent_config']= [
  {   "@os" => "Linux",
      "localfile" => {
          "location" => "/var/log/linux.log",
          "log_format" => "syslog"
      }
  }
]
```

Generates this XML in the `agent.conf` file:

```xml
<agent_config os="Linux">
    <localfile>
        <location>/var/log/linux.log</location>
        <log_format>syslog</log_format>
    </localfile>
</agent_config>
```
