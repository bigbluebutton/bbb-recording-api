xml.response do
  xml.returncode 'SUCCESS'
  xml.deleted @deleted.to_s
end
