# frozen_string_literal: true

module Controllers
  # These type of Controllers manage only the 3 following mechanisms:
  # - authorized?: like policies, checks if the user is authorized to call this action or not (false by default)
  # - sanitize: allows only the permitted parameters to be passed to the associated action
  # - serialize: formats the data that will be returned to the client
  # When a current_user is defined on the controller or channel level, we can use it in authorized? and sanitize
  # However, for simplicity when using asynchronousity, we cannot use it for serialize. If needed we can
  # pass it to the action through sanitize (params.permit(...).merge(current_user_id: current_user.id)) and
  # return it with the result of the action (result.merge(current_user:), or OpenStruct.new(result:, current_user:))
  class Base
    attr_reader :params, :result, :current_user

    def initialize(params: nil, result: nil, current_user: nil)
      @params = params
      @result = result
      @current_user = current_user
    end

    def self.authorized?(params, current_user = nil)
      new(params:, current_user:).authorized?
    end

    def self.sanitize(params, current_user = nil)
      new(params:, current_user:).sanitize
    end

    def self.serialize(result)
      new(result:).serialize
    end

    def authorized?
      false
    end

    def sanitize
      {}
    end

    def serialize
      nil
    end
  end
end
