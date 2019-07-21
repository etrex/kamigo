Rails.application.routes.draw do
  # line webhook entry
  post 'line', to: 'line#entry'
end
