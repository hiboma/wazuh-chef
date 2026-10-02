---
name: compare-wazuh-puppet
description: Compare this fork with the official wazuh-puppet module and list the changes worth porting. Use when asked what changed upstream, whether wazuh-puppet has updates to bring in, or which features the cookbooks lack compared with wazuh-puppet.
---

# Compare with wazuh-puppet

wazuh/wazuh-chef is archived, so this fork uses the official
[wazuh-puppet](https://github.com/wazuh/wazuh-puppet) module as its upstream
reference. wazuh-puppet tracks every Wazuh release and the official
documentation describes it:
https://documentation.wazuh.com/current/deployment-options/deploying-with-puppet/wazuh-puppet-module/index.html

The output is a list of changes, each classified as "port now", "port when the
target version is released" or "feature gap".

## 1. Find the versions to compare

- The version this fork targets is `default['wazuh']['patch_version']` in
  `cookbooks/wazuh_manager/attributes/versions.rb` and
  `cookbooks/wazuh_agent/attributes/version.rb`.
- Clone wazuh-puppet into a temporary directory, not into this repository.

```bash
git clone https://github.com/wazuh/wazuh-puppet.git "$TMPDIR/wazuh-puppet"
cd "$TMPDIR/wazuh-puppet"
git tag | sort -V | tail
git branch -r | grep -E '[0-9]+\.[0-9]+'
cat VERSION.json
```

- Release tags are `vX.Y.Z`. Upcoming patch releases live on branches named
  `X.Y.Z`. `main` carries the next major version and may be an alpha.
- Ignore stale branches such as `5.0-dev`, which was last updated in 2021. Check
  `git log -1 --format=%cd <ref>` before treating a branch as current.

## 2. Diff the parts this fork maintains

```bash
git log --oneline --no-merges v<current>..<target>
git diff --stat v<current> <target> -- manifests templates
git diff v<current> <target> -- manifests/agent.pp manifests/manager.pp \
  manifests/params_agent.pp manifests/params_manager.pp manifests/repo.pp templates
```

Mention indexer, dashboard, filebeat and certificates changes only briefly.
This fork maintains only the manager and the agent.

| wazuh-puppet | wazuh-chef |
|---|---|
| `manifests/params_manager.pp`, `manifests/params_agent.pp` | `cookbooks/*/attributes/*.rb` |
| `manifests/manager.pp`, `manifests/agent.pp` | `cookbooks/*/recipes/manager.rb`, `cookbooks/*/recipes/agent.rb`, `recipes/common.rb` |
| `manifests/repo.pp` | `cookbooks/*/recipes/repository.rb` |
| `templates/wazuh_manager.conf.erb`, `templates/wazuh_agent.conf.erb`, `templates/fragments/*.erb` | attributes rendered by `libraries/helpers.rb` (Gyoku) |
| `templates/api/*`, `local_rules`, `local_decoder` templates | `cookbooks/wazuh_manager/templates/default/` |
| `kitchen/` specs | `cookbooks/*/test/integration/` (InSpec) |

## 3. Classify each change

- **Version bump only**: update the version attributes with the
  `bump-wazuh-version` skill. Confirm the packages are published first.
- **ossec.conf element added or removed**: the cookbooks render ossec.conf from
  `node['ossec']['conf']`, so most elements need only an attribute change.
  An element wazuh-puppet stops rendering may still be emitted by a default
  attribute here (for example `attributes/alerts.rb`).
- **Recipe behaviour** (package pinning, service handling, enrollment, files
  placed on disk, keystore, supported platforms): needs recipe changes.
- **Not applicable**: Windows, indexer, dashboard, filebeat, firewall
  management, unless the user asks for them.

wazuh-puppet does not always reflect changes in Wazuh itself. For a new major
version, also read the Wazuh CHANGELOG and the default `ossec.conf` in
wazuh/wazuh before concluding that nothing changed.

Some features are richer here than in wazuh-puppet. For example,
`client.server` accepts an Array of manager addresses for failover. Do not
regress them to match wazuh-puppet.

## 4. Check package availability

A version on a wazuh-puppet branch may not be published yet. Check before
recommending a bump:

```bash
v=4.14.8
curl -sIo /dev/null -w '%{http_code}\n' \
  "https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-manager/wazuh-manager_${v}-1_amd64.deb"
curl -sIo /dev/null -w '%{http_code}\n' \
  "https://packages.wazuh.com/4.x/yum/wazuh-agent-${v}-1.x86_64.rpm"
```

200 means published. 403 means not published.

## 5. Report

For each change, give:

- the wazuh-puppet commit hash and file
- the current state in this repository as `file:line`
- whether to port it, when, and why
- a priority (high, medium or low)

Verify any claim about this repository's code by reading the file before
reporting it. When porting, cite the wazuh-puppet commit in the commit message.
