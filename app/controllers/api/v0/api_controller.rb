class Api::V0::ApiController < ApplicationController
  include PagingConcern
  before_action :require_authentication!, only: [:create]

  rescue_from StandardError, with: :render_errors if Rails.env.production?
  rescue_from Api::NotImplementedError, with: :render_errors
  rescue_from Api::InputError, with: :render_errors

  rescue_from ActiveModel::ValidationError do |error|
    render_errors(error.model.errors.full_messages, 400)
  end

  rescue_from ActiveModel::ValidationError do |error|
    render_errors(error, 404)
  end


  protected

  def paging_url_format
    ''
  end

  # This is different from Devise's authenticate_user! -- it does not redirect.
  def require_authentication!
    unless user_signed_in?
      render_errors('You must be logged in to perform this action.', 401)
    end
  end

  # Render an error or errors as a proper API response
  def render_errors(errors, status_code = nil)
    errors = [errors] unless errors.is_a?(Array)
    status_code ||= errors.first.try(:status_code) || 500

    render status: status_code, json: {
      errors: errors.collect do |error|
        {
          status: status_code,
          title: message_for(error)
        }
      end
    }
  end

  def message_for(error)
    error.try(:message) ||
      (error.try(:has_key?, :message) && error.send(:[], :message)) ||
      error.to_s
  end

  def filter_param(collection, name, attribute = nil)
    attribute = name if attribute.nil?
    params[name] ? collection.where(attribute => params[name]) : collection
  end

  def parse_date!(date)
    raise 'Nope' unless date.match?(/^\d{4}-\d\d-\d\d(T\d\d\:\d\d(\:\d\d(\.\d+)?)?(Z|([+\-]\d{4})))?$/)
    DateTime.parse date
  rescue
    raise Api::InputError, "Invalid date: '#{date}'"
  end
end
