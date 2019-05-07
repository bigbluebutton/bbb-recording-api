Rails.application.routes.draw do
  base = ENV.fetch('BBB_API_BASEPATH')
  get "#{base}/getRecordings",
    to: 'bigbluebutton_api#getRecordings',
    as: 'bigbluebutton_api_get_recordings',
    defaults: { format: 'xml' }
  get "#{base}/publishRecordings",
    to: 'bigbluebutton_api#publishRecordings',
    as: 'bigbluebutton_api_publish_recordings',
    defaults: { format: 'xml' }
  get "#{base}/updateRecordings",
    to: 'bigbluebutton_api#updateRecordings',
    as: 'bigbluebutton_api_update_recordings',
    defaults: { format: 'xml' }
  get "#{base}/deleteRecordings",
      to: 'bigbluebutton_api#deleteRecordings',
      as: 'bigbluebutton_api_delete_recordings',
      defaults: { format: 'xml' }
end
