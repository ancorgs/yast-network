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

require_relative "../test_helper"
require "y2network/udev_rule_part"

describe Y2Network::UdevRulePart do
  subject(:part) { described_class.new(key, operator, value) }

  let(:key) { "ACTION" }
  let(:operator) { "==" }
  let(:value) { "add" }

  describe ".from_string" do
    it "returns an udev rule part extracting the elements from the string" do
      part = described_class.from_string("ACTION==\"add\"")
      expect(part.key).to eq("ACTION")
      expect(part.operator).to eq("==")
      expect(part.value).to eq("add")

      part = described_class.from_string("ATTR{dev_id}==\"0x0\"")
      expect(part.key).to eq("ATTR{dev_id}")
      expect(part.operator).to eq("==")
      expect(part.value).to eq("0x0")
    end

    it "returns nil in case of an invalid udev rule" do
      part = described_class.from_string("ENV{MODALIAS}==\"\"")
      expect(part).to be_nil
    end
  end

  describe "#to_s" do
    it "returns an string representation compatible with rules files format" do
      expect(part.to_s).to eq('ACTION=="add"')
    end
  end

  describe "#==" do
    let(:other) { described_class.new("ACTION", "==", "add") }

    context "when key, operator and value are the same" do
      it "returns true" do
        expect(part).to eq(other)
      end
    end

    context "when the key differs" do
      let(:key) { "ENV{var1}" }

      it "returns false" do
        expect(part).to_not eq(other)
      end
    end

    context "when the operator differs" do
      let(:operator) { "!=" }

      it "returns false" do
        expect(part).to_not eq(other)
      end
    end

    context "when the value differs" do
      let(:value) { "remove" }

      it "returns false" do
        expect(part).to_not eq(other)
      end
    end
  end

  describe "#mac?" do
    context "when the part is a MAC address" do
      let(:key) { "ATTR{address}" }

      it "returns true" do
        expect(part.mac?).to eq(true)
      end
    end

    context "otherwise" do
      it "returns false" do
        expect(part.mac?).to eq(false)
      end
    end
  end

  describe "#bus_id?" do
    context "when the part is a BUS ID" do
      let(:key) { "KERNELS" }

      it "returns true" do
        expect(part.bus_id?).to eq(true)
      end
    end

    context "otherwise" do
      it "returns false" do
        expect(part.bus_id?).to eq(false)
      end
    end
  end

  describe "#dev_port?" do
    context "when the part is a dev port" do
      let(:key) { "ATTR{dev_port}" }

      it "returns true" do
        expect(part.dev_port?).to eq(true)
      end
    end

    context "otherwise" do
      it "returns false" do
        expect(part.dev_port?).to eq(false)
      end
    end
  end

  describe "#name?" do
    context "when the part is a device name" do
      let(:key) { "NAME" }
      let(:operator) { "=" }

      it "returns true" do
        expect(part.name?).to eq(true)
      end
    end

    context "otherwise" do
      it "returns false" do
        expect(part.name?).to eq(false)
      end
    end
  end
end
