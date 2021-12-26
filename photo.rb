# frozen_string_literal: true

class Photo < Sequel::Model
  def self.from_exif(image_exif)
    find_or_create(
      file_name: image_exif.file_name,
      model: image_exif[:model],
      created_at: image_exif.created_at
    )
  end

  def self.find_from_exif(image_exif)
    first(
      file_name: image_exif.file_name,
      model: image_exif[:model],
      created_at: image_exif.created_at
    )
  end

  def imported?
    !imported_at.nil?
  end
end
