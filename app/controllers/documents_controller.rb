class DocumentsController < ApplicationController
  before_action :set_project
  before_action :set_document, only: [:show, :edit, :update, :destroy]

  def index
    @documents = @project.documents
  end

  def show
  end

  def new
    @document = @project.documents.build
  end

  def create
    @document = @project.documents.build(document_params)
    @document.user = current_user
    if @document.save
      redirect_to project_document_path(@project, @document), notice: 'Document created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @document.update(document_params)
      redirect_to project_document_path(@project, @document), notice: 'Document updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @document.destroy
    redirect_to project_documents_path(@project), notice: 'Document deleted successfully.'
  end

  private

  def set_project
    @project = find_project
  end

  def set_document
    @document = @project.documents.find(params[:id])
  end

  def document_params
    params.require(:document).permit(:title, :content)
  end
end
