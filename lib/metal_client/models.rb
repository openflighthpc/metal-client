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
    self.site = Config.app_base_url

    def self.octet_stream_headers
      {
        "Authorization" => "Bearer #{Config.auth_token}",
        "Content-Type"  => 'application/octet-stream'
      }
    end

    def self.singular_type
      singularize(type)
    end

    def self.find_id(name)
      find(name).first
    rescue JsonApiClient::Errors::NotFound
      raise NotFoundError, <<~ERROR.chomp
        Could not locate #{singular_type} #{name}
      ERROR
    rescue JsonApiClient::Errors::ClientError => e
      raise ClientError.from_api_error(e)
    rescue JsonApiClient::Errors::InternalServerError => e
      raise InternalServerError.from_api_error(e)
    end

    connection do |c|
      c.faraday.authorization :Bearer, Config.auth_token
    end
  end

  module Models
    class PayloadModel < Model
      def system_path
        attributes["system-path"]
      end

      def uploaded?
        attributes[:uploaded]
      end

      def edit
        Tempfile.open("metal-client-#{self.class.singular_type}-#{id}", '/tmp') do |file|
          file.write(attributes[:payload])
          file.rewind
          TTY::Editor.open(file.path)
          update(payload: file.read)
        end
      end
    end

    class Kickstart < PayloadModel
    end

    class Legacy < PayloadModel
    end

    class Uefi < PayloadModel
    end

    class DhcpSubnet < PayloadModel
      def self.table_name
        'dhcp-subnets'
      end
    end

    class DhcpHost < PayloadModel
      def self.table_name
        'dhcp-hosts'
      end
    end

    class BootMethod < Model
      def self.table_name
        'boot-methods'
      end

      def upload_kernel(path)
        url = File.join(links.self, 'kernel-blob')
        Faraday.post(url, File.read(path), self.class.octet_stream_headers)
      end

      def upload_initrd(path)
        url = File.join(links.self, 'initrd-blob')
        Faraday.post(url, File.read(path), self.class.octet_stream_headers)
      end
    end
  end
end

