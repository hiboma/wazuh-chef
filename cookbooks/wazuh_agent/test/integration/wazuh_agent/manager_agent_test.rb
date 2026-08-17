# Check agent successfully connected to manager
# Verify via ossec.log because the TCP connection may not persist
# in Docker environments at the time of test execution.
#
# The agent writes this line only after it finishes connecting, which
# happens asynchronously after the converge returns. Verify runs a few
# seconds later, so grepping once races the agent and fails
# intermittently. Poll until the line appears instead, and cap the wait
# so a genuinely broken connection still fails the test.

# Matched as a fixed string (grep -F), so the brackets need no escaping.
manager_pattern = "Connected to the server ([#{input('manager_ip')}]:#{input('manager_port')}/#{input('protocol')}"

# Poll every second, for at most 60 seconds.
wait_for_connection = <<~SHELL
  for i in $(seq 1 60); do
      if grep -qF "#{manager_pattern}" /var/ossec/logs/ossec.log 2>/dev/null; then
          exit 0
      fi
      sleep 1
  done
  exit 1
SHELL

describe command(wait_for_connection) do
    its('exit_status') { should eq 0 }
end
