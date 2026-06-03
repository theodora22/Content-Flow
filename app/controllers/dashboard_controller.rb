class DashboardController < ApplicationController
  # No `skip_before_action :authenticate_user!` here, so the inherited
  # `before_action :authenticate_user!` from ApplicationController applies:
  # unauthenticated visitors are bounced to the Devise sign-in page. This is
  # the logged-in counterpart to the public `pages#home` landing.

  def show
    # Implicit template lookup (Rails "magic"):
    # This action has no explicit `render` call. When an action finishes
    # without rendering, Rails renders the template whose path matches the
    # controller and action names by convention:
    #
    #   controller "dashboard" + action "show"
    #     -> app/views/dashboard/show.html.erb
    #
    # So this is exactly equivalent to writing:
    #
    #   render "dashboard/show"   # or simply: render :show
    #
    # Rails also picks the format/handler from the request + filename
    # (.html.erb for an HTML request). Placeholder for now — no data yet.
  end
end
