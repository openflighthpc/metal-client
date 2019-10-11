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
require 'metal_client/commands'
require 'metal_client/errors'

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

    Commands::FileCommand.inherited_classes.each do |klass|
      command "#{klass.cli_type}" do |c|
        cli_syntax(c)
        c.sub_command_group = true
        c.summary = "Manage the #{klass.cli_type} files"
      end

      command "#{klass.cli_type} list"  do |c|
        cli_syntax(c)
        c.summary = "List all the #{klass.cli_type} files"
        action(c, klass, method: :list)
      end

      command "#{klass.cli_type} show" do |c|
        cli_syntax(c, 'NAME')
        c.summary = "Display the metadata about a #{klass.cli_type} file"
        action(c, klass, method: :show)
      end

      command "#{klass.cli_type} edit" do |c|
        cli_syntax(c, 'NAME')
        c.summary = "Edit the content of the stored file"
        action(c, klass, method: :edit)
      end

      command "#{klass.cli_type} create" do |c|
        cli_syntax(c, 'NAME FILE')
        c.summary = "Upload a new #{klass.cli_type} file to the server"
        action(c, klass, method: :create)
      end

      command "#{klass.cli_type} update" do |c|
        cli_syntax(c, 'NAME FILE')
        c.summary = "Replace a existing #{klass.cli_type} upload with a new file"
        action(c, klass, method: :update)
      end

      command "#{klass.cli_type} delete" do |c|
        cli_syntax(c, 'NAME')
        c.summary = "Delete the #{klass.cli_type} file and associated metadata"
        action(c, klass, method: :delete)
      end
    end

    host = Commands::DhcpHostCommand
    command "#{host.cli_type}" do |c|
      cli_syntax(c)
      c.sub_command_group = true
      c.summary = "Manage the #{host.cli_type} files"
    end

    command "#{host.cli_type} list" do |c|
      cli_syntax(c)
      c.summary = 'List all the configured DHCP hosts'
      action(c, host, method: :list)
    end

    command "#{host.cli_type} show" do |c|
      cli_syntax(c, 'SUBNET HOST')
      c.summary = "Display the metadata about a #{host.cli_type}"
      action(c, host, method: :show)
    end

    command "#{host.cli_type} create" do |c|
      cli_syntax(c, 'SUBNET HOST FILE')
      c.summary = "Create a new DHCP host within a subnet"
      action(c, host, method: :create)
    end

    command "#{host.cli_type} update" do |c|
      cli_syntax(c, 'SUBNET HOST FILE')
      c.summary = "Update a existing DHCP hosts file"
      action(c, host, method: :update)
    end

    command "#{host.cli_type} edit" do |c|
      cli_syntax(c, 'SUBNET HOST')
      c.summary = 'Edit the existing DHCP host file'
      action(c, host, method: :edit)
    end

    command "#{host.cli_type} delete" do |c|
      cli_syntax(c, 'SUBNET HOST')
      c.summary = "Remove the host file and reset DHCP"
      action(c, host, method: :delete)
    end

    boot = Commands::BootMethodCommand
    command "#{boot.cli_type}" do |c|
      cli_syntax(c)
      c.sub_command_group = true
      c.summary = "Manage the #{boot.cli_type} files"
    end

    command "#{boot.cli_type} list" do |c|
      cli_syntax(c)
      c.summary = 'List the available boot methods'
      action(c, boot, method: :list)
    end

    command "#{boot.cli_type} show" do |c|
      cli_syntax(c, 'NAME')
      c.summary = "Display the metadata about a #{boot.cli_type}"
      action(c, boot, method: :show)
    end

    command "#{boot.cli_type} create" do |c|
      cli_syntax(c, 'NAME')
      c.summary = 'Create a new kernel and initrd pairing'
      c.description = <<~DESC.chomp
        This command creates a kernel and initrd pair entry on the server. It does
        not however upload the files. As the kerenl and initial ram disks can be
        large binary files, they are uploaded independently.

        Please use the `upload-kernel` and `upload-initrd` commands to upload the
        kernel and initrd files respectively.
      DESC
      action(c, boot, method: :create)
    end

    command "#{boot.cli_type} upload-kernel" do |c|
      cli_syntax(c, 'NAME')
      c.summary = 'Upload a new version of the kernel'
      action(c, boot, method: :upload_kernel)
    end

    command "#{boot.cli_type} upload-initrd" do |c|
      cli_syntax(c, 'NAME')
      c.summary = 'Upload a new version of the initial ram disk'
      action(c, boot, method: :upload_initrd)
    end

    command "#{boot.cli_type} delete" do |c|
      cli_syntax(c, 'NAME')
      c.summary = 'Remove the metadata file and associated kernel and initrd'
      action(c, boot, method: :delete)
    end
  end
end

