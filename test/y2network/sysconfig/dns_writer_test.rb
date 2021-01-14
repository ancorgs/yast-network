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
require_relative "../../test_helper"
require "y2network/sysconfig/dns_writer"
require "ipaddr"

describe Y2Network::Sysconfig::DNSWriter do
  subject(:writer) { described_class.new }

  describe "#write" do

    let(:dhcp_hostname) { :any }
    let(:dns) do
      Y2Network::DNS.new(
        nameservers:        [IPAddr.new("10.0.0.1"), IPAddr.new("10.0.0.2")],
        hostname:           hostname,
        searchlist:         ["example.net", "example.org"],
        resolv_conf_policy: "auto",
        dhcp_hostname:      dhcp_hostname
      )
    end

    let(:old_dhcp_hostname) { :none }
    let(:old_dns) do
      Y2Network::DNS.new(
        nameservers:        [IPAddr.new("10.0.0.1")],
        hostname:           "linux-abcd.example.org",
        searchlist:         ["example.org"],
        resolv_conf_policy: "auto",
        dhcp_hostname:      old_dhcp_hostname
      )
    end
    let(:hostname) { "myhost.example.net" }
    let(:ifcfg_eth0) do
      instance_double(
        CFA::InterfaceFile, interface: "eth0",
        dhclient_set_hostname: "yes", :dhclient_set_hostname= => nil, load: nil, save: nil
      )
    end
    let(:ifcfg_eth1) do
      instance_double(
        CFA::InterfaceFile, interface: "eth1",
        dhclient_set_hostname: "no", :dhclient_set_hostname= => nil, load: nil, save: true
      )
    end

    before do
      allow(Yast::SCR).to receive(:Write)
      allow(Yast::Execute).to receive(:on_target!)
      allow(CFA::InterfaceFile).to receive(:all)
        .and_return([ifcfg_eth0, ifcfg_eth1])
    end

    context "when sendmail update script is installed" do
      before do
        allow(Yast::FileUtils).to receive(:Exists).with(/sendmail/).and_return(true)
      end

      it "updates MTA configuration" do
        expect(Yast::Execute).to receive(:on_target!).with(/sendmail/)
        writer.write(dns, old_dns)
      end
    end

    context "when sendmail update script is not installed" do
      before do
        allow(Yast::FileUtils).to receive(:Exists).with(/sendmail/).and_return(false)
      end

      it "updates MTA configuration" do
        expect(Yast::Execute).to_not receive(:on_target!).with(/sendmail/)
        writer.write(dns, old_dns)
      end
    end

    it "updates DNS policy" do
      expect(Yast::SCR).to receive(:Write)
        .with(Yast::Path.new(".sysconfig.network.config.NETCONFIG_DNS_POLICY"), "auto")
      writer.write(dns, old_dns)
    end

    it "updates the list of search domains" do
      expect(Yast::SCR).to receive(:Write)
        .with(
          Yast::Path.new(".sysconfig.network.config.NETCONFIG_DNS_STATIC_SEARCHLIST"),
          "example.net example.org"
        )
      writer.write(dns, old_dns)
    end

    it "updates the list of name servers" do
      expect(Yast::SCR).to receive(:Write)
        .with(
          Yast::Path.new(".sysconfig.network.config.NETCONFIG_DNS_STATIC_SERVERS"),
          "10.0.0.1 10.0.0.2"
        )
      writer.write(dns, old_dns)
    end

    it "runs the netconfig script" do
      expect(Yast::Execute).to receive(:on_target!).with("/sbin/netconfig", "update")
      writer.write(dns, old_dns)
    end

    context "when the DNS has not changed" do
      let(:old_dns) { dns.clone }

      it "does not make any change" do
        expect(Yast::SCR).to_not receive(:Write)
        expect(Yast::Execute).to_not receive(:on_target!)
        writer.write(dns, old_dns)
      end
    end
  end
end
