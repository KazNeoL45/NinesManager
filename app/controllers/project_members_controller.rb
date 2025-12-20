class ProjectMembersController < ApplicationController
  before_action :set_project
  before_action :set_project_member, only: [:destroy]

  def create
    @member = @project.project_members.build(project_member_params)
    authorize @member
    if @member.save
      redirect_to @project, notice: 'Member added successfully.'
    else
      redirect_to @project, alert: 'Failed to add member.'
    end
  end

  def destroy
    authorize @member
    @member.destroy
    redirect_to @project, notice: 'Member removed successfully.'
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
    authorize @project, :show?
  end

  def set_project_member
    @member = @project.project_members.find(params[:id])
  end

  def project_member_params
    params.require(:project_member).permit(:user_id, :role)
  end
end
