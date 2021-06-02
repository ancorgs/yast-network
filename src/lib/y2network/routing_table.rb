# Copyright (c) [2019] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require "forwardable"
require "y2network/equatable"

module Y2Network
  # Represents a {https://en.wikipedia.org/wiki/Routing_table routing table}
  #
  # @example Adding routes
  #   table = Y2Network::RoutingTable.new
  #   route = Y2Network::Route.new(to: IPAddr.new("192.168.122.0/24"))
  #   table << route
  #
  # @example Iterating through routes
  #   table.map { |r| r.to } #=> [<IPAddr: IPv4:192.168.122.0/255.255.255.0>]
  class RoutingTable
    extend Forwardable
    include Enumerable
    include Equatable

    # @return [Array<Route>] Routes included in the table
    attr_reader :routes

    eql_attr :routes

    def_delegator :@routes, :each

    def initialize(routes = [])
      @routes = routes
    end

    # Returns the default route
    def remove_default_routes
      @routes.reject!(&:default?)
    end
  end
end
