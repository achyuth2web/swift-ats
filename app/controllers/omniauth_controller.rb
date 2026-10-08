class OmniauthController < ApplicationController
  def failure
    redirect_to root_path,
                alert: "Google authentication failed."
  end
end