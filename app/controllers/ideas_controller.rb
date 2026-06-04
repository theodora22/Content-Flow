class IdeasController < ApplicationController
  before_action :set_idea, only: [:show]

  def index
    @ideas = current_user.ideas.order(created_at: :desc)
  end

  private

  def set_idea
    @idea = current_user.ideas.find(params[:id])
  end
end
