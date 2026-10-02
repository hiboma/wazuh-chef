---
paths:
  - "cookbooks/*/recipes/**/*.rb"
---

# Recipe conventions

Some existing code does not follow these conventions yet. Apply them to new
code and to the lines you change; fix other places in a separate change.

- **Services restart only through notifications.** A resource that changes a
  file the daemon reads must `notifies :restart, 'service[wazuh]'`. The
  service resource itself uses `[:enable, :start]`. A restart on every
  converge disconnects every agent from the manager.
- **Pin the full package version.** Install `"#{node['wazuh']['patch_version']}-1"`
  with every package manager (apt, dnf, yum, zypper), for both the manager
  and the agent.
- **Select platforms with `platform_family?`.** Families are `debian`, `rhel`
  (RHEL, CentOS, Rocky, AlmaLinux, Oracle), `amazon`, `fedora` and `suse`.
  `redhat` and `centos` are platforms, not families. Every `if`/`elsif` needs
  a condition; end the chain with `raise` for unsupported platforms.
- **Do not compare versions as strings.** `node['platform_version'] >= '8'`
  is false for `'10'` and `'2023'`. Use `.to_i` or `Gem::Version`.
- **Evaluate run-time state at converge time.** `File.exist?` and similar
  checks in the recipe body run at compile time, before any resource in the
  same run has created the file. Put them in `lazy`, `only_if` or `not_if`.
- **Keep secrets off the command line and out of logs.** Arguments are
  visible to every local user through `ps`, and `sensitive true` hides only
  Chef's output. Prefer a file with restricted permissions (for example
  `authd.pass`, mode 0640, group `wazuh`). Node attributes are stored in plain
  text on the Chef Server; document chef-vault or encrypted data bags for
  passwords, keys and tokens.
- **Keep the agent and manager recipes consistent.** When a fix applies to
  both cookbooks, change both in the same pull request.
