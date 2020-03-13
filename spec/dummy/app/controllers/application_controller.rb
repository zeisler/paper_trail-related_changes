class ApplicationController < ActionController::Base
  def info_for_paper_trail
    { request_id: request.request_id }
  end

  def current_user
    User.first
  end
end
