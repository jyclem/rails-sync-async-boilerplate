# frozen_string_literal: true

module Actions
  # An Action is what is directly called from a controller, it is a more or less a list of all the tasks
  # we want to process within the client query
  # - it must return the object that will be serialized by the associated controller
  # - it must contain all the calls to the DB so that we can easily optimize the DB queries if necessary
  # - it can raise HTTP exception to give some details of the error to the client
  # - it must contain as many "callbacks" as possible, to lighten the models
  # IMPORTANT: for maintenance reasons, do not use callbacks in models or do it only if the
  # callback touches nothing else than the current model
  class Base
    # initialize here is only used for testing purposes
    def initialize(...); end

    def self.call(...)
      # if an error is raised, we want to make sure to rollback all modifications of the action in DB
      ActiveRecord::Base.transaction do
        new(...).call
      end
    end
  end
end
