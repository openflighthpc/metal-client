# frozen_string_literal: true
#==============================================================================
# Copyright (C) 2019-present Alces Flight Ltd
#
# This file is part of flight-cloud-cli
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# This project is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with this project. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on flight-account, please visit:
# https://github.com/openflighthpc/flight-cloud-cli
#===============================================================================

require 'commander'
require 'metal_client/models'

module MetalClient
  # TODO: Move me to a new file
  VERSION = '0.0.1'

  class CLI
    extend Commander::Delegates

    program :name, 'metal'
    program :version, MetalClient::VERSION
    program :description, 'Metal build tool'
    program :help_paging, false

    silent_trace!

    def self.run!
      ARGV.push '--help' if ARGV.empty?
      super
    end

    def self.action(command, klass, method: :run!)
      command.action do |args, options|
        hash = options.__hash__
        hash.delete(:trace)
        begin
          begin
            cmd = klass.new
            if hash.empty?
              cmd.public_send(method, *args)
            else
              cmd.public_send(method, *args, **hash)
            end
          rescue Interrupt
            raise RuntimeError, 'Received Interrupt!'
          end
        rescue StandardError => e
          # TODO: Add logging
          # Log.fatal(e.message)
          raise e
        end
      end
    end

    def self.cli_syntax(command, args_str = '')
      command.hidden = true if command.name.split.length > 1
      command.syntax = <<~SYNTAX.chomp
        #{program(:name)} #{command.name} #{args_str} [options]
      SYNTAX
    end

    command 'kickstart' do |c|
      cli_syntax(c)
      c.sub_command_group = true
      c.summary = 'Manage the kickstart files'
    end
  end
end
