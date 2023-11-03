# frozen_string_literal: true

module Tasks
  # A Task must be small and isolated, and can pretty much replace any callback that could be put in a model
  # - it must not contain any call to the DB, this will be done in the action
  # - it must raise all the errors encountered
  # - it must not raise any HTTP exception, this will be handled by the action
  class Base
    def self.call(...)
      new(...).call
    end
  end
end
