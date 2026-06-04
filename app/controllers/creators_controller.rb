class CreatorsController < ApplicationController
  before_action :set_creator, only: [ :show, :edit, :update ]
  skip_before_action :check_creator_exist, only: [ :new, :create ]

  def show
  end

  def new
    return redirect_to creator_path if current_user.creator.present?
    @creator = current_user.build_creator
  end

  def create
    return redirect_to creator_path if current_user.creator.present?
    @creator = current_user.build_creator(creator_params)
    if @creator.save
      destination = current_user.onboarding_complete? ? creator_path : new_idea_path
      redirect_to destination, notice: "Profile created!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @creator.update(creator_params)
      redirect_to creator_path, notice: "Profile updated!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def edit
  end

  private

  def set_creator
    @creator = current_user.creator
    redirect_to new_creator_path if @creator.nil?
  end

  def creator_params
    params.require(:creator).permit(:name, :topic, :goal, :audience, :show)
  end
end
