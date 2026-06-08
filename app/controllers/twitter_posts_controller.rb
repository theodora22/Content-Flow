class TwitterPostsController < ApplicationController
  include UserScopedResource

  before_action :authenticate_user!
  before_action :set_script
  before_action :set_twitter_post, only: [ :show, :edit, :update, :destroy ]

  def show
  end

  def new
    redirect_to new_chat_path(purpose: "generate_twitter_post",
                              chattable_type: "Script", chattable_id: @script.id)
  end

  def create
    @twitter_post = @script.build_twitter_post(twitter_post_params)
    if @twitter_post.save
      redirect_to script_twitter_post_path(@script), notice: "Twitter post saved."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @twitter_post.update(twitter_post_params)
      redirect_to script_twitter_post_path(@script), notice: "Twitter post updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @twitter_post.destroy
    redirect_to script_path(@script), notice: "Twitter post deleted."
  end

  private

  def set_script
    @script = current_user_scripts.find(params[:script_id])
  end

  def set_twitter_post
    @twitter_post = @script.twitter_post
  end

  def twitter_post_params
    params.require(:twitter_post).permit(:title, :hook, :body)
  end
end
