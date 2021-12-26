# frozen_string_literal: true

require "bundler"
Bundler.require

DB = Sequel.connect(adapter: :postgres, database: "photocopier", host: "localhost")

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

class ExifPhoto
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

volumes = Dir.entries("/Volumes").reject { |f| f.start_with?(".") }
puts "Where are the photos?"
puts volumes.map.with_index(1) { |v, i| "#{i}: #{v}" }
disk = volumes[gets.chomp.strip.to_i - 1]
path = "/Volumes/#{disk}/DCIM"
folders = Dir.entries(path).reject { |f| f.start_with?(".") }

photos = []
folders.each do |folder|
  folder_path = "#{path}/#{folder}"
  entries = Dir.entries(folder_path).reject { |f| f.start_with?(".") }
  photos += entries.map { |entry| "#{folder_path}/#{entry}" }
end
exif = Exiftool.new(photos)
locations = photos.filter_map do |photo|
  exif_photo = ExifPhoto.new(exif.result_for(photo))
  foto = Photo.find_from_exif(exif_photo)
  next if foto&.imported?

  date = exif_photo.created_at.strftime("%Y-%m-%d")
  model = exif_photo[:model]
  "#{date}|#{model}"
end.uniq

desktop = "#{ENV['HOME']}/Desktop"
destinations = {}
locations.each do |location|
  day, model = location.split("|")
  puts "What do you want to call the folder for #{day} from #{model}? Type 's' to skip."
  folder_name = gets.chomp.strip
  if folder_name == "s"
    destinations[location] = nil
  else
    folder_name = "#{day}-#{folder_name}-#{model}".downcase.gsub(/\s/, "-")
    destinations[location] = "#{desktop}/#{folder_name}"
    FileUtils.mkdir_p(destinations[location])
  end
end

progressbar = ProgressBar.create(
  format: "Copying photos: %a %b\u{15E7}%i %p%% %e",
  progress_mark: " ",
  remainder_mark: "\u{FF65}",
  total: photos.count
)

photos.each do |photo|
  exif_photo = ExifPhoto.new(exif.result_for(photo))
  foto = Photo.create_from_exif(exif_photo)
  unless foto.imported?
    date = exif_photo.created_at.strftime("%Y-%m-%d")
    model = exif_photo[:model]
    location = "#{date}|#{model}"
    if destinations[location]
      destination = "#{destinations[location]}/#{exif_photo.file_name}"
      FileUtils.cp(photo, destination)
      foto.update(imported_at: Time.now)
    end
  end
  progressbar.increment
end
