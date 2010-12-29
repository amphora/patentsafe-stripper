$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), "/../lib"))

require 'rubygems'
require 'test/unit'
require 'psstrip'

LOG = Logger.new(STDOUT)
LOG.level = Logger::ERROR

module TestHelper
  @@script = "ruby psstrip.rb"
  @@outdir = "tmp"
  @@psdir = "test/fixtures/ps-repositories/5.1"
end

class Test::Unit::TestCase
  include TestHelper

  ## helper
  def read_file(path)
    Pathname.new(File.expand_path(File.join(@@psdir,path))).read
  end

end