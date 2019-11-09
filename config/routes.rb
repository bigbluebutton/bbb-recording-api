Rails.application.routes.draw do
  base = ENV.fetch('BBB_API_BASEPATH')

  # Remove base first slash and replace following slashes with underscore.
  path_prefix = base.gsub(%r{^/}, '').gsub(%r{/}, '_')

  scope as: path_prefix, path: base do
    get 'getRecordings',
        to: 'recordings#get_recordings',
        as: 'get_recordings',
        defaults: { format: 'xml' }
    get 'publishRecordings',
        to: 'recordings#publish_recordings',
        as: 'publish_recordings',
        defaults: { format: 'xml' }
    get 'updateRecordings',
        to: 'recordings#update_recordings',
        as: 'update_recordings',
        defaults: { format: 'xml' }
    get 'deleteRecordings',
        to: 'recordings#delete_recordings',
        as: 'delete_recordings',
        defaults: { format: 'xml' }
    get 'get_data',
        to: 'data#getData',
        as: 'get_data',
        defaults: { format: 'json' }
  end
end
