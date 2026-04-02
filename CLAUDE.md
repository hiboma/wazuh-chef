# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A collection of Chef cookbooks for deploying the Wazuh security platform. Requires Chef >= 15.0. The Wazuh version varies by cookbook: wazuh_manager and wazuh_agent deploy 4.12.0, while elastic-stack, opendistro, filebeat, and filebeat-oss target 4.4.0.

## Cookbooks

Six cookbooks live under `cookbooks/`:

- **wazuh_manager** - Installs and configures the Wazuh Manager (central server)
- **wazuh_agent** - Installs and configures the Wazuh Agent (client)
- **elastic-stack** - Elasticsearch + Kibana (commercial)
- **opendistro** - Open Distro for Elasticsearch + Kibana (OSS)
- **filebeat** - Filebeat (commercial, ships logs from Manager to Elasticsearch)
- **filebeat-oss** - Filebeat (OSS variant)

Each cookbook follows the standard Chef structure: `recipes/`, `attributes/`, `templates/`, `test/`. The `wazuh_manager` and `wazuh_agent` cookbooks include `libraries/helpers.rb` which converts Chef attributes to OSSEC XML configuration using Gyoku and Nokogiri.

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

Test suites: `wazuh-manager`, `wazuh-agent`, `odfe-single-node` (kitchen.yml only), `elk-single-node` (kitchen.yml only)

## Architecture

The deployment pipeline flows as:

```
Agent → Manager → Filebeat → Elasticsearch → Kibana
```

Pre-configured deployment profiles are defined in `roles/` (`wazuh_server.json`, `wazuh_agent.json`, `elastic_stack.json`, `opendistro.json`, etc.).

## CI

GitHub Actions (`.github/workflows/manager-agent.yml`) runs Manager-Agent connection tests on Docker (Dokken) across ubuntu-20.04, 22.04, and 24.04.

## Supported Platforms

RedHat/CentOS/Oracle (>= 6), Amazon Linux (>= 1), Fedora (>= 22), Debian (>= 7), Ubuntu (>= 12.04), SUSE (>= 12), openSUSE (>= 42)
