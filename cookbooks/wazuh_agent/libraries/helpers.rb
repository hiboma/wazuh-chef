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
        value.nil? || value.to_s.empty?
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
      def self.client_defaults!(conf, address, hostname)
        client = conf['client']
        return conf unless client.is_a?(Hash)

        server = client['server']
        server['address'] = address if server.is_a?(Hash) && blank?(server['address'])

        enrollment = client['enrollment']
        if enrollment.is_a?(Hash)
          enrollment['manager_address'] = address if blank?(enrollment['manager_address'])
          enrollment['agent_name'] = hostname if blank?(enrollment['agent_name'])
        end

        if blank?(server.is_a?(Hash) ? server['address'] : nil) ||
           (enrollment.is_a?(Hash) && blank?(enrollment['manager_address']))
          raise "node['ossec']['address'] must be set to the Wazuh manager address so the agent can report to and enroll against it"
        end

        conf
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
