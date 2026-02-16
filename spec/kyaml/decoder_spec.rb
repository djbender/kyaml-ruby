# frozen_string_literal: true

RSpec.describe KYAML::Decoder do
  def decode(input)
    KYAML::Decoder.new(input).decode
  end

  describe "#decode" do
    # Phase 1: Scalars

    context "with null" do
      it "decodes null" do
        expect(decode("---\nnull\n")).to be_nil
      end
    end

    context "with booleans" do
      it "decodes true" do
        expect(decode("---\ntrue\n")).to be true
      end

      it "decodes false" do
        expect(decode("---\nfalse\n")).to be false
      end
    end

    context "with integers" do
      it "decodes positive integer" do
        expect(decode("---\n42\n")).to eq(42)
      end

      it "decodes negative integer" do
        expect(decode("---\n-7\n")).to eq(-7)
      end

      it "decodes zero" do
        expect(decode("---\n0\n")).to eq(0)
      end
    end

    context "with floats" do
      it "decodes positive float" do
        expect(decode("---\n3.14\n")).to eq(3.14)
      end

      it "decodes negative float" do
        expect(decode("---\n-0.5\n")).to eq(-0.5)
      end
    end

    context "with strings" do
      it "decodes simple string" do
        expect(decode("---\n\"hello\"\n")).to eq("hello")
      end

      it "decodes empty string" do
        expect(decode("---\n\"\"\n")).to eq("")
      end

      it "decodes escaped double quotes" do
        expect(decode("---\n\"say \\\"hi\\\"\"\n")).to eq('say "hi"')
      end

      it "decodes escaped backslash" do
        expect(decode("---\n\"back\\\\slash\"\n")).to eq('back\\slash')
      end

      it "decodes escaped newline" do
        expect(decode("---\n\"line1\\nline2\"\n")).to eq("line1\nline2")
      end

      it "decodes escaped tab" do
        expect(decode("---\n\"col1\\tcol2\"\n")).to eq("col1\tcol2")
      end
    end

    # Phase 2: Collections

    context "with empty collections" do
      it "decodes empty hash" do
        expect(decode("---\n{}\n")).to eq({})
      end

      it "decodes empty array" do
        expect(decode("---\n[]\n")).to eq([])
      end
    end

    context "with hashes" do
      it "decodes single key-value pair" do
        expect(decode("---\n{\n  name: \"alice\",\n}\n")).to eq({"name" => "alice"})
      end

      it "decodes multiple key-value pairs" do
        input = "---\n{\n  name: \"alice\",\n  age: 30,\n}\n"
        expect(decode(input)).to eq({"name" => "alice", "age" => 30})
      end

      it "decodes mixed scalar value types" do
        input = "---\n{\n  s: \"hi\",\n  i: 1,\n  f: 2.5,\n  b: true,\n  n: null,\n}\n"
        expect(decode(input)).to eq({"s" => "hi", "i" => 1, "f" => 2.5, "b" => true, "n" => nil})
      end

      it "decodes quoted keys" do
        input = "---\n{\n  \"true\": \"v\",\n  \"42\": \"v\",\n}\n"
        expect(decode(input)).to eq({"true" => "v", "42" => "v"})
      end
    end

    context "with arrays" do
      it "decodes string array" do
        input = "---\n[\n  \"a\",\n  \"b\",\n]\n"
        expect(decode(input)).to eq(["a", "b"])
      end

      it "decodes mixed scalar array" do
        input = "---\n[\n  \"hi\",\n  1,\n  true,\n  null,\n]\n"
        expect(decode(input)).to eq(["hi", 1, true, nil])
      end
    end

    # Phase 3: Nesting

    context "with nested structures" do
      it "decodes hash-in-hash" do
        input = "---\n{\n  metadata: {\n    name: \"app\",\n  },\n}\n"
        expect(decode(input)).to eq({"metadata" => {"name" => "app"}})
      end

      it "decodes deeply nested hash" do
        input = "---\n{\n  a: {\n    b: {\n      c: \"deep\",\n    },\n  },\n}\n"
        expect(decode(input)).to eq({"a" => {"b" => {"c" => "deep"}}})
      end

      it "decodes hash containing array" do
        input = "---\n{\n  items: [\n    \"a\",\n    \"b\",\n  ],\n}\n"
        expect(decode(input)).to eq({"items" => ["a", "b"]})
      end

      it "decodes array of arrays" do
        input = "---\n[\n  [\n    \"a\",\n    \"b\",\n  ],\n  [\n    \"c\",\n  ],\n]\n"
        expect(decode(input)).to eq([["a", "b"], ["c"]])
      end

      it "decodes cuddled array of hashes" do
        input = "---\n[{\n  name: \"a\",\n}, {\n  name: \"b\",\n}]\n"
        expect(decode(input)).to eq([{"name" => "a"}, {"name" => "b"}])
      end

      it "decodes single-element cuddled array" do
        input = "---\n[{\n  a: 1,\n}]\n"
        expect(decode(input)).to eq([{"a" => 1}])
      end

      it "decodes mixed array with scalars and hashes" do
        input = "---\n[\n  \"x\",\n  {\n    name: \"y\",\n  },\n]\n"
        expect(decode(input)).to eq(["x", {"name" => "y"}])
      end
    end

    # Phase 4: Multiline Strings

    context "with multiline strings" do
      it "decodes simple multiline string" do
        input = "---\n\"\\n This\\n\\n is a\\n\\n multi-line string\\n\"\n"
        expect(decode(input)).to eq("This\nis a\nmulti-line string")
      end

      it "decodes multiline with leading-whitespace lines" do
        input = "---\n\"\\n this:\\n\\n\\\\  is:\\n\\n\\\\  - embedded\\n\"\n"
        expect(decode(input)).to eq("this:\n  is:\n  - embedded")
      end

      it "decodes multiline with trailing newline" do
        input = "---\n\"\\n line1\\n\\n line2\\n\\n\\n\"\n"
        expect(decode(input)).to eq("line1\nline2\n")
      end

      it "does not unfold single escaped newline" do
        expect(decode("---\n\"\\n\"\n")).to eq("\n")
      end

      it "does not unfold simple string with escaped newline" do
        expect(decode("---\n\"hello\\n\"\n")).to eq("hello\n")
      end
    end

    # Phase 5: Round-trip + Errors

    context "round-trip symmetry" do
      [
        nil,
        true,
        false,
        42,
        -7,
        0,
        3.14,
        -0.5,
        "hello",
        "",
        'say "hi"',
        "back\\slash",
        "col1\tcol2",
        {},
        {"name" => "alice"},
        {"s" => "hi", "i" => 1, "f" => 2.5, "b" => true, "n" => nil},
        [],
        ["a", "b"],
        {"metadata" => {"name" => "app"}},
        {"items" => ["a", "b"]},
        [{"name" => "a"}, {"name" => "b"}],
        [["a", "b"], ["c"]],
        "This\nis a\nmulti-line string",
        "this:\n  is:\n  - embedded"
      ].each do |obj|
        it "round-trips #{obj.inspect}" do
          expect(KYAML.load(KYAML.dump(obj))).to eq(obj)
        end
      end
    end

    context "error handling" do
      it "raises on missing --- prefix" do
        expect { decode("null\n") }.to raise_error(KYAML::ParseError, /expected "---\\n"/)
      end

      it "raises on unterminated string" do
        expect { decode("---\n\"hello\n") }.to raise_error(KYAML::ParseError)
      end

      it "raises on unexpected character" do
        expect { decode("---\n@\n") }.to raise_error(KYAML::ParseError, /unexpected character/)
      end

      it "raises on trailing garbage" do
        expect { decode("---\nnull garbage\n") }.to raise_error(KYAML::ParseError, /unexpected content/)
      end

      it "raises on unclosed hash" do
        expect { decode("---\n{\n  a: 1,\n\n") }.to raise_error(KYAML::ParseError)
      end

      it "raises on unclosed array" do
        expect { decode("---\n[\n  1,\n\n") }.to raise_error(KYAML::ParseError)
      end
    end
  end
end

RSpec.describe KYAML do
  describe ".load" do
    it "decodes a simple value" do
      expect(KYAML.load("---\n\"hello\"\n")).to eq("hello")
    end

    it "decodes a hash" do
      result = KYAML.load("---\n{\n  name: \"app\",\n}\n")
      expect(result).to eq({"name" => "app"})
    end

    it "decodes nil" do
      expect(KYAML.load("---\nnull\n")).to be_nil
    end
  end
end
