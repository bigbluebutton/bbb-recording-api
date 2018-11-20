Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get 'bigbluebutton/api/getRecordings', to: 'bigbluebutton_api#get_recordings', defaults: { format: 'xml' }
end
