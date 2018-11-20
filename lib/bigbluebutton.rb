module BigBlueButton

  def self.remove_domain(url)
    if url.present?
      u = URI(url)
      url.gsub(/^#{u.scheme}:\/\/#{u.host}/, '')
    end
  end

end
