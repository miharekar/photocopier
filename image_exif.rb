# frozen_string_literal: true

class ImageExif
  extend Forwardable

  attr_reader :exif

  def initialize(exif)
    @exif = exif.to_hash
  end

  def created_at
    exif[:date_time_original_civil] || exif[:create_date_civil]
  end

  def file_name
    exif[:original_file_name] || exif[:file_name]
  end

  def_delegator :exif, :[]
end
