class CreatorsController < ApplicationController
  skip_before_action :check_creator_exist, only: [ :show, :create ]

  def show
    @creator = current_user.creator || current_user.build_creator
  end

  def create
    return redirect_to creator_path if current_user.creator.present?
    @creator = current_user.build_creator(creator_params)
    if @creator.save
      destination = current_user.onboarding_complete? ? creator_path : new_idea_path
      redirect_to destination, notice: "Profile created!"
    else
      render :show, status: :unprocessable_entity
    end
  end

  def update
    @creator = current_user.creator
    if @creator.update(creator_params)
      redirect_to creator_path, notice: "Profile updated!"
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def creator_params
    params.require(:creator).permit(:name, :topic, :goal, :audience, :show, :avatar).tap do |permitted|
      # An untouched file field submits a blank value; without this an update
      # that doesn't pick a new photo would clobber the existing attachment.
      permitted.delete(:avatar) if permitted[:avatar].blank?
    end
  end
end
