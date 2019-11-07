Rails.application.routes.draw do
  base = ENV.fetch('BBB_API_BASEPATH')

  # Remove base first slash and replace following slashes with underscore.
  path_prefix = base.gsub(/^\//, '').gsub(/\//, '_')

  scope as: path_prefix, path: base do
    get "getRecordings",
        to: 'recordings#getRecordings',
        as: 'get_recordings',
        defaults: { format: 'xml' }
    get "publishRecordings",
        to: 'recordings#publishRecordings',
        as: 'publish_recordings',
        defaults: { format: 'xml' }
    get "updateRecordings",
        to: 'recordings#updateRecordings',
        as: 'update_recordings',
        defaults: { format: 'xml' }
    get "deleteRecordings",
        to: 'recordings#deleteRecordings',
        as: 'delete_recordings',
        defaults: { format: 'xml' }
    get "getData",
        to: 'data#getData',
        as: 'get_data',
        defaults: { format: 'json' }
  end
end
