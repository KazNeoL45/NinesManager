class DashboardController < ApplicationController
  def index
    @projects = current_user.owned_projects.includes(:tasks, :boards)
    @recent_tasks = current_user.tasks.order(created_at: :desc).limit(10)
  end

  def show
    redirect_to action: :index
  end
end
