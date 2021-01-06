# frozen_string_literal: false

require "test-unit"

require "rexml/document"

module Helper
  module Fixture
    def fixture_path(*components)
      File.join(__dir__, "data", *components)
    end
  end

  module Global
    def suppress_warning
      verbose = $VERBOSE
      begin
        $VERBOSE = nil
        yield
      ensure
        $VERBOSE = verbose
      end
    end

    def with_default_internal(encoding)
      default_internal = Encoding.default_internal
      begin
        suppress_warning {Encoding.default_internal = encoding}
        yield
      ensure
        suppress_warning {Encoding.default_internal = default_internal}
      end
    end
  end
end
