# frozen_string_literal: true

require_relative "kyaml/version"
require_relative "kyaml/encoder"
require_relative "kyaml/decoder"

module KYAML
  def self.dump(obj)
    "---\n#{Encoder.new.encode(obj)}\n"
  end

  def self.load(str)
    Decoder.new(str).decode
  end
end
