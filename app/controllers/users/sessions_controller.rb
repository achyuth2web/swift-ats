class Users::SessionsController < Devise::SessionsController
  layout "devise"
  protect_from_forgery with: :exception, prepend: true
end
