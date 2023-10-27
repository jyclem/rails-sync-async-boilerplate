# frozen_string_literal: true

module Tasks
  # A Task must be small and isolated, and can pretty much replace any callback from a model
  # - it must not contain any call to the DB, this will be done in the action
  # - it must raise all the errors encountered
  # - it must not raise any HTTP exception, this will be handled by the action
  # IMPORTANT: we don't want to hide any error, when it fails, it must fail loudly so that it will be easy to
  # identify and to fix, that is why it is suggested to systematically raise errors
  class Base
    def self.call(...)
      new(...).call
    end
  end
end
