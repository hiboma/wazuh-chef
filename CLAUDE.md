# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A fork of [wazuh/wazuh-chef](https://github.com/wazuh/wazuh-chef) (archived). Only **wazuh_agent** and **wazuh_manager** cookbooks are maintained for internal use. Requires Chef >= 15.0.

## Cookbooks

Two cookbooks live under `cookbooks/`:

- **wazuh_manager** - Installs and configures the Wazuh Manager (central server)
- **wazuh_agent** - Installs and configures the Wazuh Agent (client)

Each cookbook follows the standard Chef structure: `recipes/`, `attributes/`, `templates/`, `test/`. Both include `libraries/helpers.rb` which converts Chef attributes to OSSEC XML configuration using Gyoku and Nokogiri.

## Build & Test Commands

### Install dependencies

```bash
# For Docker (Dokken) testing
bundle config set --local without 'vagrant'
bundle install

# For Vagrant testing
bundle config set --local without 'dokken'
bundle install
```

### Test Kitchen (integration tests)

```bash
# List available test suites
kitchen list

# When using Docker (Dokken), set these environment variables
export KITCHEN_LOCAL_YAML=kitchen.dokken.yml
export CHEF_LICENSE=accept-no-persist

# Run a specific suite
kitchen converge wazuh-manager    # Apply Chef recipes
kitchen verify wazuh-agent        # Run InSpec tests
kitchen test wazuh-manager        # Full lifecycle (create, converge, verify, destroy)
kitchen destroy wazuh-manager     # Tear down the environment
kitchen login wazuh-manager       # SSH/exec into the instance
```

Test suites: `wazuh-manager`, `wazuh-agent`

## CI

GitHub Actions (`.github/workflows/manager-agent.yml`) runs Manager-Agent connection tests on Docker (Dokken) across ubuntu-20.04, 22.04, and 24.04.

## Supported Platforms

RedHat/CentOS/Oracle (>= 6), Amazon Linux (>= 1), Fedora (>= 22), Debian (>= 7), Ubuntu (>= 12.04), SUSE (>= 12), openSUSE (>= 42)
