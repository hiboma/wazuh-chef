#
# Cookbook Name:: ossec
# Library:: helpers
#
# Copyright 2015, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class Chef
  # Class that supports the interface between Chef and OSSEC
  module OSSEC
    # Defines methods that return serialized OSSEC data to Chef
    module Helpers
      # Gyoku looks for a symbol called :content! but Chef attributes
      # are always stringified. We can't just call symbolize_keys
      # because we need to recurse through the hash structure. Doing
      # this also gives us the opportunity to convert true/false to
      # yes/no, which is handy.
      def self.object_to_ossec(object)
        case object
        when Hash
          object.keys.each do |k|
            if k == 'content!'
              object[:content!] = object_to_ossec(object.delete(k))
            else
              object[k] = object_to_ossec(object[k])
            end
          end
          object
        when Array
          object.map! do |e|
            object_to_ossec(e)
          end
        when TrueClass
          'yes'
        when FalseClass
          'no'
        when NilClass
          ''
        else
          object
        end
      end

      def self.blank?(value)
        value.nil? || value.to_s.strip.empty?
      end

      # The manager address reaches ossec.conf through two places in <client>:
      # <server><address> and <enrollment><manager_address>. Deriving either one
      # in an attributes file freezes it before a wrapper cookbook or a role
      # attribute can take effect, because attribute files of a dependency are
      # evaluated first and precedence levels do not change evaluation order.
      # They are therefore resolved here, at converge time, from the final value
      # of node['ossec']['address']. Values a consumer set explicitly are left
      # untouched, so enrolling against a different host than the agent reports
      # to stays possible.
      #
      # client.server may be a single Hash or, for manager failover, an Array of
      # them. Each entry is filled in individually and the order is preserved,
      # because the order of <server> blocks defines the failover priority.
      def self.client_defaults!(conf, address, hostname)
        client = conf['client']
        return conf unless client.is_a?(Hash)

        servers = client['server'].is_a?(Array) ? client['server'] : [client['server']]
        servers.each do |server|
          next unless server.is_a?(Hash)

          server['address'] = address if blank?(server['address'])
        end

        enrollment = client['enrollment']
        if enrollment.is_a?(Hash)
          # An empty <manager_address> is a fatal config error for Wazuh
          # (XML_VALUENULL), so leave it out rather than emit it blank.
          enrollment['manager_address'] = address if blank?(enrollment['manager_address']) && !blank?(address)
          enrollment['agent_name'] = hostname if blank?(enrollment['agent_name'])
        end

        raise "node['ossec']['address'] must be set to the Wazuh manager address so the agent can report to and enroll against it" unless client_address_configured?(conf, address)

        conf
      end

      # True when the agent has an address to work with: either
      # node['ossec']['address'] is set, or every <server> block and the
      # <enrollment> block already carry one explicitly. Used both by the
      # compile-time guard in wazuh_agent::agent and by client_defaults!, so the
      # two cannot disagree about what counts as configured.
      def self.client_address_configured?(conf, address)
        return true unless blank?(address)

        client = conf['client']
        return true unless client.is_a?(Hash)

        servers = client['server'].is_a?(Array) ? client['server'] : [client['server']]
        servers = servers.select { |s| s.is_a?(Hash) }
        return false if servers.any? { |s| blank?(s['address']) }

        enrollment = client['enrollment']
        return false if enrollment.is_a?(Hash) && blank?(enrollment['manager_address'])

        true
      end

      # Checks node['ossec']['system_logs'] and raises when it would leave the
      # node without any system log source. Used both by the compile-time guard
      # in the agent and manager recipes and by system_log_localfiles!, so the
      # two cannot disagree about what counts as configured.
      #
      # Only true and false are accepted. A value such as 'yes' or 'false' is
      # truthy in Ruby and would silently turn a path on.
      def self.validate_system_logs!(system_logs)
        system_logs ||= {}

        %w(journald syslog_files).each do |key|
          value = system_logs[key]
          next if [true, false].include?(value)

          raise "node['ossec']['system_logs']['#{key}'] must be true or false, got #{value.inspect}"
        end

        unless system_logs['journald'] || system_logs['syslog_files']
          raise "Neither node['ossec']['system_logs']['journald'] nor ['syslog_files'] is enabled; system logs would not be collected"
        end

        if system_logs['syslog_files'] && Array(system_logs['syslog_file_locations']).empty?
          raise "node['ossec']['system_logs']['syslog_files'] is enabled but ['syslog_file_locations'] is empty"
        end

        system_logs
      end

      # Appends the system log sources selected by node['ossec']['system_logs']
      # to conf['localfile']. This runs at converge time for the same reason as
      # client_defaults!: building the entries in an attributes file would
      # freeze the choice before a wrapper cookbook or a role could change it.
      # See attributes/localfile.rb.
      #
      # An entry whose location is already listed in conf['localfile'] is not
      # added again, so a consumer that kept its own entry for one of these
      # sources does not end up collecting it twice.
      def self.system_log_localfiles!(conf, system_logs)
        validate_system_logs!(system_logs)

        if system_logs['journald'] && system_logs['syslog_files']
          Chef::Log.warn("Both node['ossec']['system_logs']['journald'] and ['syslog_files'] are enabled. " \
                         'Where rsyslog is running this ingests kernel, sshd and systemd records twice.')
        end

        entries = []
        entries << { 'log_format' => 'journald', 'location' => 'journald' } if system_logs['journald']
        if system_logs['syslog_files']
          Array(system_logs['syslog_file_locations']).each do |location|
            entries << { 'log_format' => 'syslog', 'location' => location }
          end
        end

        # A single <localfile> may be given as a Hash. Array() would split it
        # into key/value pairs, so wrap it instead.
        localfiles = conf['localfile'].is_a?(Hash) ? [conf['localfile']] : Array(conf['localfile'])
        known = localfiles.map { |entry| localfile_location(entry) }.compact
        entries.reject! { |entry| known.include?(entry['location']) }

        conf['localfile'] = localfiles + entries
        conf
      end

      # Entries in conf['localfile'] come in two shapes, with or without a
      # 'content!' wrapper. Both render the same XML.
      def self.localfile_location(entry)
        return unless entry.is_a?(Hash)

        body = entry['content!'].is_a?(Hash) ? entry['content!'] : entry
        body['location']
      end

      def self.ossec_to_xml(hash)
        require 'gyoku'
        require 'nokogiri'
        formatted_no_decl = Nokogiri::XML::Node::SaveOptions::FORMAT +
                            Nokogiri::XML::Node::SaveOptions::NO_DECLARATION
        source= Gyoku.xml object_to_ossec(hash)
        doc = Nokogiri::XML source
        doc.to_xml( save_with:formatted_no_decl )
      end
    end
  end
end
