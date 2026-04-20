Rails.application.routes.draw do
  # line webhook entry
  post 'line', to: 'line#entry'
  post 'line/:account_name', to: 'line#entry'
end
