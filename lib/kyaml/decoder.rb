# frozen_string_literal: true

module KYAML
  class ParseError < StandardError; end

  class Decoder
    def initialize(input)
      @input = input
      @pos = 0
    end

    def decode
      expect_prefix("---\n")
      value = parse_value
      skip_whitespace
      unless @pos == @input.length
        error("unexpected content after value")
      end
      value
    end

    private

    def parse_value
      skip_whitespace
      ch = peek
      case ch
      when '"' then parse_string
      when "{" then parse_hash
      when "[" then parse_array
      when "t" then parse_true
      when "f" then parse_false
      when "n" then parse_null
      when "-", "0".."9" then parse_number
      else
        error("unexpected character: #{ch.inspect}")
      end
    end

    def parse_null
      expect_prefix("null")
      nil
    end

    def parse_true
      expect_prefix("true")
      true
    end

    def parse_false
      expect_prefix("false")
      false
    end

    def parse_number
      start = @pos
      advance if peek == "-"
      digits = false
      while peek&.match?(/[0-9]/)
        advance
        digits = true
      end
      error("expected digit") unless digits
      if peek == "."
        advance
        frac_digits = false
        while peek&.match?(/[0-9]/)
          advance
          frac_digits = true
        end
        error("expected digit after decimal point") unless frac_digits
        @input[start...@pos].to_f
      else
        @input[start...@pos].to_i
      end
    end

    def parse_string
      expect_char('"')
      buf = +""
      loop do
        ch = peek || error("unterminated string")
        if ch == "\\"
          advance
          buf << parse_escape
        elsif ch == '"'
          advance
          break
        else
          buf << ch
          advance
        end
      end
      unfold_multiline(buf)
    end

    def parse_escape
      ch = peek || error("unterminated escape")
      advance
      case ch
      when "n" then "\n"
      when "t" then "\t"
      when "\\" then "\\"
      when '"' then '"'
      when " " then "\\ "
      else
        error("unknown escape: \\#{ch}")
      end
    end

    def unfold_multiline(str)
      return str unless str.start_with?("\n") && str.end_with?("\n") && str.length > 1 && str.include?("\n\n")
      inner = str[1...-1]
      segments = inner.split("\n\n", -1)
      lines = segments.map do |seg|
        if seg.start_with?(" ")
          seg[1..]
        elsif seg.start_with?("\\")
          seg[1..]
        else
          seg
        end
      end
      lines.join("\n")
    end

    def parse_hash
      expect_char("{")
      skip_whitespace
      result = {}
      if peek == "}"
        advance
        return result
      end
      loop do
        skip_whitespace
        key = parse_key
        skip_whitespace
        expect_char(":")
        skip_whitespace
        value = parse_value
        result[key] = value
        skip_whitespace
        if peek == ","
          advance
          skip_whitespace
          break if peek == "}"
        end
      end
      expect_char("}")
      result
    end

    def parse_key
      if peek == '"'
        parse_string
      else
        parse_bare_key
      end
    end

    def parse_bare_key
      start = @pos
      unless peek&.match?(/[a-zA-Z_]/)
        error("expected key")
      end
      advance
      while peek&.match?(/[a-zA-Z0-9_.\/-]/)
        advance
      end
      @input[start...@pos]
    end

    def parse_array
      expect_char("[")
      skip_whitespace
      result = []
      if peek == "]"
        advance
        return result
      end
      loop do
        skip_whitespace
        result << parse_value
        skip_whitespace
        break if peek == "]"
        if peek == ","
          advance
          skip_whitespace
          break if peek == "]"
        end
      end
      expect_char("]")
      result
    end

    # Helpers

    def peek
      return nil if @pos >= @input.length
      @input[@pos]
    end

    def advance
      ch = @input[@pos]
      @pos += 1
      ch
    end

    def expect_char(expected)
      ch = peek
      if ch != expected
        error("expected #{expected.inspect}, got #{ch.inspect}")
      end
      advance
    end

    def expect_prefix(prefix)
      if @input[@pos, prefix.length] != prefix
        error("expected #{prefix.inspect}")
      end
      @pos += prefix.length
    end

    def skip_whitespace
      while peek&.match?(/[ \t\n\r]/)
        advance
      end
    end

    def error(msg)
      raise ParseError, "#{msg} at position #{@pos}"
    end
  end
end
