# frozen_string_literal: true

require_relative "photo"
require_relative "image_exif"
require "debug"

class Copier
  IGNORED_EXTENSIONS = %w[.DS_Store .lrv .thm].freeze

  attr_reader :images, :exif_data, :events, :destinations

  def initialize
    find_images
    detect_events
  end

  def run
    create_destinations
    copy_images
    unmount_volume
  end

  private

  def find_images
    @images = []
    @images = Dir["/Volumes/#{selected_volume}/DCIM/**/*"].reject do |f|
      extension = File.extname(f).downcase
      extension.empty? || IGNORED_EXTENSIONS.include?(extension)
    end
    puts "Parsing EXIF data..."
    @exif_data = Exiftool.new(images)
  end

  def selected_volume
    @selected_volume ||= select_volume
  end

  def select_volume
    volumes = Dir.entries("/Volumes").reject { |f| f.start_with?(".") }
    puts "Where are the images?"
    puts volumes.map.with_index(1) { |v, i| "#{i}: #{v}" }
    volumes[gets.chomp.strip.to_i - 1]
  end

  def detect_events
    @events = images.filter_map do |image|
      image_exif = ImageExif.new(exif_data.result_for(image))
      photo = Photo.find_from_exif(image_exif)
      next if photo&.imported? || image_exif.created_at.nil?

      date = image_exif.created_at.strftime("%Y-%m-%d")
      model = image_exif[:model]
      "#{date}|#{model}"
    end.uniq
  end

  def create_destinations
    desktop = "#{Dir.home}/Desktop"
    @destinations = {}
    events.each do |event|
      day, model = event.split("|")
      puts "What do you want to call the folder for #{day} from #{model}? Type 's' to skip."
      folder_name = gets.chomp.strip
      if folder_name == "s"
        @destinations[event] = nil
      else
        folder_name = "#{day}-#{folder_name}-#{model}".downcase.gsub(/\s/, "-")
        @destinations[event] = "#{desktop}/#{folder_name}"
        FileUtils.mkdir_p(@destinations[event])
      end
    end
  end

  def copy_images
    progressbar = create_progressbar
    images.each do |image|
      progressbar.increment

      image_exif = ImageExif.new(exif_data.result_for(image))
      next if image_exif.created_at.nil?

      photo = Photo.from_exif(image_exif)
      next if photo.imported?

      date = image_exif.created_at.strftime("%Y-%m-%d")
      model = image_exif[:model]
      event = "#{date}|#{model}"
      if destinations[event]
        destination = "#{destinations[event]}/#{image_exif.file_name}"
        FileUtils.cp(image, destination)
      end
      photo.update(imported_at: Time.now)
    end
  end

  def unmount_volume
    list = Plist.parse_xml(`diskutil list -plist`)

    disk = list["AllDisksAndPartitions"].find do |d|
      d["MountPoint"] == "/Volumes/#{selected_volume}"
    end

    if disk.nil?
      disk = list["AllDisksAndPartitions"].find do |d|
        d["Partitions"].find { |p| p["MountPoint"] == "/Volumes/#{selected_volume}" }
      end
    end

    puts `diskutil unmountDisk "#{disk["DeviceIdentifier"]}"`
  end

  def create_progressbar
    ProgressBar.create(
      format: "Copying images: %a %b\u{15E7}%i %p%% %e",
      progress_mark: " ",
      remainder_mark: "\u{FF65}",
      total: images.count
    )
  end
end
