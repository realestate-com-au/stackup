module Stackup

  # Generates diffs of data.
  #
  module Utils

    def normalize_data(data)
      case data
      when Hash
        pairs = data.sort.map { |k, v| [k, normalize_data(v)] }
        Hash[pairs]
      when Array
        data.map { |x| normalize_data(x) }
      else
        data
      end
    end

  end

end
