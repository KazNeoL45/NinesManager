class BoardsController < ApplicationController
  before_action :set_project
  before_action :set_board, only: [:show, :edit, :update, :destroy]

  def index
    @boards = @project.boards
  end

  def show
    @columns = @board.columns.includes(tasks: :assignees)
  end

  def new
    @board = @project.boards.build
  end

  def create
    @board = @project.boards.build(board_params)
    if @board.save
      redirect_to project_board_path(@project, @board), notice: 'Board created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @board.update(board_params)
      redirect_to project_board_path(@project, @board), notice: 'Board updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @board.destroy
    redirect_to project_path(@project), notice: 'Board deleted successfully.'
  end

  private

  def set_project
    @project = find_project
  end

  def set_board
    @board = @project.boards.find(params[:id])
  end

  def board_params
    params.require(:board).permit(:name)
  end
end
