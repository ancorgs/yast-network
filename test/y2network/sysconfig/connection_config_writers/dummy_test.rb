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

require_relative "../../../test_helper"

require "y2network/sysconfig/connection_config_writers/dummy"
require "y2network/startmode"
require "y2network/boot_protocol"
require "y2network/connection_config/dummy"
require "y2network/connection_config/ip_config"

describe Y2Network::Sysconfig::ConnectionConfigWriters::Dummy do
  subject(:handler) { described_class.new(file) }

  let(:scr_root) { Dir.mktmpdir }

  around do |example|

    FileUtils.cp_r(File.join(DATA_PATH, "scr_read", "etc"), scr_root)
    change_scr_root(scr_root, &example)
  ensure
    FileUtils.remove_entry(scr_root)

  end

  let(:ip) do
    Y2Network::ConnectionConfig::IPConfig.new(Y2Network::IPAddress.from_string("10.0.0.100/24"))
  end

  let(:conn) do
    Y2Network::ConnectionConfig::Dummy.new.tap do |c|
      c.name = "dummy1"
      c.interface = "dummy1"
      c.description = ""
      c.ip = ip
      c.bootproto = Y2Network::BootProtocol::STATIC
      c.startmode = Y2Network::Startmode.create("auto")
    end
  end

  let(:file) { CFA::InterfaceFile.new(conn.name) }

  describe "#write" do
    it "writes common properties" do
      handler.write(conn)
      expect(file).to have_attributes(
        bootproto: "static",
        startmode: "auto"
      )
    end

    it "writes the interfacetype as 'dummy'" do
      handler.write(conn)
      expect(file).to have_attributes(
        interfacetype: Y2Network::InterfaceType::DUMMY.short_name
      )
    end
  end
end
