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
require "cwm/rspec"

require "y2network/dialogs/additional_address"

describe Y2Network::Dialogs::AdditionalAddress do
  let(:builder) do
    Y2Network::InterfaceConfigBuilder.for("eth").tap do |eth_builder|
      eth_builder.name = "eth0"
    end
  end

  let(:ip_settings) { OpenStruct.new(builder.alias_for(nil)) }

  subject { described_class.new(builder.name, ip_settings) }

  include_examples "CWM::Dialog"

  describe "#run" do
    let(:ret_code) { :cancel }

    before do
      allow(subject).to receive(:cwm_show).and_return(ret_code)
    end

    context "when the modifications are applied" do
      let(:ret_code) { :ok }

      before do
        ip_settings.ip_address = "192.168.20.200"
        ip_settings.subnet_prefix = "/24"
      end

      context "and the address is not valid" do
        it "reports a validation error" do
          ip_settings.subnet_prefix = "/64"
          allow(subject).to receive(:cwm_show).and_return(:ok, :cancel)
          expect(Yast::Report).to receive(:Error).with(/Invalid/)

          subject.run
        end
      end

      context "and the modified IP address settings uses a netmask" do
        it "converts the netmask to its equivalent prefix length" do
          ip_settings.subnet_prefix = "255.255.255.0"
          expect { subject.run }
            .to change { ip_settings.subnet_prefix }.from("255.255.255.0").to("/24")
        end
      end

      context "and the modified IP address settings uses a prefix length without '/'" do
        it "sets the prefix lenght correctly" do
          ip_settings.subnet_prefix = "32"
          expect { subject.run }
            .to change { ip_settings.subnet_prefix }.from("32").to("/32")
        end
      end
    end
  end
end

describe Y2Network::Dialogs::IPAddressLabel do
  let(:label) { "foo" }
  let(:builder) do
    Y2Network::InterfaceConfigBuilder.for("eth").tap do |eth_builder|
      eth_builder.name = "eth0"
      eth_builder.aliases = [eth_builder.alias_for(ip_alias)]
    end
  end

  let(:ip_alias) do
    Y2Network::ConnectionConfig::IPConfig.new(
      Y2Network::IPAddress.from_string("192.168.20.200/24"),
      id: "_0", label: "bar"
    )
  end

  let(:ip_settings) { OpenStruct.new(builder.aliases[0]) }
  let(:focus) { false }

  subject { described_class.new(builder.name, ip_settings, focus: focus) }

  include_examples "CWM::InputField"

  before do
    allow(subject).to receive(:value).and_return(label)
  end

  describe "#init" do
    it "sets the input value with the IP settings label" do
      expect(subject).to receive(:value=).with("bar")

      subject.init
    end

    context "when it is initialized with the focus option as true" do
      let(:focus) { true }

      it "gets the focus" do
        expect(subject).to receive(:focus)

        subject.init
      end
    end
  end

  describe "#validate" do
    context "when the join of the name and the value with ':' is longer than 15" do
      let(:label) { "tooolonglabel" }

      it "returns false" do
        expect(subject.validate).to eql(false)
      end
    end

    context "when the label is valid" do
      it "modifies the ip_settings label" do
        expect { subject.store }
          .to change { ip_settings.label }.from("bar").to("foo")
      end
    end
  end
end
