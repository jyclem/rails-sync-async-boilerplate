# frozen_string_literal: true

module Actions
  # An Action is what is directly called from a controller, it is more or less a list of all the tasks
  # we want to process within the client query
  # - it must return the object that will be serialized by the associated controller
  # - it must contain all the calls to the DB so that we can regroup and easily optimize the DB queries if necessary
  # - it must contain as many "callbacks" as possible, to lighten the models
  # - it can raise exception (such as HttpBadRequest, HttpNotFound, ActiveRecord::RecordInvalid, ... see
  # app/controllers/sync_async_controller.rb for more details) to include the error in the response given to the client
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
