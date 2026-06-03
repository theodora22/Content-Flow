class IdeasController < ApplicationController
  def index
    @ideas = current_user.ideas.order(created_at: :desc)
  end
end
