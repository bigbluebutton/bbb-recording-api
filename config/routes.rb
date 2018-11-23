Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get 'bigbluebutton/api/getRecordings',
    to: 'bigbluebutton_api#getRecordings',
    as: 'bigbluebutton_api_get_recordings',
    defaults: { format: 'xml' }
  get 'bigbluebutton/api/publishRecordings',
    to: 'bigbluebutton_api#publishRecordings',
    as: 'bigbluebutton_api_publish_recordings',
    defaults: { format: 'xml' }
  get 'bigbluebutton/api/updateRecordings',
    to: 'bigbluebutton_api#updateRecordings',
    as: 'bigbluebutton_api_update_recordings',
    defaults: { format: 'xml' }
end
