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

module MetalClient
  module Commands
    class FileCommand
      def self.inherited(base)
        FileCommand.inherited_classes << base
      end

      def self.inherited_classes
        @inherited_classes ||= []
      end

      def self.cli_type
        model_class.singular_type
      end

      def self.model_class
        raise NotImplementedError
      end

      def model_class
        self.class.model_class
      end

      def list
        models = model_class.all.map(&:id).sort
        if models.empty?
          $stderr.puts "No #{self.class.model_class.type} found!"
        else
          puts models
        end
      end

      def show(name)
        pp model_class.find(name).attributes
      end

      def create(name, file)
        pp model_class.create(name, payload: File.read(file)).attributes
      end

      def update(name, file)
        pp model_class.update(name, payload: File.read(file)).attributes
      end

      def edit(name)
      end
    end

    class KickstartCommand < FileCommand
      def self.model_class
        Models::Kickstart
      end
    end

    class UefiCommand < FileCommand
      def self.model_class
        Models::Uefi
      end
    end

    class LegacyCommand < FileCommand
      def self.model_class
        Models::Legacy
      end
    end

    # Does not inherit off FileCommand as it must form a composite of the kernels and initrds
    class BootMethodCommand
      def self.cli_type
        'bootmethod'
      end

      def list
      end
    end
  end
end

