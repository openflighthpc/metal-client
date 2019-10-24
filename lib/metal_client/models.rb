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

    def self.singular_type
      singularize(type)
    end

    def self.find_id(id)
      find(id).first
    rescue JsonApiClient::Errors::NotFound
      raise NotFoundError, <<~ERROR.chomp
        Could not locate #{singular_type} #{id}
      ERROR
    rescue JsonApiClient::Errors::ClientError => e
      raise ClientError.from_api_error(e)
    rescue JsonApiClient::Errors::InternalServerError => e
      raise InternalServerError.from_api_error(e)
    end

    connection do |c|
      c.faraday.authorization :Bearer, Config.auth_token
    end

    # For most models, the `name` and `id` are the same thing. However this is not guaranteed
    def name
      id
    end
  end

  module Models
    class Service < Model
    end

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

    class Grub < PayloadModel
      def sub_type
        id.split('.').first
      end

      def name
        id.split('.').last
      end
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

      def subnet
        id.split('.').first
      end

      def name
        id.split('.').last
      end
    end

    class BootMethod < Model
      def self.table_name
        'boot-methods'
      end

      def upload_kernel(path)
        upload(path, File.join(links.self, 'kernel-blob'))
      end

      def upload_initrd(path)
        upload(path, File.join(links.self, 'initrd-blob'))
      end

      private

      def upload(path, url)
        headers = {
          "Authorization" => "Bearer #{Config.auth_token}",
          "Content-Type"  => 'application/octet-stream'
        }
        Faraday.post(url, File.read(path), headers).tap do |res|
          next if res.success?
          message = <<~ERROR.chomp
          The server responded with: #{res.status}

          #{res.body}
          ERROR
          raise (res.status < 500 ? ClientError : InternalServerError), message
        end
      end
    end
  end
end

