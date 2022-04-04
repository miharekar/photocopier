# frozen_string_literal: true

class ImageExif
  extend Forwardable

  attr_reader :exif

  def initialize(exif)
    @exif = exif.to_hash
  end

  def created_at
    return if created_at_string.nil?

    DateTime.new(*created_at_string.split(/[\s.:]/).map(&:to_i))
  end

  def file_name
    exif[:original_file_name] || exif[:file_name]
  end

  def_delegator :exif, :[]

  private

  def created_at_string
    exif[:date_time_original] || exif[:create_date]
  end
end
