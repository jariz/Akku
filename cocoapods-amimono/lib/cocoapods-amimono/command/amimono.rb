require 'claide'
require 'cocoapods-amimono/gem_version'

module Amimono
  class Command < CLAide::Command

    self.abstract_command = true
    self.command = 'amimono'
    self.version = CocoapodsAmimono::VERSION
    self.description = <<-DESC
      Move all dynamic frameworks symbols into the main executable.
    DESC

    def self.run(argv)
      super(argv)
    end
  end
end
