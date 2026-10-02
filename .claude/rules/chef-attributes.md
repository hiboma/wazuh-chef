---
paths:
  - "cookbooks/*/attributes/**/*.rb"
  - "cookbooks/*/libraries/**/*.rb"
---

# Attribute and helper conventions

- **ossec.conf comes from attributes.** `recipes/common.rb` renders
  `node['ossec']['conf']` to XML with Gyoku through `libraries/helpers.rb`.
  Add an ossec.conf element by adding an attribute, not a template.
- **Do not derive one attribute from another in an attributes file.**
  `default['a'] = node['b']` copies the value at load time. A role or wrapper
  cookbook that later overrides `node['b']` does not change `node['a']`, and
  `override` or `force_default` does not help. Resolve derived values at
  converge time instead, in a recipe, a `lazy` block or a helper such as
  `Helpers.client_defaults!`.
- **Leave required values unset rather than using a placeholder.** Use `nil`
  and fail the converge when it is still unset. A placeholder address makes
  the agent report to the wrong host without any error.
- **`node['ossec']['address']` is the single setting for the manager
  address.** `client.server`, `enrollment.manager_address` and
  `agent_auth.host` fall back to it at converge time. `client.server` accepts
  a Hash or an Array; the Array order is the failover priority, so keep it.
- **System log sources are added at render time.** The journald and syslog
  file `<localfile>` entries come from `node['ossec']['system_logs']` through
  `Helpers.system_log_localfiles!`. They do not appear in
  `node['ossec']['conf']['localfile']`.
- **`libraries/helpers.rb` is the same file in both cookbooks.** Keep the two
  copies identical.
- **Version attributes live in two files.** `wazuh_manager/attributes/versions.rb`
  and `wazuh_agent/attributes/version.rb` must hold the same version.
