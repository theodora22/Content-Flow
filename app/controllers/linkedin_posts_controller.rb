class LinkedinPostsController < ApplicationController
  include UserScopedResource

  before_action :set_script

  def show
    render plain: "authorized — post belongs to script #{@script.id} which is yours"
  end

  private

  def set_script
    @script = current_user_scripts.find(params[:script_id])
  end
end
