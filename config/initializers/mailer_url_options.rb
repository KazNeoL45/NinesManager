if Rails.env.development?
  Rails.application.config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
  Rails.application.routes.default_url_options[:host] = 'localhost'
  Rails.application.routes.default_url_options[:port] = 3000
end