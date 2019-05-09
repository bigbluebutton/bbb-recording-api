class BigbluebuttonApiController < ApplicationController
  before_action :parse_metadata

  def getRecordings
    query = Recording.includes(playback_formats: [:thumbnails], metadata: [])
    if params[:recordID].present?
      query = query.with_recording_id_prefixes(params[:recordID].split(','))
    elsif params[:meetingID].present?
      query = query.where(meeting_id: params[:meetingID].split(','))
    end

    # processing|processed|published|unpublished|deleted
    if params[:state].present?
      states = params[:state].split(',')
    else
      states = %w[published unpublished]
    end
    query = query.where(state: states) unless states.include?('any')

    # filters by metadata
    # if there's more than one meta, returns only recordings with *all* of them
    unless @metadata.empty?
      ids = nil
      @metadata.each do |key, value|
        meta_query = Metadatum
        meta_query = meta_query.where(recording_id: ids) unless ids.nil?
        ids = meta_query.where(metadata: { key: key, value: value }).pluck(:recording_id)
      end
      query = query.where(id: ids)
    end

    @recordings = query.order(starttime: :desc).all
    @url_prefix = "#{request.protocol}#{request.host}"
    render :get_recordings
  end

  def publishRecordings
    raise ApiError.new('missingParamRecordID', 'You must specify a recordID.') if params[:recordID].blank?
    raise ApiError.new('missingParamPublish', 'You must specify a publish value true or false.') if params[:publish].blank?

    publish = params[:publish].casecmp('true').zero?

    query = Recording.where(record_id: params[:recordID].split(','), state: %w[ published unpublished ])
    raise ApiError.new('notFound', 'We could not find recordings') if query.none?

    query.where.not(published: publish).update(published: publish, state: (publish ? 'published' : 'unpublished'))

    @published = publish
    render :publish_recordings
  end

  def updateRecordings
    raise ApiError.new('missingParamRecordID', 'You must specify a recordID.') if params[:recordID].blank?

    record_ids = params[:recordID].split(',')

    add_metadata = {}
    remove_metadata = []
    @metadata.each do |key, value|
      if value.blank?
        remove_metadata << key
      else
        add_metadata[key] = value
      end
    end

    Metadatum.transaction do
      Metadatum.upsert_by_record_id(record_ids, add_metadata)
      Metadatum.delete_by_record_id(record_ids, remove_metadata)
    end

    @updated = !(add_metadata.empty? && remove_metadata.empty?)

    # the update above won't trigger the hooks in the models, so we post to redis manually
    Recording.metadata_updated(record_ids) if @updated

    render :update_recordings
  end

  def deleteRecordings
    raise ApiError.new('missingParamRecordID', 'You must specify a recordID.') if params[:recordID].blank?

    query = Recording.where(record_id: params[:recordID].split(','))
                     .where.not(state: 'deleted')
    raise ApiError.new('notFound', 'We could not find recordings') if query.none?

    destroyed_recs = query.update(state: 'deleted', deleted_at: Time.now)

    @deleted = destroyed_recs.count.positive?
    render :delete_recordings
  end

  private

  def parse_metadata
    @metadata = {}
    params.each do |key, value|
      next unless key.start_with?('meta_')

      key = key[5..-1]
      @metadata[key] = value
    end
  end
end
