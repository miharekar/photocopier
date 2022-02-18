# Photocopier

I always do the same photo copying from SD cards and I decided to automate it. So I wrote this simple Ruby script.

This is how it works:

1. it asks on which volume the photos are
1. it analyzes exif of all the photos on it
1. it groups photos by day taken and camera model
1. it asks what those event names should be
1. it creates a folder per event on your desktop
1. it copies photos in there

It also remembers which photos were already imported, so it won't import them twice if you didn't format the card between imports.

Oh, and the `photos` above stands for images, videos, raw files,…, everything.

The script has been tested with:
- Leica Q2
- DJI Air 2S
- GoPro HERO10

Feel free to fork and extend for your own needs.

## Requirements

- [Ruby](https://www.ruby-lang.org/en/)
- [ExifTool](https://exiftool.org/)

## Running

Once you have all requirements on your system, you should clone this repo, and in your shell run the following commands:

1. `bundle install`
1. `sequel -m migrations sqlite://photos.db`
1. `ruby run.rb`
