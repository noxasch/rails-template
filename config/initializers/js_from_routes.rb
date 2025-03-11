if Rails.env.development? || Rails.env.test?
  JsFromRoutes.config do |config|
    config.file_suffix = "Api.ts"
    config.client_library = "@js-from-routes/axios"
  end
end
