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

require 'active_support/inflector/inflections'

require 'json_api_client'
require 'open-uri'
require 'tempfile'
require 'tty-editor'

module MetalClient
  class Model < JsonApiClient::Resource
    extend ActiveSupport::Inflector

    # TODO: Make this a config value
    self.site = ENV['APP_BASE_URL']

    def self.singular_type
      singularize(type)
    end

    def self.find(name)
      super(name).first
    rescue JsonApiClient::Errors::NotFound
      raise NotFoundError, <<~ERROR.chomp
        Could not locate #{singular_type} #{name}
      ERROR
    end

    connection do |c|
      c.faraday.authorization :Bearer, ENV['AUTH_TOKEN']
    end
  end

  module Models
    class PayloadModel < Model
      def self.cli_type
      end

      def system_path
        attributes["system-path"]
      end

      def uploaded?
        attributes[:uploaded]
      end

      def edit
        tmp = Tempfile.new('metal-client-download', '/tmp')
        if uploaded?
          tmp.write(read)
          tmp.rewind
        end
        TTY::Editor.open(tmp.path)
        tmp.rewind
        upload(tmp.path)
      ensure
        tmp.close
        tmp.unlink
      end
    end

    class Kickstart < PayloadModel
    end

    class Legacy < PayloadModel
    end

    class Uefi < PayloadModel
    end

    class DhcpSubnet < PayloadModel
    end
  end
end

