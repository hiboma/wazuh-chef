# System logs reach Wazuh through one of two paths: journald, or the files
# rsyslog writes from it. They carry the same records, so enabling both
# ingests every kernel, sshd and systemd event twice where rsyslog is running,
# while enabling only the files leaves a blind spot where it is not (the
# dokken and official Ubuntu images ship without rsyslog, and Wazuh does not
# report a missing localfile path). Which one is correct depends on the host,
# so it is chosen here rather than guessed.
#
# The matching <localfile> entries are appended to ossec.conf at converge
# time by Chef::OSSEC::Helpers.system_log_localfiles!, not listed in
# node['ossec']['conf']['localfile'] below. Building them here would freeze
# the choice before a wrapper cookbook or a role could change it.
#
# The defaults keep the previous behaviour of each platform. Debian/Ubuntu
# follows upstream's WriteLogs(), which skips the rsyslog files on a host
# that has journalctl.

if platform_family?('ubuntu', 'debian')
  default['ossec']['conf']['localfile'] = [
    {
      'log_format' => 'command',
      'command' => 'df -P',
      'frequency' => 360
    },
    {
      'content!' => {
        'log_format' => 'full_command',
        'command' => "netstat -tulpn | sed 's/\([[:alnum:]]\+\)\ \+[[:digit:]]\+\ \+[[:digit:]]\+\ \+\(.*\):\([[:digit:]]*\)\ \+\([0-9\.\:\*]\+\).\+\ \([[:digit:]]*\/[[:alnum:]\-]*\).*/\1 \2 == \3 == \4 \5/' | sort -k 4 -g | sed 's/ == \(.*\) ==/:\1/' | sed 1,2d",
        'alias' => 'netstat listening ports',
        'frequency' => 360
      }
    },
    {
      'content!' => {
      'log_format' => 'full_command',
      'command' => 'last -n 20',
      'frequency' => 360
      }
    },
    {
      'content!' => {
        'log_format' => 'syslog',
        'location' => '/var/ossec/logs/active-responses.log',
      }
    },
    {
      'content!' => {
        'log_format' => 'syslog',
        'location' => '/var/log/dpkg.log'
        }
    }
  ]

  default['ossec']['system_logs']['journald'] = true
  default['ossec']['system_logs']['syslog_files'] = false
  default['ossec']['system_logs']['syslog_file_locations'] = %w(
    /var/log/syslog
    /var/log/auth.log
    /var/log/kern.log
  )
elsif platform_family?('rhel','centos', 'amazon')
  default['ossec']['conf']['localfile'] = [
    {
      'log_format' => 'command',
      'command' => 'df -P',
      'frequency' => 360
    },
    {
      'content!' => {
        'log_format' => 'full_command',
        'command' => "netstat -tulpn | sed 's/\([[:alnum:]]\+\)\ \+[[:digit:]]\+\ \+[[:digit:]]\+\ \+\(.*\):\([[:digit:]]*\)\ \+\([0-9\.\:\*]\+\).\+\ \([[:digit:]]*\/[[:alnum:]\-]*\).*/\1 \2 == \3 == \4 \5/' | sort -k 4 -g | sed 's/ == \(.*\) ==/:\1/' | sed 1,2d",
        'alias' => 'netstat listening ports',
        'frequency' => 360
      }
    },
    {
      'content!' => {
      'log_format' => 'full_command',
      'command' => 'last -n 20',
      'frequency' => 360
      }
    },
    {
      'content!' => {
        'log_format' => 'syslog',
        'location' => '/var/ossec/logs/active-responses.log',
      }
    },
  ]

  default['ossec']['system_logs']['journald'] = false
  default['ossec']['system_logs']['syslog_files'] = true
  default['ossec']['system_logs']['syslog_file_locations'] = %w(
    /var/log/messages
    /var/log/secure
    /var/log/maillog
  )
else
  raise "Currently platforn not supported yet. Feel free to open an issue on https://www.github.com/wazuh/wazuh-chef if you consider that support for a specific OS should be added"
end
