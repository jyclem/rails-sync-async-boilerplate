# frozen_string_literal: true

# This controller can be inherited and allows the endpoints to be accessible synchrounously or
# asynchronoulsy depending if the request Header "async: true" is present or not
class SyncAsyncController < ApplicationController
  before_action :remove_useless_params, :call

  # The following methods can be overriden to update the response
  # It is mandatory to add any non CRUD action in the associated controller, even if empty
  def index; end
  def show; end
  def create; end
  def update; end
  def destroy; end

  private

  def call # rubocop:disable Metrics/MethodLength
    send(action_name) # we call the action in case we want to override the classic behavior
    render json: result, status: response.status
  rescue HttpBadRequest, HttpInternalServerError, HttpUnauthorized, HttpNotImplemented, HttpNotFound,
         HttpUnprocessableEntity => e
    handle_error(e, e.class.to_s.gsub(/^Http(.*)/, '\1').underscore.to_sym)
  rescue ActiveRecord::RecordNotFound => e
    handle_error(e, :not_found)
  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    handle_error(e, :unprocessable_entity)
  rescue StandardError => e
    handle_error(e, :internal_server_error, important: true)
  end

  def remove_useless_params
    params.delete(controller_name.singularize)
  end

  def result
    raise HttpUnauthorized unless controller.authorized?(params, user)

    if async?
      handle_async
    else
      handle_sync
    end
  end

  def handle_async
    { job_id: ExecuteActionJob.perform_async(action.to_s, sanitized_params.to_hash) }
  end

  def handle_sync
    action_result = action.call(**sanitized_params.to_h.symbolize_keys)

    controller.serialize(action_result)
  end

  def handle_error(exception, status, important: false)
    Rails.logger.send(important ? :error : :info, "#{exception.inspect} #{exception.backtrace.first(10)}")
    # we remove the full path of the Rails application from the message returned to the client
    render json: { error: exception ? exception.message.gsub(Rails.root.to_s, '') : 'unknown' }, status:
  end

  def async?
    request.headers['async'] == 'true'
  end

  def controller
    @controller ||= "Controllers::#{controller_action_camelized}".constantize
  rescue NameError => e
    raise HttpNotImplemented, e
  end

  def action
    @action ||= "Actions::#{controller_action_camelized}".constantize
  rescue NameError => e
    raise HttpNotImplemented, e
  end

  def sanitized_params
    controller.sanitize(params, user)
  end

  def controller_action_camelized
    @controller_action_camelized ||= "#{controller_name.camelize}::#{action_name.camelize}"
  end

  def user
    @user ||= defined?(current_user) && current_user
  end
end

class HttpBadRequest < StandardError; end
class HttpInternalServerError < StandardError; end
class HttpUnauthorized < StandardError; end
class HttpNotImplemented < StandardError; end
class HttpNotFound < StandardError; end
class HttpUnprocessableEntity < StandardError; end
