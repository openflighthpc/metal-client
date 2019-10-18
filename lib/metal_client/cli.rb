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
require 'metal_client/config'
require 'metal_client/models'
require 'metal_client/commands'
require 'metal_client/errors'

module MetalClient
  # TODO: Move me to a new file
  VERSION = '1.0.1'

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
        #{program(:name)} #{command.name} #{args_str}
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
        c.summary = "Display all the #{klass.cli_type} files"
        c.description = <<~DESC.chomp
          List all the existing #{klass.cli_type} files stored on the server.
        DESC
        action(c, klass, method: :list)
      end

      command "#{klass.cli_type} show" do |c|
        cli_syntax(c, 'NAME')
        c.summary = "Display the #{klass.cli_type} file and associated metadata"
        action(c, klass, method: :show)
      end

      command "#{klass.cli_type} edit" do |c|
        cli_syntax(c, 'NAME')
        c.summary = "Update the #{klass.cli_type} file through the editor"
        base_desc = <<~DESC.chomp
          Downloads the current version of the #{klass.cli_type} file to a
          temporary file. It is then opened by the system editor.

          The saved version of the temporary file is uploaded to the server;
          replacing the original. Exiting the editor without saving will abort
          the edit. The original version will remain intact and any changes
          will be lost.
        DESC
        c.description = if klass == Commands::DhcpSubnetCommand
          <<~DESC.chomp
            #{base_desc}

            The editted file should include the subnet's host file. Skipping this
            include will ignore the hosts' configs within the subnet.
          DESC
        else
          base_desc
        end
        action(c, klass, method: :edit)
      end

      command "#{klass.cli_type} create" do |c|
        cli_syntax(c, 'NAME UPLOAD_FILE_PATH')
        c.summary = "Upload a new #{klass.cli_type} file to the server"
        base_desc = <<~DESC.chomp
          Uploads the file given by UPLOAD_FILE_PATH to the server. This will create a
          new #{klass.cli_type} entry NAME. This action will error if the entry already exists.
        DESC
        c.description = if klass == Commands::DhcpSubnetCommand
          <<~DESC.chomp
            #{base_desc}

            The uploaded file should include the subnet's host file. Skipping this
            include will ignore the hosts' configs within the subnet.
          DESC
        else
          base_desc
        end
        action(c, klass, method: :create)
      end

      command "#{klass.cli_type} update" do |c|
        cli_syntax(c, 'NAME UPLOAD_FILE_PATH')
        c.summary = "Replace a existing #{klass.cli_type} upload with a new file"
        base_desc = <<~DESC.chomp
          Upload a new version of the #{klass.cli_type} given by UPLOAD_FILE_PATH.
          This will replace the existing version of the file. The entry NAME must
          already exist before it can be updated.
        DESC
        c.description = if klass == Commands::DhcpSubnetCommand
          <<~DESC.chomp
            #{base_desc}

            The uploaded file should include the subnet's host file. Skipping this
            include will ignore the hosts' configs within the subnet.
          DESC
        else
          base_desc
        end
        action(c, klass, method: :update)
      end

      command "#{klass.cli_type} delete" do |c|
        cli_syntax(c, 'NAME')
        c.summary = "Delete the #{klass.cli_type} file and associated metadata"
        base_desc = <<~DESC.chomp
          Delete the #{klass.cli_type} entry NAME. This removes the system file and
          any associated metadata.
        DESC
        c.description = if klass == Commands::DhcpSubnetCommand
          <<~DESC.chomp
            #{base_desc}

            The subnet must not have any hosts before it is deleted. Cascade deletion
            of hosts is not supported.
          DESC
        else
          base_desc
        end
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
      cli_syntax(c, 'SUBNET HOST UPLOAD_FILE_PATH')
      c.summary = "Upload a new #{host.cli_type} file to the server"
      c.description = <<~DESC.chomp
        Uploads the file given by UPLOAD_FILE_PATH to the server. This will
        create a new #{host.cli_type} entry HOST within the SUBNET.

        The SUBNET must exist before preforming this action. However the HOST
        must not exist before it is created.
      DESC
      action(c, host, method: :create)
    end

    command "#{host.cli_type} update" do |c|
      cli_syntax(c, 'SUBNET HOST FILE')
      c.summary = "Upload a new host config from the filesystem"
      action(c, host, method: :update)
    end

    command "#{host.cli_type} edit" do |c|
      cli_syntax(c, 'SUBNET HOST')
      c.summary = "Update the host config through the editor"
      c.description = <<~DESC.chomp
        Downloads the current version of the host config to a
        temporary file. It is then opened by the system editor.

        The saved version of the temporary file is uploaded to the server;
        replacing the original. Exiting the editor without saving will abort
        the edit. The original version will remain intact and any changes
        will be lost.
      DESC
      action(c, host, method: :edit)
    end

    command "#{host.cli_type} delete" do |c|
      cli_syntax(c, 'SUBNET HOST')
      c.summary = "Remove the host file and reset DHCP"
      c.description = <<~DESC.chomp
        Delete the host file entry and associated config file
      DESC
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
      cli_syntax(c, 'NAME FILEPATH')
      c.summary = 'Upload a new version of the kernel'
      c.description = <<~DESC.chomp
        Upload a new version of the kernel given by the FILEPATH. The #{boot.cli_type}
        entry NAME must already exist before the upload can commence.

        This action will create or replace the kernel currently stored against the #{boot.cli_type}.
      DESC
      action(c, boot, method: :upload_kernel)
    end

    command "#{boot.cli_type} upload-initrd" do |c|
      cli_syntax(c, 'NAME FILEPATH')
      c.summary = 'Upload a new version of the initial ram disk'
      c.description = <<~DESC.chomp
        Upload a new version of the initrd image give by the FILEPATH. The #{boot.cli_type}
        entry NAME must already exist before the upload can commence.

        This action will create or replace the initrd currently stored against #{boot.cli_type}.
      DESC
      action(c, boot, method: :upload_initrd)
    end

    command "#{boot.cli_type} delete" do |c|
      cli_syntax(c, 'NAME')
      c.summary = 'Remove the metadata file and associated kernel and initrd'
      action(c, boot, method: :delete)
    end
  end
end

