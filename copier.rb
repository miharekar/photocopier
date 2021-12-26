# frozen_string_literal: true

require_relative "photo"
require_relative "image_exif"

class Copier
  IGNORED_EXTENSIONS = %w[.DS_Store .lrv .thm].freeze

  attr_reader :images, :exif_data, :events, :destinations

  def initialize
    find_images
    @exif_data = Exiftool.new(images)
    @events = detect_events
  end

  def run
    create_destinations
    copy_images
  end

  private

  def find_images
    @images = []
    path = "/Volumes/#{selected_volume}/DCIM"
    folders = Dir.entries(path).select do |f|
      File.directory?("#{path}/#{f}") && !f.start_with?(".")
    end
    folders.each do |folder|
      folder_path = "#{path}/#{folder}"
      entries = Dir.entries(folder_path).reject do |f|
        extension = File.extname(f).downcase
        f.start_with?(".") || IGNORED_EXTENSIONS.include?(extension)
      end
      @images += entries.map { |entry| "#{folder_path}/#{entry}" }
    end
  end

  def selected_volume
    volumes = Dir.entries("/Volumes").reject { |f| f.start_with?(".") }
    puts "Where are the images?"
    puts volumes.map.with_index(1) { |v, i| "#{i}: #{v}" }
    volumes[gets.chomp.strip.to_i - 1]
  end

  def detect_events
    images.filter_map do |image|
      image_exif = ImageExif.new(exif_data.result_for(image))
      photo = Photo.find_from_exif(image_exif)
      next if photo&.imported?

      date = image_exif.created_at.strftime("%Y-%m-%d")
      model = image_exif[:model]
      "#{date}|#{model}"
    end.uniq
  end

  def create_destinations
    desktop = "#{ENV['HOME']}/Desktop"
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
      image_exif = ImageExif.new(exif_data.result_for(image))
      photo = Photo.create_from_exif(image_exif)
      unless photo.imported?
        date = image_exif.created_at.strftime("%Y-%m-%d")
        model = image_exif[:model]
        event = "#{date}|#{model}"
        if destinations[event]
          destination = "#{destinations[event]}/#{image_exif.file_name}"
          FileUtils.cp(image, destination)
          photo.update(imported_at: Time.now)
        end
      end
      progressbar.increment
    end
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
