class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  def home
    # `pages#home` is the PUBLIC marketing landing (auth is skipped above).
    # But a signed-in creator shouldn't sit on the marketing page — send them
    # straight to their authed home. `user_signed_in?` is a Devise helper.
    redirect_to dashboard_path if user_signed_in?
  end
end
