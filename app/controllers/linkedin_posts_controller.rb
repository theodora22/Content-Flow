class LinkedinPostsController < ApplicationController
  include UserScopedResource

  before_action :set_script

  def show
    @linkedin_post = @script.linkedin_post
  end

  private

  def set_script
    @script = current_user_scripts.find(params[:script_id])
  end
end
