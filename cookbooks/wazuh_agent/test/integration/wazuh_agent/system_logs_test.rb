# System log <localfile> entries are appended at converge time according to
# node['ossec']['system_logs'] (see attributes/localfile.rb). The wazuh-agent
# suite runs with the defaults, which on Debian/Ubuntu select journald only:
# the dokken images ship without rsyslog, so journald is the only source of
# auth and kernel records there.

describe xml('/var/ossec/etc/ossec.conf') do
    its("ossec_config/localfile[log_format='journald']/location") { should cmp 'journald' }
end

# The rsyslog files must not be collected alongside journald, or every record
# would be ingested twice where rsyslog is running.
%w(/var/log/syslog /var/log/auth.log /var/log/kern.log).each do |location|
    describe xml('/var/ossec/etc/ossec.conf') do
        its("ossec_config/localfile[location='#{location}']") { should be_empty }
    end
end

# Entries from node['ossec']['conf']['localfile'] are kept alongside them.
describe xml('/var/ossec/etc/ossec.conf') do
    its("ossec_config/localfile[location='/var/log/dpkg.log']/log_format") { should cmp 'syslog' }
end
