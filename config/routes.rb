Rails.application.routes.draw do
  base = ENV.fetch('BBB_API_BASEPATH')

  get "#{base}/getRecordings",
      to: 'recordings#getRecordings',
      as: 'recordings_get_recordings',
      defaults: { format: 'xml' }
  get "#{base}/publishRecordings",
      to: 'recordings#publishRecordings',
      as: 'recordings_publish_recordings',
      defaults: { format: 'xml' }
  get "#{base}/updateRecordings",
      to: 'recordings#updateRecordings',
      as: 'recordings_update_recordings',
      defaults: { format: 'xml' }
  get "#{base}/deleteRecordings",
      to: 'recordings#deleteRecordings',
      as: 'recordings_delete_recordings',
      defaults: { format: 'xml' }

  get "#{base}/getData",
      to: 'data#getData',
      as: 'data_get_data',
      defaults: { format: 'json' }
end
