class TasksController < ApplicationController
  before_action :set_project
  before_action :set_task, only: [:show, :edit, :update, :destroy, :move]

  def index
    @tasks = @project.tasks.includes(:user, :column)
  end

  def show
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def new
    @task = @project.tasks.build
  end

  def create
    @task = @project.tasks.build(task_params)
    @task.user = current_user
    if @task.save
      redirect_to project_path(@project), notice: 'Task created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

def edit
    respond_to do |format|
    format.html
    format.turbo_stream 
  end
end

  def update
    if @task.update(task_params)
      redirect_to project_board_path(@project, @task.column.board), notice: 'Task updated successfully.'
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("editTaskModal", partial: "form", locals: { project: @project, task: @task }) }
      end
    end
  end

  def destroy
    @task.destroy
    redirect_to project_path(@project), notice: 'Task deleted successfully.'
  end

  def move
    if @task.update(column_id: params[:column_id], position: params[:position])
      head :ok
    else
      head :unprocessable_entity
    end
  end

  private

  def set_project
    @project = current_user.owned_projects.find(params[:project_id])
  end

  def set_task
    @task = @project.tasks.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :description, :status, :priority, :due_date, :column_id, :user_id, :recurring, :recurrence_pattern)
  end
end