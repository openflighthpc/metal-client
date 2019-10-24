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

require 'tty-table'

module MetalClient
  module Commands
    class RecordCommand
      def self.cli_type
        model_class.singular_type
      end

      def self.model_class
        raise NotImplementedError
      end

      def self.show_table
        raise NotImplementedError
      end

      def model_class
        self.class.model_class
      end

      def show(id)
        record = model_class.find_id(id)
        puts render_show_table(record)
      end

      private

      def render_show_table(record)
        data = self.class.show_table.map { |k, m| [k, m.call(record)] }
        table = TTY::Table.new data
        table.render(:ascii, multiline: true)
      end
    end

    class FileCommand < RecordCommand
      def self.inherited(base)
        FileCommand.inherited_classes << base
      end

      def self.inherited_classes
        @inherited_classes ||= []
      end

      def self.show_table
        @show_table ||= {
          'NAME' => ->(r) { r.id },
          'Filename' => ->(k) { k.attributes['filename'] },
          'Size' => ->(r) { r.attributes['size'] },
          '' => ->(_) {}, # Intentionally left blank
          'Content' => ->(r) { r.attributes['payload'] }
        }
      end

      def list
        models = model_class.all.map(&:id).sort
        if models.empty?
          $stderr.puts "No #{self.class.model_class.type} found!"
        else
          puts models
        end
      end

      def create(name, file)
        record = model_class.create(id: name, payload: File.read(file))
        puts render_show_table(record)
      end

      def update(name, file)
        model = model_class.find_id(name)
        model.update(payload: File.read(file))
        puts render_show_table model
      end

      def edit(name)
        model = model_class.find_id(name)
        model.edit
        puts render_show_table model
      end

      def delete(name)
        pp model_class.find_id(name).destroy
      end
    end

    class KickstartCommand < FileCommand
      def self.show_table
        @show_table ||= {
          'NAME' => ->(k) { k.id },
          'Filename' => ->(k) { k.attributes['filename'] },
          'Size' => ->(k) { k.attributes['size'] },
          'Download URL' => ->(k) { k.relationships['blob']['links']['related'] },
          '' => ->(_) {}, # Intentionally left blank
          'Content' => ->(k) { k.attributes['payload'] }
        }
      end

      def self.model_class
        Models::Kickstart
      end
    end

    class LegacyCommand < FileCommand
      def self.model_class
        Models::Legacy
      end

      def self.cli_type
        'legacybootmenu'
      end
    end

    class DhcpSubnetCommand < FileCommand
      def self.model_class
        Models::DhcpSubnet
      end

      def self.cli_type
        'dhcpsubnet'
      end

      def self.show_table
        @show_table ||= {
          'NAME' => ->(r) { r.id },
          'Size' => ->(r) { r.attributes['size'] },
          'Hosts File' => ->(r) { r.attributes['hosts-path'] },
          '' => ->(_) {}, # Intentionally left blank
          'Status' => ->(r) do
            payload = r.attributes['payload']
            path = r.attributes['hosts-path']
            if /.*^\s*include\s+"#{path}"\s*;\s*$.*/.match?(payload)
              <<~STATUS.squish
                The host configs are included in the subnet.
              STATUS
            elsif payload.include?(path)
              <<~STATUS.squish
                The main host config appears in the subnet's content, however
                it may not be included. Please confirm manually.
              STATUS
            else
              part1 = <<~STATUS.squish
                The main host config does not appear in the subnets content!.
                Please edit the subnet and add the following line:
              STATUS
              <<~STATUS.chomp
                #{part1}
                include "#{r.attributes['hosts-path']}";
              STATUS
            end
          end,
          ' ' => ->(_) {}, # Intentionally left blank
          'Content' => ->(r) { r.attributes['payload'] }
        }
      end

      def delete(name)
        super
      rescue JsonApiClient::Errors::Conflict => e
        raise ClientError.from_api_error(e)
      end
    end

    class GrubCommand < RecordCommand
      def self.model_class
        Models::Grub
      end
    end

    class DhcpHostCommand < RecordCommand
      def self.model_class
        Models::DhcpHost
      end

      def self.cli_type
        'dhcphost'
      end

      def self.show_table
        @show_table ||= {
          'ID' => ->(k) { k.id },
          'Name' => ->(k) { k.name },
          'Subnet' => ->(k) { k.subnet },
          'Size' => ->(k) { k.attributes['size'] },
          '' => ->(_) {}, # Intentionally left blank
          'Content' => ->(k) { k.attributes['payload'] }
        }
      end

      def list
        ids = model_class.all.map do |record|
          subnet, name = record.id.split('.')
          "Subnet #{subnet}: #{name}"
        end.sort
        if ids.empty?
          $stderr.puts "No #{self.class.model_class.type} found!"
        else
          puts ids
        end
      end

      def show(subnet, name)
        super("#{subnet}.#{name}")
      end

      def create(subnet, name, file)
        id = "#{subnet}.#{name}"
        record = model_class.create(id: id, payload: File.read(file))
        puts render_show_table(record)
      end

      def update(subnet, name, file)
        id = "#{subnet}.#{name}"
        record = model_class.find_id(id)
        record.update(payload: File.read(file))
        puts render_show_table(record)
      end

      def edit(subnet, name)
        id = "#{subnet}.#{name}"
        record = model_class.find_id(id)
        record.edit
        puts render_show_table(record)
      end

      def delete(subnet, name)
        id = "#{subnet}.#{name}"
        pp model_class.find_id(id).destroy
      end
    end

    class BootMethodCommand < RecordCommand
      def self.cli_type
        'bootmethod'
      end

      def self.model_class
        Models::BootMethod
      end

      def self.show_table
        @show_table ||= {
          'NAME' => ->(r) { r.id },
          'Status'=> ->(record) do
            if record.attributes['complete']
              'Both the kernel and initrd have been uploaded.'
            elsif record.attributes['kernel-uploaded']
              'Missing the initial ram disk! Please upload it.'
            elsif record.attributes['initrd-uploaded']
              'Missing the kernel! Please upload it.'
            else
              'Missing both the kernel and initrd! Please upload them.'
            end
          end,
          'Kernel Size' => ->(record) do
            record.attributes['kernel-uploaded'] ? record.attributes['kernel-size'] : 'n/a'
          end,
          'Initrd Size' => ->(record) do
            record.attributes['initrd-uploaded'] ? record.attributes['initrd-size'] : 'n/a'
          end
        }
      end

      def list
        models = model_class.all.map(&:id).sort
        if models.empty?
          $stderr.puts "No #{self.class.model_class.type} found!"
        else
          puts models
        end
      end

      def create(name)
        puts render_show_table(model_class.create(id: name))
      end

      def upload_kernel(name, path)
        model_class.find_id(name).upload_kernel(path)
        puts render_show_table(model_class.find_id(name))
      end

      def upload_initrd(name, path)
        model_class.find_id(name).upload_initrd(path)
        puts render_show_table(model_class.find_id(name))
      end

      def delete(name)
        pp model_class.find_id(name).destroy
      end
    end
  end
end

