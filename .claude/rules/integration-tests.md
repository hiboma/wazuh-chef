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
  `cookbooks/<cookbook>/test/integration/<cookbook>/`.
- **The CI runs only the tests listed in `inspec_tests`.** It converges the
  manager and the agent, then runs `verify` on the wazuh-agent suite, on
  ubuntu-20.04, 22.04 and 24.04. That runs only the files listed under
  `inspec_tests` in `kitchen.yml` and `kitchen.dokken.yml`. The manager's
  InSpec tests do not run in CI. Add a new test file to `inspec_tests` in
  both files to run it in CI.
