# frozen_string_literal: true

require_relative "kyaml/version"
require_relative "kyaml/encoder"

module KYAML
  def self.dump(obj)
    "---\n#{Encoder.new.encode(obj)}\n"
  end
end
