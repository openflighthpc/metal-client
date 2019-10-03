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

require 'json_api_client'
require 'open-uri'
require 'tempfile'
require 'tty-editor'

module MetalClient
  class FileModel < JsonApiClient::Resource
    # TODO: Make this an environment config
    self.site = 'http://192.168.101.101/api'

    connection do |c|
      c.faraday.authorization :Bearer, ENV['AUTH_TOKEN']
    end

    def download_url
      attributes["download-url"]
    end

    def upload_url
      File.join(links['self'], 'upload')
    end

    def system_path
      attributes["system-path"]
    end

    def read
      self.class.connection.faraday.get(download_url).body
    end

    def upload(path)
      Faraday.post(upload_url,
                   File.read(path),
                   "Authorization" => "Bearer #{ENV['AUTH_TOKEN']}",
                   "Content-Type" => "application/octet-stream")
    end

    def edit
      tmp = Tempfile.new('metal-client-download', '/tmp')
      tmp.write(read)
      tmp.rewind
      TTY::Editor.open(tmp.path)
      tmp.rewind
      upload(tmp.path)
    ensure
      tmp.close
      tmp.unlink
    end
  end

  module Models
    class Kickstart < FileModel
    end

    class Legacy < FileModel
    end

    class Uefi < FileModel
    end

    class DhcpSubnet < FileModel
    end
  end
end

