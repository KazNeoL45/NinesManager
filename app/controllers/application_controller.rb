class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :authenticate_user!
  before_action :update_user_status
  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :role])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :role])
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end

  def find_project
    Project.includes(:members).find(params[:project_id]).tap do |project|
      authorize project, :show?
    end
  end

  def update_user_status
    if user_signed_in? && (current_user.last_seen_at.nil? || current_user.last_seen_at < 1.minute.ago)
      current_user.update_column(:last_seen_at, Time.current)
    end
  end
end
