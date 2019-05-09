class DataController < ApplicationController
  before_action :parse_metadata

  def getData
    raise ApiError.new('missingParamRecordID', 'You must specify a recordID.') if params[:recordID].blank?

    recording = Recording.find_by(record_id: params[:recordID].split(',')[0])
    if recording.present?
      filename = recording.data_file_path
      if File.exist?(filename)
        data = File.read(filename)

        # for some reason `render :json` doesn't work
        return render plain: data, status: :ok, content_type: 'application/json'
      else
        Rails.logger.warn("Could not find the file #{filename}")
      end
    end

    # no data found
    render plain: {}.to_json, status: :ok, content_type: 'application/json'
  end
end
