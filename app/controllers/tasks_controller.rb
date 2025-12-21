class TasksController < ApplicationController
  before_action :set_project
  before_action :set_task, only: [:show, :edit, :update, :destroy, :move]

  def index
    @tasks = @project.tasks.includes(:user, :column, :assignees)
  end

  def show
    authorize @task
    assigned_user_ids = @task.assignees.pluck(:id)
    if assigned_user_ids.any?
      @available_assignees = @project.assignable_users.where.not(id: assigned_user_ids)
    else
      @available_assignees = @project.assignable_users
    end
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def new
    @task = @project.tasks.build
    authorize @task
  end

  def create
    @task = @project.tasks.build(task_params)
    authorize @task
    if @task.save
      redirect_to project_path(@project), notice: 'Task created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @task
    respond_to do |format|
      format.html
      format.turbo_stream 
    end
  end

  def update
    authorize @task
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
    authorize @task
    @task.destroy
    redirect_to project_path(@project), notice: 'Task deleted successfully.'
  end

  def move
    authorize @task, :move?
    update_params = { column_id: params[:column_id] }
    update_params[:position] = params[:position] if params[:position].present?
    
    if @task.update(update_params)
      head :ok
    else
      head :unprocessable_entity
    end
  end

  private

  def set_project
    @project = find_project
  end

  def set_task
    @task = @project.tasks.includes(:assignees, :column).find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :description, :status, :priority, :due_date, :column_id, :recurring, :recurrence_pattern)
  end
end