# frozen_string_literal: true

class Photo < Sequel::Model
  def self.create_from_exif(exif_photo)
    find_or_create(
      file_name: exif_photo[:file_name],
      model: exif_photo[:model],
      created_at: exif_photo.created_at
    )
  end

  def self.find_from_exif(exif_photo)
    first(
      file_name: exif_photo[:file_name],
      model: exif_photo[:model],
      created_at: exif_photo.created_at
    )
  end

  def imported?
    !imported_at.nil?
  end
end
