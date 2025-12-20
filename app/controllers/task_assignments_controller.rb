class TaskAssignmentsController < ApplicationController
  before_action :set_project
  before_action :set_task

  def create
    authorize @task
    if @task.assignees.size >= 2
      redirect_to project_task_path(@project, @task), alert: 'Task can only have 2 assignees.', status: :see_other
      return
    end
    if @task.assignees.pluck(:id).include?(params[:user_id].to_i)
      redirect_to project_task_path(@project, @task), alert: 'User is already assigned to this task.', status: :see_other
      return
    end
    @assignment = @task.task_assignments.build(user_id: params[:user_id])
    if @assignment.save
      redirect_to project_task_path(@project, @task), notice: 'Assignee added successfully.', status: :see_other
    else
      error_message = @assignment.errors.full_messages.join(', ')
      redirect_to project_task_path(@project, @task), alert: "Failed to add assignee: #{error_message}", status: :see_other
    end
  end

  def update
    @assignment = @task.task_assignments.find(params[:id])
    authorize @task
    if @task.assignees.pluck(:id).include?(params[:user_id].to_i) && @assignment.user_id != params[:user_id].to_i
      redirect_to project_task_path(@project, @task), alert: 'User is already assigned to this task.', status: :see_other
      return
    end
    if @assignment.update(user_id: params[:user_id])
      redirect_to project_task_path(@project, @task), notice: 'Assignee updated successfully.', status: :see_other
    else
      error_message = @assignment.errors.full_messages.join(', ')
      redirect_to project_task_path(@project, @task), alert: "Failed to update assignee: #{error_message}", status: :see_other
    end
  end

  def destroy
    @assignment = @task.task_assignments.find(params[:id])
    authorize @task
    @assignment.destroy
    redirect_to project_task_path(@project, @task), notice: 'Assignee removed successfully.', status: :see_other
  end

  private

  def set_project
    @project = find_project
  end

  def set_task
    @task = @project.tasks.includes(:assignees).find(params[:task_id])
  end
end

