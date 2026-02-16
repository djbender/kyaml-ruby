# frozen_string_literal: true

module KYAML
  class Encoder
    def encode(value, depth: 0)
      case value
      when String then encode_string(value)
      when Integer then value.to_s
      when Float then value.to_s
      when true then "true"
      when false then "false"
      when nil then "null"
      when Hash then encode_hash(value, depth)
      when Array then encode_array(value, depth)
      else
        raise ArgumentError, "unsupported type: #{value.class}"
      end
    end

    private

    def encode_string(str)
      if str.count("\n") >= 2
        encode_multiline_string(str)
      else
        encode_simple_string(str)
      end
    end

    def encode_simple_string(str)
      escaped = str.gsub("\\", "\\\\\\\\").gsub('"', '\\"').gsub("\n", "\\n").gsub("\t", "\\t")
      "\"#{escaped}\""
    end

    def encode_multiline_string(str)
      lines = str.split("\n", -1)
      parts = lines.map do |line|
        if line.start_with?(" ", "\t")
          "\\#{escape_line(line)}"
        elsif line.empty?
          ""
        else
          " #{escape_line(line)}"
        end
      end
      "\"\\n#{parts.join("\\n\\n")}\\n\""
    end

    def escape_line(line)
      line.gsub("\\", "\\\\\\\\").gsub('"', '\\"').gsub("\t", "\\t")
    end

    def encode_hash(hash, depth)
      return "{}" if hash.empty?

      indent = "  " * (depth + 1)
      pairs = hash.map { |k, v| "#{indent}#{encode_key(k)}: #{encode(v, depth: depth + 1)}" }
      "{\n#{pairs.join(",\n")},\n#{"  " * depth}}"
    end

    def encode_array(array, depth)
      return "[]" if array.empty?

      if array.all?(Hash)
        encode_cuddled_array(array, depth)
      else
        indent = "  " * (depth + 1)
        items = array.map { |v| "#{indent}#{encode(v, depth: depth + 1)}" }
        "[\n#{items.join(",\n")},\n#{"  " * depth}]"
      end
    end

    def encode_cuddled_array(array, depth)
      items = array.map { |h| encode_hash(h, depth) }
      "[#{items.join(", ")}]"
    end

    AMBIGUOUS_KEYWORDS = Set.new(%w[
      true false yes no on off null
      True False Yes No On Off Null
      TRUE FALSE YES NO ON OFF NULL
    ]).freeze

    NUMERIC_PATTERN = /\A[+-]?(\d[\d_]*\.?[\d_]*([eE][+-]?\d+)?|0x[\da-fA-F_]+|0o[0-7_]+|0b[01_]+|\.\d[\d_]*([eE][+-]?\d+)?)\z/

    SAFE_KEY_PATTERN = /\A[a-zA-Z_][a-zA-Z0-9_.\/-]*\z/

    def encode_key(key)
      str = key.to_s
      if str.empty? || AMBIGUOUS_KEYWORDS.include?(str) || str.match?(NUMERIC_PATTERN) || !str.match?(SAFE_KEY_PATTERN)
        encode_string(str)
      else
        str
      end
    end
  end
end
