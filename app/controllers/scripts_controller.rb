class ScriptsController < ApplicationController
  include UserScopedResource

  before_action :set_idea, only: [:new]
  before_action :set_script, only: [:show]

  private

  def set_idea
    @idea = current_user.ideas.find(params[:idea_id])
  end

  def set_script
    @script = current_user_scripts.find(params[:id])
  end
end

