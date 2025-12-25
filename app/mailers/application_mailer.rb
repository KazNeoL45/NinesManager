class ApplicationMailer < ActionMailer::Base
  default from: "kazne045@gmail.com"
  layout "mailer"
  
  include Rails.application.routes.url_helpers
end
