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
require "yast"
require "y2network/dns"

Yast.import "Mode"

module Y2Network
  module Wicked
    # Reads DNS configuration from sysconfig files
    class DNSReader
      include Yast::Logger

      # Return configuration from sysconfig files
      #
      # @return [Y2Network::DnsConfig] DNS configuration
      def config
        Y2Network::DNS.new(
          nameservers:        nameservers,
          searchlist:         searchlist,
          resolv_conf_policy: resolv_conf_policy
        )
      end

    private

      # Nameservers from sysconfig
      #
      # Does not include invalid addresses
      #
      # @return [Array<IPAddr>]
      def nameservers
        servers = Yast::SCR.Read(
          Yast::Path.new(".sysconfig.network.config.NETCONFIG_DNS_STATIC_SERVERS")
        ).to_s.split

        servers.each_with_object([]) do |str, ips|

          ips << IPAddr.new(str)
        rescue IPAddr::InvalidAddressError
          log.warn "Invalid IP address: #{str}"

        end
      end

      # Returns the resolv.conf update policy
      #
      # @return [String]
      def resolv_conf_policy
        value = Yast::SCR.Read(
          Yast::Path.new(".sysconfig.network.config.NETCONFIG_DNS_POLICY")
        )
        (value.nil? || value.empty?) ? "default" : value
      end

      # Return the list of search domains
      #
      # @return [Array<String>]
      def searchlist
        Yast::SCR.Read(
          Yast::Path.new(".sysconfig.network.config.NETCONFIG_DNS_STATIC_SEARCHLIST")
        ).to_s.split
      end
    end
  end
end
