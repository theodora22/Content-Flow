class InstagramPostsController < ApplicationController
  include UserScopedResource

  before_action :authenticate_user!
  before_action :set_script
  before_action :set_instagram_post, only: [ :show, :edit, :update, :destroy ]

  def show
  end

  def new
    redirect_to new_chat_path(purpose: "generate_instagram_post",
                              chattable_type: "Script", chattable_id: @script.id)
  end

  def create
    @instagram_post = @script.build_instagram_post(instagram_post_params)
    if @instagram_post.save
      redirect_to script_instagram_post_path(@script), notice: "Instagram post saved."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @instagram_post.update(instagram_post_params)
      redirect_to script_instagram_post_path(@script), notice: "Instagram post updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @instagram_post.destroy
    redirect_to script_path(@script), notice: "Instagram post deleted."
  end

  private

  def set_script
    @script = current_user_scripts.find(params[:script_id])
  end

  def set_instagram_post
    @instagram_post = @script.instagram_post
  end

  def instagram_post_params
    params.require(:instagram_post).permit(:title, :hook, :body)
  end
end
