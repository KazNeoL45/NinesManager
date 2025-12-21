class DashboardController < ApplicationController
  def index
    @projects = (current_user.owned_projects.includes(:tasks, :boards) + current_user.projects.includes(:tasks, :boards)).uniq
    @assigned_tasks = Task.joins(:task_assignments).where(task_assignments: { user_id: current_user.id }).includes(:project, :assignees)
    @completed_tasks = @assigned_tasks.where(status: 'done')
    @recent_tasks = @assigned_tasks.order(created_at: :desc).limit(10)
  end

  def show
    redirect_to action: :index
  end
end
