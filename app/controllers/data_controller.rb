class DataController < ApplicationController
  before_action :parse_metadata

  def getData
    query = if params.key?(:recordID)
              Datum.where(record_id: params[:recordID].split(','))
            else
              Datum
            end
    @data = query.all
  end
end
