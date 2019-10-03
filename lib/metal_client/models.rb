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

    def system_path
      attributes["system-path"]
    end

    def read
      open_download_url(&:read)
    end

    def edit
      open_download_url do |file|
        TTY::Editor.open(file.path)
      end
    end

    private

    def open_download_url(&b)
      file = nil
      io = open(download_url, 'Authorization' => "Bearer #{ENV['AUTH_TOKEN']}")
      file = case io
             when Tempfile
               io
             else
               Tempfile.new('metal-server', '/tmp').tap do |tmp|
                 begin
                   IO.copy_stream(io, tmp)
                   tmp.rewind
                 rescue => e
                   tmp.close
                   tmp.unlink
                   raise e
                 ensure
                   io.close
                 end
                end
             end
      b ? b.call(file) : file
    ensure
      if b && file
        file.close
        file.unlink
      elsif b
        io.close
      end
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

