# frozen_string_literal: true

RSpec.describe KYAML::Encoder do
  subject(:encoder) { described_class.new }

  describe "#encode" do
    context "with strings" do
      it "double-quotes a simple string" do
        expect(encoder.encode("hello")).to eq('"hello"')
      end

      it "escapes embedded double quotes" do
        expect(encoder.encode('say "hi"')).to eq('"say \\"hi\\""')
      end

      it "escapes backslashes" do
        expect(encoder.encode('back\\slash')).to eq('"back\\\\slash"')
      end

      it "escapes newlines" do
        expect(encoder.encode("line1\nline2")).to eq('"line1\\nline2"')
      end

      it "escapes tabs" do
        expect(encoder.encode("col1\tcol2")).to eq('"col1\\tcol2"')
      end

      it "handles empty string" do
        expect(encoder.encode("")).to eq('""')
      end
    end

    context "with integers" do
      it "renders as bare number" do
        expect(encoder.encode(42)).to eq("42")
      end

      it "renders negative integers" do
        expect(encoder.encode(-7)).to eq("-7")
      end

      it "renders zero" do
        expect(encoder.encode(0)).to eq("0")
      end
    end

    context "with floats" do
      it "renders as bare number" do
        expect(encoder.encode(3.14)).to eq("3.14")
      end

      it "renders negative floats" do
        expect(encoder.encode(-0.5)).to eq("-0.5")
      end
    end

    context "with booleans" do
      it "renders true" do
        expect(encoder.encode(true)).to eq("true")
      end

      it "renders false" do
        expect(encoder.encode(false)).to eq("false")
      end
    end

    context "with nil" do
      it "renders as null" do
        expect(encoder.encode(nil)).to eq("null")
      end
    end

    context "with hashes" do
      it "renders empty hash" do
        expect(encoder.encode({})).to eq("{}")
      end

      it "renders single key-value pair" do
        expect(encoder.encode({"name" => "alice"})).to eq("{\n  name: \"alice\",\n}")
      end

      it "renders multiple key-value pairs" do
        result = encoder.encode({"name" => "alice", "age" => 30})
        expect(result).to eq("{\n  name: \"alice\",\n  age: 30,\n}")
      end

      it "renders hash with various scalar values" do
        input = {"s" => "hi", "i" => 1, "f" => 2.5, "b" => true, "n" => nil}
        expected = "{\n  s: \"hi\",\n  i: 1,\n  f: 2.5,\n  b: true,\n  n: null,\n}"
        expect(encoder.encode(input)).to eq(expected)
      end
    end

    context "with arrays" do
      it "renders empty array" do
        expect(encoder.encode([])).to eq("[]")
      end

      it "renders array of scalars" do
        expect(encoder.encode(["a", "b"])).to eq("[\n  \"a\",\n  \"b\",\n]")
      end

      it "renders array of mixed scalars" do
        result = encoder.encode(["hi", 1, true, nil])
        expect(result).to eq("[\n  \"hi\",\n  1,\n  true,\n  null,\n]")
      end
    end

    context "with nested structures" do
      it "renders hash containing hash" do
        input = {"metadata" => {"name" => "app"}}
        expected = "{\n  metadata: {\n    name: \"app\",\n  },\n}"
        expect(encoder.encode(input)).to eq(expected)
      end

      it "renders hash containing array" do
        input = {"items" => ["a", "b"]}
        expected = "{\n  items: [\n    \"a\",\n    \"b\",\n  ],\n}"
        expect(encoder.encode(input)).to eq(expected)
      end

      it "renders array of hashes with bracket cuddling" do
        input = [{"name" => "a"}, {"name" => "b"}]
        expected = "[{\n  name: \"a\",\n}, {\n  name: \"b\",\n}]"
        expect(encoder.encode(input)).to eq(expected)
      end

      it "renders array of arrays" do
        input = [["a", "b"], ["c"]]
        expected = "[\n  [\n    \"a\",\n    \"b\",\n  ],\n  [\n    \"c\",\n  ],\n]"
        expect(encoder.encode(input)).to eq(expected)
      end

      it "renders deeply nested structure" do
        input = {"a" => {"b" => {"c" => "deep"}}}
        expected = "{\n  a: {\n    b: {\n      c: \"deep\",\n    },\n  },\n}"
        expect(encoder.encode(input)).to eq(expected)
      end

      it "renders mixed array with scalars and hashes" do
        input = ["x", {"name" => "y"}]
        expected = "[\n  \"x\",\n  {\n    name: \"y\",\n  },\n]"
        expect(encoder.encode(input)).to eq(expected)
      end

      it "renders array of only hashes with cuddling" do
        input = [{"a" => 1}]
        expected = "[{\n  a: 1,\n}]"
        expect(encoder.encode(input)).to eq(expected)
      end
    end

    context "with key quoting" do
      it "leaves safe keys unquoted" do
        %w[apiVersion app foo-bar kubernetes.io/name metadata].each do |key|
          result = encoder.encode({key => "v"})
          expect(result).to include("#{key}: \"v\""), "expected #{key} unquoted"
        end
      end

      it "quotes YAML boolean words" do
        %w[true false yes no on off].each do |key|
          result = encoder.encode({key => "v"})
          expect(result).to include("\"#{key}\": \"v\""), "expected #{key} quoted"
        end
      end

      it "quotes null keyword" do
        result = encoder.encode({"null" => "v"})
        expect(result).to include('"null": "v"')
      end

      it "quotes numeric-looking keys" do
        %w[42 3.14 0x1A 0o77 0b101 1_000 -5 +3 .5 1e10 1.2e-3].each do |key|
          result = encoder.encode({key => "v"})
          expect(result).to include("\"#{key}\": \"v\""), "expected #{key} quoted"
        end
      end

      it "quotes keys with special characters" do
        result = encoder.encode({"has space" => "v"})
        expect(result).to include('"has space": "v"')
      end

      it "quotes keys with colons" do
        result = encoder.encode({"key: val" => "v"})
        expect(result).to include('"key: val": "v"')
      end

      it "quotes keys with braces" do
        ["{", "}", "[", "]"].each do |ch|
          result = encoder.encode({"a#{ch}b" => "v"})
          expect(result).to include("\"a#{ch}b\": \"v\""), "expected key with #{ch} quoted"
        end
      end

      it "quotes empty string key" do
        result = encoder.encode({"" => "v"})
        expect(result).to include('"": "v"')
      end
    end

    context "with multi-line strings" do
      it "flow-folds a simple multi-line string" do
        input = "This\nis a\nmulti-line string"
        # Each line gets extra space for alignment, \n for newlines, \ for fold
        expected = "\"\\n" \
                   " This\\n\\n" \
                   " is a\\n\\n" \
                   " multi-line string\\n" \
                   "\""
        expect(encoder.encode(input)).to eq(expected)
      end

      it "preserves leading whitespace with backslash escape" do
        input = "this:\n  is:\n  - embedded"
        expected = "\"\\n" \
                   " this:\\n\\n" \
                   "\\  is:\\n\\n" \
                   "\\  - embedded\\n" \
                   "\""
        expect(encoder.encode(input)).to eq(expected)
      end

      it "handles single-line strings without folding" do
        expect(encoder.encode("no newlines here")).to eq('"no newlines here"')
      end

      it "handles string that is just a newline" do
        expect(encoder.encode("\n")).to eq('"\\n"')
      end

      it "handles trailing newline with single line" do
        expect(encoder.encode("hello\n")).to eq('"hello\\n"')
      end

      it "flow-folds string with trailing newline and multiple lines" do
        input = "line1\nline2\n"
        expected = "\"\\n" \
                   " line1\\n\\n" \
                   " line2\\n\\n" \
                   "\\n" \
                   "\""
        expect(encoder.encode(input)).to eq(expected)
      end
    end

    context "with unsupported types" do
      it "raises ArgumentError" do
        expect { encoder.encode(Object.new) }.to raise_error(ArgumentError, /unsupported type/)
      end
    end
  end
end

RSpec.describe KYAML do
  describe ".dump" do
    it "prefixes output with ---" do
      expect(KYAML.dump("hello")).to eq("---\n\"hello\"\n")
    end

    it "dumps a hash with --- prefix" do
      result = KYAML.dump({"name" => "app"})
      expect(result).to start_with("---\n{")
      expect(result).to end_with("}\n")
    end

    it "dumps nil" do
      expect(KYAML.dump(nil)).to eq("---\nnull\n")
    end
  end
end
