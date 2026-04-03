# Check agent successfully connected to manager
# Verify via ossec.log because the TCP connection may not persist
# in Docker environments at the time of test execution.

describe command("cat /var/ossec/logs/ossec.log | grep \"Connected to the server (\\\[#{input('manager_ip')}\\\]:#{input('manager_port')}\/#{input('protocol')}\"") do
    its('exit_status') { should eq 0 }
end
