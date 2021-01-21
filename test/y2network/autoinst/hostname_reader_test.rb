#!/usr/bin/env rspec

# Copyright (c) [2020] SUSE LLC
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
require "y2network/autoinst/hostname_reader"

describe Y2Network::Autoinst::HostnameReader do
  let(:subject) { described_class.new(dns_section) }

  let(:dns_section) do
    Y2Network::AutoinstProfile::DNSSection.new_from_hashes(profile["dns"])
  end

  let(:current_static_hostname) { "test" }
  let(:current_dhcp_hostname) { :any }

  before do
    allow_any_instance_of(Y2Network::Wicked::HostnameReader)
      .to receive(:static_hostname).and_return(current_static_hostname)
    allow_any_instance_of(Y2Network::Wicked::HostnameReader)
      .to receive(:dhcp_hostname).and_return(current_dhcp_hostname)
  end

  let(:profile) do
    {
      "dns" => {
        "hostname" => "host",
        "dhcp_hostname" => false, "write_hostname" => true
      }
    }
  end

  describe "#config" do
    it "builds a new Y2Network::Hostname config from the profile dns section" do
      config = subject.config
      expect(config).to be_a Y2Network::Hostname
      expect(config.installer).to eq("host")
      expect(config.dhcp_hostname).to eq(:none)
      expect(config.static).to eq("host")
    end

    context "when no hostname option is defined" do
      let(:profile) { { "dns" => { "dhcp_hostname" => true } } }

      it "reads the current hostname configuration from the system" do
        expect(subject.config.hostname).to eq(current_static_hostname)
      end
    end

    context "when no dhcp_hostname option is defined" do
      let(:profile) { { "dns" => { "hostname" => "another_host" } } }

      it "reads the current dhcp_hostname configuration from the system" do
        expect(subject.config.dhcp_hostname).to eq(current_dhcp_hostname)
      end
    end
  end
end
