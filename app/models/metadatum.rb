class Metadatum < ApplicationRecord
  belongs_to :recording

  after_save :publish_to_redis_after_save
  after_destroy :publish_to_redis_after_destroy

  def self.upsert_by_record_id(record_ids, metadata)
    record_ids = Array.try_convert(record_ids) || [record_ids]
    return if record_ids.empty? || metadata.empty?

    insert_records = []

    key_col = Metadatum.columns_hash['key']
    value_col = Metadatum.columns_hash['value']
    record_id_col = Recording.columns_hash['record_id']
    metadata.each do |key, value|
      insert_records << [key_col, key]
      insert_records << [value_col, value]
    end
    record_ids.each do |record_id|
      insert_records << [record_id_col, record_id]
    end
    insert_metadatum(metadata, record_ids, insert_records)
  end

  def self.insert_metadatum(metadata, record_ids, insert_records)
    Metadatum.connection.insert(
      'INSERT INTO "metadata" ("recording_id", "key", "value") '\
        'WITH "new_metadata" AS '\
            "(VALUES #{Array.new(metadata.length, '(?, ?)').join(', ')}) "\
          'SELECT "recordings"."id", "new_metadata".* FROM "recordings" JOIN "new_metadata" '\
          'WHERE "recordings"."record_id" '\
            "IN (#{Array.new(record_ids.length, '?').join(', ')}) "\
          'ON CONFLICT ("recording_id", "key") DO UPDATE SET "value" = EXCLUDED."value"',
      'Metadatum Upsert',
      nil,
      nil,
      nil,
      insert_records
    )
  end

  def self.delete_by_record_id(record_ids, metadata_keys)
    return if record_ids.empty? || metadata_keys.empty?

    Metadatum.joins(:recording).where(recordings: { record_id: record_ids }, key: metadata_keys).delete_all
  end

  private

  def publish_to_redis_after_save
    recording.publish_metadata_to_redis unless saved_changes.empty?
  end

  def publish_to_redis_after_destroy
    recording.publish_metadata_to_redis
  end
end
