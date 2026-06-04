module UserScopedResource
  extend ActiveSupport::Concern

  private

  def current_user_scripts
    Script.joins(:idea).where(ideas: { user_id: current_user.id })
  end
end
