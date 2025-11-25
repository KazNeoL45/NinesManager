class ProjectMembersController < ApplicationController
  before_action :set_project

  def create
    @member = @project.project_members.build(project_member_params)
    if @member.save
      redirect_to @project, notice: 'Member added successfully.'
    else
      redirect_to @project, alert: 'Failed to add member.'
    end
  end

  def destroy
    @member = @project.project_members.find(params[:id])
    @member.destroy
    redirect_to @project, notice: 'Member removed successfully.'
  end

  private

  def set_project
    @project = current_user.owned_projects.find(params[:project_id])
  end

  def project_member_params
    params.require(:project_member).permit(:user_id, :role)
  end
end
