# frozen_string_literal: true

require "active_support/concern"

module Auth
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!

    rescue_from ::Errors::AuthorizationError, with: :unauthorized_user
    rescue_from ::Errors::BlockedUserError, with: :blocked_user
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
  end

  private

  def authenticate_user!
    raise ::Errors::AuthorizationError, I18n.t("errors.unauthorized") unless user_signed_in?
    raise ::Errors::BlockedUserError, I18n.t("errors.blocked") if current_user.blocked_at.present?

    super
  end

  def unauthorized_user(error)
    render inertia: "Error", props: {
      code: "401", title: "Unauthorized", message: error.message
    }, status: :unauthorized
  end

  def blocked_user(error)
    render inertia: "Error", props: {
      code: "403", title: "Forbidden", message: error.message
    }, status: :forbidden
  end

  def not_found(error)
    render inertia: "Error", props: {
      code: "404", title: "Resources Not Found", message: error.message
    }, status: :not_found
  end
end
