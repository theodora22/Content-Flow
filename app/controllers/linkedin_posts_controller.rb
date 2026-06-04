class LinkedinPostsController < ApplicationController
  include UserScopedResource

  before_action :authenticate_user!
  before_action :set_script
  before_action :set_linkedin_post, only: [ :show, :edit, :update, :destroy ]

  def show
  end

  def new
    # If a post already exists for this script, go straight to edit
    if @script.linkedin_post.present?
      redirect_to edit_script_linkedin_post_path(@script) and return
    end
    # build_linkedin_post builds a new in-memory LinkedinPost associated with @script,
    # but does NOT save it — equivalent to: LinkedinPost.new(script: @script)
    @linkedin_post = @script.build_linkedin_post
  end

  def create
    @linkedin_post = @script.build_linkedin_post(linkedin_post_params)
    if @linkedin_post.save
      redirect_to script_linkedin_post_path(@script), notice: "LinkedIn post saved."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @linkedin_post.update(linkedin_post_params)
      redirect_to script_linkedin_post_path(@script), notice: "LinkedIn post updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @linkedin_post.destroy
    redirect_to script_path(@script), notice: "LinkedIn post deleted."
  end

  private

  def set_script
    @script = current_user_scripts.find(params[:script_id])
  end

  # singular resource — no :id in the path, so we load via the association.
  # Equivalent: LinkedinPost.find_by!(script_id: @script.id)
  def set_linkedin_post
    @linkedin_post = @script.linkedin_post
  end

  def linkedin_post_params
    params.require(:linkedin_post).permit(:title, :hook, :body)
  end
end
