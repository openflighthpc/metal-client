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
  class MetalClientError < StandardError; end

  class ExistingRecordError < StandardError
    def self.from_record(record)
      new <<~ERROR.chomp
        Can not create #{record.class.singular_type} #{record.id} as it already exists
      ERROR
    end
  end

  class MetalAPIError < MetalClientError
    def self.from_api_error(error)
      new(error.env.body['errors'].first['detail'])
    end
  end

  class NotFoundError < MetalAPIError; end
  class ClientError < MetalAPIError; end
  class InternalServerError < MetalAPIError; end
end

