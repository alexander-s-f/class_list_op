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

  describe ".resolve_attributes" do
    it "merges non-class attributes like a regular hash merge" do
      defaults = { class: "flex gap-4", id: "main", data_role: "layout" }
      overrides = { id: "sidebar" }

      expect(described_class.resolve_attributes(defaults, overrides)).to eq(
        class: "flex gap-4",
        id: "sidebar",
        data_role: "layout"
      )
    end

    it "keeps regular class override semantics for string values" do
      defaults = { class: "flex gap-4", id: "main" }
      overrides = { class: "mb-4" }

      expect(described_class.resolve_attributes(defaults, overrides)).to eq(
        class: "mb-4",
        id: "main"
      )
    end

    it "resolves class operations against the default class list" do
      defaults = { class: "cols w-full md:flex md:flex-row md:space-x-4" }
      overrides = { class: { add: "mb-4", remove: "md:space-x-4" } }

      expect(described_class.resolve_attributes(defaults, overrides)).to eq(
        class: "cols w-full md:flex md:flex-row mb-4"
      )
    end

    it "accepts array-based default class parts" do
      defaults = { class: ["cols w-full md:flex", "md:flex-row md:space-x-4"] }
      overrides = { class: { add: "mb-4", remove: "md:space-x-4" } }

      expect(described_class.resolve_attributes(defaults, overrides)).to eq(
        class: "cols w-full md:flex md:flex-row mb-4"
      )
    end

    it "supports replace in class operations" do
      defaults = { class: "flex gap-4", id: "main" }
      overrides = { class: { replace: "grid gap-2" } }

      expect(described_class.resolve_attributes(defaults, overrides)).to eq(
        class: "grid gap-2",
        id: "main"
      )
    end

    it "raises for unsupported attribute input types" do
      expect { described_class.resolve_attributes([], {}) }
        .to raise_error(ClassList::InvalidInputError, "unsupported attribute input: Array")
    end
  end

  describe ".merge_attributes" do
    it "aliases resolve_attributes" do
      defaults = { class: "flex gap-4" }
      overrides = { class: { add: "mb-4" } }

      expect(described_class.merge_attributes(defaults, overrides))
        .to eq(described_class.resolve_attributes(defaults, overrides))
    end
  end

  describe ".variants" do
    let(:button_config) do
      {
        base: {
          container: "font-medium whitespace-nowrap text-center inline-flex items-center cursor-pointer",
          icon: "shrink-0"
        },
        defaults: {
          size: :md,
          tone: :default
        },
        dimensions: {
          size: {
            xs: {
              container: "px-1.5 py-1 rounded-md text-xs",
              icon: "size-3"
            },
            md: {
              container: "px-3 py-2 rounded-lg text-sm",
              icon: "size-4"
            }
          },
          tone: {
            default: {
              container: "text-white bg-blue-600 hover:bg-blue-700 focus:ring-blue-800"
            },
            red: {
              container: "text-white bg-red-600 hover:bg-red-700 focus:ring-red-800"
            }
          }
        }
      }
    end

    it "builds slot attributes from base and selected dimensions" do
      variants = described_class.variants(button_config)

      expect(variants.attributes(:container, size: :xs, tone: :red)).to eq(
        class: "font-medium whitespace-nowrap text-center inline-flex items-center cursor-pointer " \
               "px-1.5 py-1 rounded-md text-xs text-white bg-red-600 hover:bg-red-700 focus:ring-red-800"
      )
    end

    it "uses configured defaults for omitted dimensions" do
      variants = described_class.variants(button_config)

      expect(variants.resolve(:container)).to eq(
        "font-medium whitespace-nowrap text-center inline-flex items-center cursor-pointer " \
        "px-3 py-2 rounded-lg text-sm text-white bg-blue-600 hover:bg-blue-700 focus:ring-blue-800"
      )
    end

    it "applies attribute overrides after resolving variants" do
      variants = described_class.variants(button_config)

      expect(
        variants.attributes(:container, tone: :red, class: { add: "w-full", remove: "rounded-lg" }, id: "cta")
      ).to eq(
        class: "font-medium whitespace-nowrap text-center inline-flex items-center cursor-pointer " \
               "px-3 py-2 text-sm text-white bg-red-600 hover:bg-red-700 focus:ring-red-800 w-full",
        id: "cta"
      )
    end

    it "returns slot-specific attributes for additional slots" do
      variants = described_class.variants(button_config)

      expect(variants.attributes(:icon, size: :xs)).to eq(class: "shrink-0 size-3")
    end

    it "accepts string-keyed config" do
      string_keyed_config = {
        "base" => { "container" => "inline-flex" },
        "defaults" => { "size" => "md" },
        "dimensions" => {
          "size" => {
            "md" => { "container" => "px-3 py-2" }
          }
        }
      }

      expect(described_class.variants(string_keyed_config).resolve(:container)).to eq("inline-flex px-3 py-2")
    end

    it "raises for unknown variant options" do
      variants = described_class.variants(button_config)

      expect { variants.attributes(:container, size: :xl) }
        .to raise_error(ClassList::InvalidVariantError, 'unknown option :xl for dimension :size')
    end
  end
end
