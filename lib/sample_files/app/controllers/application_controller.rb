class ApplicationController < Caboose::ApplicationController
  protect_from_forgery
  layout "layouts/caboose/application"
end
