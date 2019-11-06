# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of Metal Client.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Metal Client is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Cloud. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Metal Client, please visit:
# https://github.com/openflighthpc/metal-client
#===============================================================================

require 'active_support/core_ext/module/delegation'

module MetalClient
  class Config
    class << self
      def cache
        @cache ||= new
      end

      def path
        File.expand_path('../../etc/config.yaml', __dir__)
      end

      delegate_missing_to :cache
    end

    def path
      self.class.path
    end

    def __data__
      @__data__ ||= begin
                      if File.exists?(path)
                        YAML.load(File.read(path), symbolize_names: true, fallback: {})
                            .reject { |_, v| v.nil? || v.empty? }
                      else
                        $stderr.puts <<~ERROR.squish
                          Can not continue as the core configuration file does not
                          exist! Please create the file with the required paramters and
                          try again:
                        ERROR
                        $stderr.print path + "\n\n"
                        $stderr.puts <<~ERROR.chomp
                          Refer to the reference document for the required keys:
                          #{path}.reference
                        ERROR
                        exit 1
                      end
                    end
    end

    def app_base_url
      __data__[:app_base_url] || begin
        $stderr.print <<~ERROR
          The 'app_base_url' has not been set in the configuration. Please set the key and try again:
          #{path}
        ERROR
        exit 1
      end
    end

    def auth_token
      __data__[:auth_token] || begin
        $stderr.print <<~ERROR
          The 'auth_token' has not been set in the configuration. Please set the key and try again:
          #{path}
        ERROR
        exit 1
      end
    end

    def named_sub_dir
      __data__[:named_sub_dir] || 'metal-server'
    end
  end
end

