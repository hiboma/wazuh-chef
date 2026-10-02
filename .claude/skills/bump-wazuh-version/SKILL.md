---
name: bump-wazuh-version
description: Update the Wazuh version installed by the wazuh_manager and wazuh_agent cookbooks. Use when asked to bump, upgrade or pin the Wazuh version.
---

# Bump the Wazuh version

## 1. Confirm the packages are published

wazuh-puppet and the documentation can reference a version before
packages.wazuh.com serves it. Installing an unpublished version fails the
converge.

```bash
v=4.14.8   # target version
major=4.x  # repository directory for the major version
for pkg in wazuh-manager wazuh-agent; do
  curl -sIo /dev/null -w "%{http_code} apt $pkg\n" \
    "https://packages.wazuh.com/${major}/apt/pool/main/w/${pkg}/${pkg}_${v}-1_amd64.deb"
  curl -sIo /dev/null -w "%{http_code} yum $pkg\n" \
    "https://packages.wazuh.com/${major}/yum/${pkg}-${v}-1.x86_64.rpm"
done
```

Proceed only when every line returns 200.

## 2. Update both cookbooks together

The manager and the agent must stay on the same version. Edit both files:

- `cookbooks/wazuh_manager/attributes/versions.rb`
- `cookbooks/wazuh_agent/attributes/version.rb`

| Attribute | Example | Change when |
|---|---|---|
| `major_version` | `4.x` | the major version changes. It selects the repository URL in `recipes/repository.rb` |
| `minor_version` | `4.14` | the minor version changes |
| `patch_version` | `4.14.8` | every release |

The recipes install `"#{patch_version}-1"`. If Wazuh publishes a package
revision other than `-1`, update the recipes as well.

## 3. Check the rest of the repository for the old version

```bash
grep -rn '<old version>' --exclude-dir=.git .
```

For a major version change, also update the hard-coded repository URL in the
InSpec repository tests, and read the Wazuh release notes for removed
ossec.conf sections. The `compare-wazuh-puppet` skill covers that review.

## 4. Test

Run the manager-agent connection test the way the CI runs it, or push and let
GitHub Actions run it on ubuntu-20.04, 22.04 and 24.04.

```bash
export KITCHEN_LOCAL_YAML=kitchen.dokken.yml CHEF_LICENSE=accept-no-persist
kitchen converge wazuh-manager-ubuntu-2404
kitchen converge wazuh-agent-ubuntu-2404
kitchen verify wazuh-agent-ubuntu-2404
```

## 5. Commit

Use `chore: bump Wazuh to <version>` and state in the body why this version
was chosen, for example that it is the newest published release.
