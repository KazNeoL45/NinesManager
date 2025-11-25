class ProjectsController < ApplicationController
  before_action :set_project, only: [:show, :edit, :update, :destroy]

  def index
    @projects = current_user.owned_projects
  end

  def show
    @tasks = @project.tasks.includes(:user, :column)
    @boards = @project.boards.includes(:columns)
    @documents = @project.documents
  end

  def new
    @project = Project.new
  end

  def create
    @project = current_user.owned_projects.build(project_params)
    if @project.save
      redirect_to @project, notice: 'Project created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @project.update(project_params)
      redirect_to @project, notice: 'Project updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    redirect_to projects_url, notice: 'Project deleted successfully.'
  end

  private

  def set_project
    @project = current_user.owned_projects.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :description)
  end
end
