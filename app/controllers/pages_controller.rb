class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  def home
    redirect_to dashboard_path if user_signed_in?
  end

  def about
    @version = NinesManager::Application.version
    @status_display = NinesManager::Application.status_display
    @status = SystemStatus.new
  end
end
