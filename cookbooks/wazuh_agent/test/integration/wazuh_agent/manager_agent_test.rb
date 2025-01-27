# Check agent is listening to manager

describe command("netstat -vatunp | grep wazuh-agentd | awk \'{print $6}\'") do
    its('stdout') { should match ("ESTABLISHED")} 
end

# Check agent reports logs from manager in ossec.log

describe command("cat /var/ossec/logs/ossec.log | grep \"Connected to the server (\\\[#{input('manager_ip')}\\\]:#{input('manager_port')}\/#{input('protocol')}\"") do
    its('exit_status') { should eq 0 }
end
