json.array! @data do |data|
  json.record_id data.record_id
  json.recorded data.recording.present?
  json.raw_data data.raw_data
end
