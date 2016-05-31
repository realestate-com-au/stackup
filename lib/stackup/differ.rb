require "diffy"
require "stackup/utils"
require "yaml"

module Stackup

  # Generates diffs of data.
  #
  class Differ

    def initialize(diff_style = :color, &data_formatter)
      @diff_style = diff_style.to_sym
      @data_formatter = data_formatter || YAML.method(:dump)
    end

    attr_reader :diff_style

    include Utils

    def diff(existing_data, pending_data)
      existing = format(normalize_data(existing_data)) + "\n"
      pending = format(normalize_data(pending_data)) + "\n"
      diff = Diffy::Diff.new(existing, pending).to_s(diff_style)
      diff unless diff =~ /\A\s*\Z/
    end

    private

    def format(data)
      @data_formatter.call(data)
    end

  end

end
