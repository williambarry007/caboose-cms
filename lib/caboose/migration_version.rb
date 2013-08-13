module Caboose

  class Version
    include Comparable
    attr_accessor :str, :migrations

    def initialize(str, migration_range)
      @str = str
      @migrations = []

      if !migration_range.nil?

        directory = File.join(File.expand_path('../../..', __FILE__), 'db/migrate')
        files = Dir.entries(directory).select{ |f| !File.directory?(f) && /[0-9]{3}_[^\n\r\.]+\.rb$/ =~ f && migration_range.include?(f[0..2].to_i) }
        files.sort.each do |f|
          require File.join(directory, f)
          /[0-9]{3}_(?<clazz_name>[^\n\r\.]+)\.rb$/ =~ f
          @migrations += [clazz_name.classify.constantize.new]
        end
      end

    end

    def to_s
      return @str
    end

    def self.compare_version_strings(a, b)
      a = a.split('.').map{|s| s.to_i}
      b = b.split('.').map{|s| s.to_i}
      return a <=> b
    end

    def <=>(other)
      return Version.compare_version_strings(@str, other.to_s)
    end

    def up(c)
      @migrations.each{|m| m.up(c)}
    end

    def down(c)
      @migrations.reverse_each{|m| m.down(c)}
    end
  end

end