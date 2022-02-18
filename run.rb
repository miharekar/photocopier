# frozen_string_literal: true

require "bundler"
Bundler.require
DB = Sequel.connect("sqlite://photos.db")

require_relative "copier"
Copier.new.run
