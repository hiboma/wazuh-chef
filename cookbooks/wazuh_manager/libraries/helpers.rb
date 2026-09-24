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

        if system_logs['syslog_files']
          locations = Array(system_logs['syslog_file_locations'])
          raise "node['ossec']['system_logs']['syslog_files'] is enabled but ['syslog_file_locations'] is empty" if locations.empty?

          locations.each do |location|
            next if location.is_a?(String) && !location.strip.empty?

            raise "node['ossec']['system_logs']['syslog_file_locations'] must contain non-empty paths, got #{location.inspect}"
          end
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

        # A consumer that overrode ['ossec']['conf']['localfile'] before these
        # attributes existed may still list a source there that is now turned
        # off, which would keep it collected next to the selected one.
        disabled = []
        disabled << 'journald' unless system_logs['journald']
        disabled.concat(Array(system_logs['syslog_file_locations'])) unless system_logs['syslog_files']
        (known & disabled).each do |location|
          Chef::Log.warn("#{location} is listed in node['ossec']['conf']['localfile'] although node['ossec']['system_logs'] " \
                         'turns it off. It is still collected; remove it there or enable it in system_logs.')
        end

        entries.reject! do |entry|
          next false unless known.include?(entry['location'])

          Chef::Log.info("#{entry['location']} is already listed in node['ossec']['conf']['localfile']; not adding it again")
          true
        end

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
