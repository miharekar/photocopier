# Photocopier

I always do the same photo copying from SD cards and I decided to automate it.

It's a very simple Ruby script. This is how it works:

1. it asks on which volume the photos are
1. it analyzes exif of all the photos on it
1. it groups photos by day taken and camera model
1. it asks what those event names should be
1. it creates a folder per event on your desktop
1. it copies photos in there

It remembers which photos were already imported so it won't import them twice.

Requirements:
- [Ruby](https://www.ruby-lang.org/en/)
- [ExifTool](https://exiftool.org/)
- [PostgreSQL](https://www.postgresql.org/)

Once you have all those in your system you should clone this repo and in your shell run following commands:

1. `bundle install`
1. `createdb photocopier`
1. `sequel -m migrations/ postgres://localhost/photocopier`

Then you can run it with `ruby photocopy.rb`

Tested with:
- Leica Q2
- DJI Air 2S
- GoPro HERO10

Feel free to fork and extend for your own needs.
