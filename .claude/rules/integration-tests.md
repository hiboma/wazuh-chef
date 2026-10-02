---
paths:
  - "cookbooks/*/test/**/*.rb"
  - "kitchen*.yml"
  - "Gemfile"
  - ".github/workflows/**"
---

# Integration test conventions

- **Keep `inspec-core` pinned to 5.24.24.** InSpec 6.x and later check for a
  Progress Chef license when run under Test Kitchen and fail `verify` without
  one. `CHEF_LICENSE=accept-no-persist` accepts the EULA only and does not
  satisfy that check.
- **Wait for the agent connection.** The agent connects asynchronously after
  converge. `manager_agent_test.rb` polls `ossec.log` for up to 60 seconds; a
  single grep makes the CI fail intermittently. Use `grep -qF` because the
  pattern contains brackets and slashes from the manager address. Run the CI
  about three times to confirm a fix for a race.
- **Pass XPaths that contain dots as arrays.** InSpec splits `its('a.b')` on
  `.`, so `its("ossec_config/localfile[location='/var/log/auth.log']")` breaks.
  Write `its(["ossec_config/localfile[location='/var/log/auth.log']"])`.
- **Add a regression test with each fix** under
  `cookbooks/<cookbook>/test/integration/<cookbook>/`. The CI runs the
  manager-agent connection test on ubuntu-20.04, 22.04 and 24.04 only.
