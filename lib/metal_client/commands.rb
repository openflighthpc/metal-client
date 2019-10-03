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
        raise NotImplementedError
      end

      def self.model_class
        raise NotImplementedError
      end

      def list
        pp self.class.model_class.all.map(&:attributes)
      end

      def show(name)
        pp self.class.model_class.find(name).first.attributes
      end
    end

    class KickstartCommand < FileCommand
      def self.cli_type
        'kickstart'
      end

      def self.model_class
        Models::Kickstart
      end
    end

    class UefiCommand < FileCommand
      def self.cli_type
        'uefibootmenu'
      end

      def self.model_class
        Models::Uefi
      end
    end

    class LegacyCommand < FileCommand
      def self.cli_type
        'legacybootmenu'
      end

      def self.model_class
        Models::Legacy
      end
    end
  end
end

