# Regression test for the <enrollment> block in ossec.conf.
#
# manager_address used to be derived from node['ossec']['address'] inside
# attributes/client.rb. Attribute files of a dependency are evaluated before
# the wrapper cookbook's, and role attributes land later still, so the value
# was frozen to a placeholder IP and never followed an overridden
# server.address. An agent that lost client.keys would then try to enroll
# against an unreachable (or unrelated) host.
#
# manager_address is now resolved at converge time, so it must always agree
# with the address the agent actually reports to.

manager = input('manager_ip')

# Assumes the single-<server> shape used by the wazuh-agent suite. With
# several <server> blocks configured for failover the address XPath returns
# a list, and these assertions would need to match against it instead.

describe xml('/var/ossec/etc/ossec.conf') do
    # The agent reports to the manager under test...
    its('ossec_config/client/server/address') { should cmp manager }
    # ...and enrolls against that same manager, not a leftover placeholder.
    its('ossec_config/client/enrollment/manager_address') { should cmp manager }
    its('ossec_config/client/enrollment/enabled') { should cmp 'yes' }
    its('ossec_config/client/enrollment/port') { should cmp '1515' }
end

# agent_name is filled in at converge time from the node's hostname.
describe xml('/var/ossec/etc/ossec.conf') do
    its('ossec_config/client/enrollment/agent_name') { should_not be_empty }
end

# The placeholder address must not survive anywhere in the rendered config.
describe file('/var/ossec/etc/ossec.conf') do
    its('content') { should_not match(/172\.19\.0\.211/) }
end
