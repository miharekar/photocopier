# frozen_string_literal: true

require "bundler"
Bundler.require
DB = Sequel.connect(adapter: :postgres, database: "photocopier", host: "localhost")

require_relative "copier"
Copier.new.run
