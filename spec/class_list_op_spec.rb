# frozen_string_literal: true

RSpec.describe ClassList do
  describe ".normalize" do
    it "splits a string into tokens" do
      expect(described_class.normalize("flex gap-4")).to eq(%w[flex gap-4])
    end

    it "flattens nested arrays and ignores nils" do
      value = ["flex gap-4", ["mb-2", nil, ""]]

      expect(described_class.normalize(value)).to eq(%w[flex gap-4 mb-2])
    end

    it "accepts symbols" do
      expect(described_class.normalize(:flex)).to eq(["flex"])
    end

    it "raises for unsupported input types" do
      expect { described_class.normalize({ hidden: true }) }
        .to raise_error(ClassList::InvalidInputError, "unsupported class input: Hash")
    end
  end

  describe ".tokens" do
    it "returns normalized base tokens" do
      expect(described_class.tokens("flex gap-4")).to eq(%w[flex gap-4])
    end

    it "adds tokens to the end" do
      expect(described_class.tokens("flex", add: "mb-4")).to eq(%w[flex mb-4])
    end

    it "removes exact tokens" do
      expect(described_class.tokens("flex md:flex gap-4", remove: "md:flex")).to eq(%w[flex gap-4])
    end

    it "applies remove before add" do
      expect(described_class.tokens("flex", remove: "flex", add: "flex")).to eq(%w[flex])
    end

    it "replaces the base tokens" do
      expect(described_class.tokens("flex gap-4", replace: "mb-4")).to eq(%w[mb-4])
    end

    it "deduplicates while preserving first appearance order" do
      expect(described_class.tokens("flex gap-4", add: "gap-4 mb-4")).to eq(%w[flex gap-4 mb-4])
    end

    it "raises for unknown operations" do
      expect { described_class.tokens("flex", toggle: "hidden") }
        .to raise_error(ClassList::InvalidOperationError, "unknown operations: toggle")
    end

    it "raises when replace is combined with add or remove" do
      expect { described_class.tokens("flex", replace: "grid", add: "mb-4") }
        .to raise_error(ClassList::InvalidOperationError, "replace cannot be combined with add/remove")
    end
  end

  describe ".resolve" do
    it "joins resolved tokens into a string" do
      expect(described_class.resolve("flex gap-4", add: "mb-4")).to eq("flex gap-4 mb-4")
    end
  end

  describe ".call" do
    it "aliases resolve" do
      expect(described_class.call("flex gap-4", remove: "gap-4")).to eq("flex")
    end
  end

  describe ".list" do
    it "returns an immutable list" do
      list = described_class.list("flex gap-4")
      updated = list.remove("gap-4").add("mb-4")

      expect(list.tokens).to eq(%w[flex gap-4])
      expect(updated.tokens).to eq(%w[flex mb-4])
    end

    it "stringifies the tokens" do
      list = described_class.list("flex gap-4")

      expect(list.to_s).to eq("flex gap-4")
    end

    it "freezes the tokens array" do
      list = described_class.list("flex gap-4")

      expect(list.tokens).to be_frozen
    end
  end
end
