# frozen_string_literal: true

# This class should be empty most of the time, because everything is managed in SyncAsyncController,
# but if you want to override some classic mecanism (such as response status), you can do it here
class TodosController < SyncAsyncController
  # Add here any non CRUD method (ie not "index", "show", "create", "update", "destroy")
  # Add them as an empty method, for example:
  # def non_crud_method; end

  def create
    response.status = :created
  end
end
