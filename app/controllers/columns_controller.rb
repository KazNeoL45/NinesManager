class ColumnsController < ApplicationController
  before_action :set_project
  before_action :set_board

  def create
    @column = @board.columns.build(column_params)
    @column.position = @board.columns.maximum(:position).to_i + 1
    if @column.save
      redirect_to project_board_path(@project, @board), notice: 'Column created successfully.'
    else
      redirect_to project_board_path(@project, @board), alert: 'Failed to create column.'
    end
  end

  def update
    @column = @board.columns.find(params[:id])
    if @column.update(column_params)
      redirect_to project_board_path(@project, @board), notice: 'Column updated successfully.'
    else
      redirect_to project_board_path(@project, @board), alert: 'Failed to update column.'
    end
  end

  def destroy
    @column = @board.columns.find(params[:id])
    @column.destroy
    redirect_to project_board_path(@project, @board), notice: 'Column deleted successfully.'
  end

  private

  def set_project
    @project = current_user.owned_projects.find(params[:project_id])
  end

  def set_board
    @board = @project.boards.find(params[:board_id])
  end

  def column_params
    params.require(:column).permit(:name, :position)
  end
end
