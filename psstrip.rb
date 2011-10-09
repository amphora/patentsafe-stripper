#!/usr/bin/env ruby
#
# == Synopsis
#   Script to create a copy of a PatentSafe repository stripped of
#   sensitive data.
#
# == Examples
#     ruby psstrip.rb source target
#     ruby psstrip.rb /path/to/repository /path/to/copy
#
#     * source is a patentsafe directory
#     * target is directory where stripped copy will be made. It is created
#       if it doesn't exist. If it exists and is non-empty you'll need to
#       pass the -f (--force) option.
#
#   Other examples:
#     ruby psstrip.rb -f -q /path/to/repository /path/to/copy
#     ruby psstrip.rb -q /path/to/repository /path/to/copy
#     ruby psstrip.rb --verbose /path/to/repository /path/to/copy
#     ruby psstrip.rb -V /path/to/repository /path/to/copy
#     ruby psstrip.rb -f -t 1 /path/to/repository /path/to/copy
#
# == Usage
#   psstrip.rb [options] "/path/to/repository" "/path/to/copy"
#
#   For help use: ruby psstrip.rb -h
#
# == Options
#   -f, --force         Force copy to non-empty directory
#   -t, --throttle      Throttle the speed of the stripper (0-10) [Default 0]
#   -h, --help          Displays help message
#   -v, --version       Display the version, then exit
#   -q, --quiet         Output as little as possible, overrides verbose
#   -V, --verbose       Verbose output
#
# == Copyright
#   Copyright (c) 2010,2011 Amphora Research Systems Ltd.
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#


# ===========================================================================
# psstrip.rb
# ===========================================================================

require 'date'
require 'fileutils'
require 'find'
require 'logger'
require 'optparse'
require 'ostruct'
require 'pathname'
require 'rdoc/usage'
require 'rexml/document'


# Setup global logger if file is being run as a script (not included)
if __FILE__ == $PROGRAM_NAME
  LOG = Logger.new(STDOUT)
end


# Script
#   sets up arguments, logging level, and options. Also handles help output.
class Script
  VERSION = '0.2.4'

  # Simple log formatter
  class Formatter < Logger::Formatter
    def call(severity, time, program_name, message)
      "#{message}\n"
    end
  end

  attr_reader :options

  def initialize(arguments, stdin)
    @arguments = arguments
    @stdin = stdin
    @options = OpenStruct.new
    @options.force = false
    @options.throttle = nil
    @options.verbose = false
    @options.quiet = false
  end

  def run
    LOG.formatter = Formatter.new

    if parsed_options? && arguments_valid?

      LOG.level = if @options.verbose
        Logger::INFO
      elsif @options.quiet
        Logger::ERROR
      else # default
        Logger::WARN
      end

      process_arguments
      process_command
    else
      output_usage
    end

  end

  protected

  def parsed_options?
    opts = OptionParser.new
    opts.on('-f', '--force')    { @options.force = true }
    opts.on('-t', '--throttle [AMOUNT]', Integer) { |throttle| @options.throttle = throttle }
    opts.on('-v', '--version')  { output_version ; exit 0 }
    opts.on('-h', '--help')     { output_help }
    opts.on('-V', '--verbose')  { @options.verbose = true }
    opts.on('-q', '--quiet')    { @options.quiet = true }
    opts.parse!(@arguments) rescue return false
    process_options
    true
  end

  # Performs post-parse processing on options
  def process_options
    @options.verbose = false if @options.quiet
  end

  # True if required arguments were provided
  def arguments_valid?
    true if @arguments.length == 2
  end

  # Setup the arguments
  def process_arguments
    @source = Pathname.new(File.expand_path(ARGV[0])) if ARGV[0]
    @target = Pathname.new(File.expand_path(ARGV[1])) if ARGV[1]

    # check the target
    if @target.exist?
      if !@target.children.empty? && !@options.force
        LOG.error "Target directory '#{@target.to_s}' exists and is not empty. Pass -f (--force) option to proceed anyway."
        exit 0
      end
    else
      @target.mkpath
    end

  end

  def process_command
    repo = PatentSafe::Repository.new(:path => @source)
    repo.copy_to(@target, @options.throttle)
  end

  def version_text
    "#{File.basename(__FILE__)} version #{VERSION}"
  end

  def output_help
    LOG.info version_text
    RDoc::usage() #exits app
  end

  def output_usage
    RDoc::usage('usage') # gets usage from comments above
  end

  def output_version
    LOG.info version_text
    RDoc::usage('copyright')
  end

  def output_options
    LOG.info "Options:\n"
    @options.marshal_dump.each do |name, val|
      LOG.info "  #{name} = #{val}"
    end
  end

end # class Script


# PatentSafe
#  wrapper around PatentSafe data and objects
module PatentSafe

  class Repository
    attr_accessor :path
    attr_reader :rules, :user_subs, :totals, :users, :user_name_map, :user_id_map, :workgroups, :workgroup_map

    # File patterns used to match against repo file paths

    # SKIP_DIRS: directories we skip altogether
    SKIPDIRS = [
      "configlets",
      "index",
      "printers",
      "printjobs",
      "queues",
      "scanning",
      "scripts",
      "spool",
      "users"
    ]

    # COPY: files that are copied with no changes
    COPY = [
      "classifications\.xml$",
      "id-values\.xml$",
      "settings\.xml$",
      "tenants\.xml$"
    ]

    # SKIP: files that are not copied
    SKIP = [
      ".*\.(png|ps|pdf)$", # images + pdf
      "database\.xml",
      # any of our main files with additional ext data (migrated/update/etc)
      "docinfo\.xml.+",
      "signature\-\d\d\d\.xml.+",
      "events\.txt.+",
      "log\.xml.+",
      "workgroups\.xml.+",
      "events\.log.+",
      "settings\.xml.+"
    ]

    # REPLACE: files that have their entire contents replaced before copy
    REPLACE = [
      "content\.txt"
    ]

    # STRIP: files that are cleaned before copy with doc specific substitutions
    # ** All 'STRIP' files are checked for user/group data
    STRIP = [
      ["docinfo\.xml$",[
          ["<summary>.*<\/summary>"              , "<summary>~summary stripped by psstrip~</summary>"],
          ["<text>.*<\/text>"                    , "<text>~text stripped by psstrip~</text>"],
          ["<metadataValues>.*<\/metadataValues>", "<metadataValues>~metadata stripped by psstrip~</metadataValues>"]]
      ],

      ["signature\-\d\d\d\.xml$", []],

      ["events\.(txt|log)$", []], # 5.0 merge of events.log + log.xml # 4.8 is events.log

      ["log\.xml$", []], # 4.8 read log

      ["workgroups\.xml$", []]
    ]

    # USER_SUBSTITUTIONS: substitutions for user files
    USER_SUBSTITUTIONS = [
      ["<aliases>.*<\/aliases>"  , "<aliases/>"],
      ["<email>.*<\/email>"      , "<email>stripped.email@example.com</email>"],
      ["<password>.*<\/password>", "<password>fa4afd98097d7f7c7ced012edb56d2c6c6987e31f2f12caa3a422e8b</password>"]
    ]

    def initialize(options={})
      @path = Pathname.new(options[:path].to_s) if options[:path]
      @users = Hash.new
      @user_name_map = Array.new
      @user_id_map = Array.new
      @workgroups = Hash.new
      @workgroup_map = Array.new
      @rules = Array.new
      @user_subs = Array.new
      @totals = OpenStruct.new
      @totals.users = 0
      @totals.workgroups = 0
      @totals.skipped = 0
      @totals.stripped = 0
      @totals.replaced = 0
      @totals.copied = 0

      LOG.info "-----------------------------------------------------------------------"
      LOG.info " PatentSafe Stripper "
      LOG.info "-----------------------------------------------------------------------"
      LOG.warn " Started at: #{Time.now}"
      LOG.info ""

      load_users
      load_workgroups
      load_rules
    end

    def data_path
      @path.join('data').expand_path
    end

    def user_id_mapping(userid)
      user_id_map.find{|k,v| k == userid }[1]
    end

    def user_name_mapping(name)
      user_name_map.find{|k,v| k == name}[1]
    end

    def load_rules
      # prep user name and user id rules
      user_names = @user_name_map.map{ |name, namesub| [/[>](#{name})[<]/im, namesub] }
      user_ids = @user_id_map.map{ |id, idsub| [/[~'"](#{id})["~']/im, idsub] }
      workgroups = @workgroup_map.map{ |group, groupsub| [/(#{group})/im, groupsub] }

      # array keeps them ordered
      #   nested array is string_pattern, regexp, rule, substitutions
      COPY.each{    |pattern| @rules << [pattern, /#{pattern}/i, :copy,    nil] }
      REPLACE.each{ |pattern| @rules << [pattern, /#{pattern}/i, :replace, nil] }
      SKIP.each{    |pattern| @rules << [pattern, /#{pattern}/i, :skip,    nil] }

      # add user and group subs to file specific subs
      STRIP.each do |pattern, subs|
        subs = subs.map{ |regex, sub| [/(#{regex})/im, sub] }

        @rules << [
          pattern,
          /#{pattern}/i,
          :strip,
          [].concat(user_names).concat(user_ids).concat(workgroups).concat(subs)
        ]
      end

      # rules for use files
      @user_subs.concat(USER_SUBSTITUTIONS.map{ |regex, sub| [/(#{regex})/im, sub] })
      @user_subs.concat(user_names).concat(user_ids).concat(workgroups)
    end

    # Loads users from the xml in the repo
    def load_users
      users_path = @path.join('data', 'users').expand_path
      LOG.info ""
      LOG.info "** loading users from #{users_path}"

      names = []
      ids = []

      Dir["#{users_path}/**/*.xml"].each_with_index do |path,i|
        user = OpenStruct.new
        user.xml = REXML::Document.new(File.read(path))
        user.user_id = user.xml.root.attribute("userId").to_s
        user.name = user.xml.root.get_text("name").value().to_s
        user.anon_id = "user#{i}"
        user.anon_name = "User #{i}"

        unless user.user_id == "installer"
          # user id and user name index
          ids << [user.user_id, user.anon_id]
          names << [user.name, user.anon_name]
        end

        # store the user
        @users[user.user_id] = user
        @totals.users += 1
        LOG.info " - loaded #{user.name} [#{user.user_id}]"
      end

      @user_name_map.concat(names)
      @user_id_map.concat(ids)
      LOG.info "** #{@users.length} users loaded"
    end

    # Loads workgroups from the xml in the repo
    def load_workgroups
      workgroups_file = @path.join('data', 'config', 'workgroups.xml')
      return unless workgroups_file.exist?
      LOG.info ""
      LOG.info "** loading workgroups from #{workgroups_file}"

      xml = REXML::Document.new(workgroups_file.read)
      xml.root.elements.each do |wgxml|
        workgroup = OpenStruct.new
        workgroup.wg_id = wgxml.attribute("wgId").to_s
        workgroup.name = wgxml.attribute("name").to_s
        workgroup.anon_id = workgroup.wg_id
        workgroup.anon_name = "Group #{workgroup.wg_id}"

        # group name index
        @workgroup_map << [workgroup.name, workgroup.anon_name] unless workgroup.name == "Admin"

        # store the workgroup
        @workgroups[workgroup.wg_id] = workgroup
        @totals.workgroups += 1
        LOG.info " - loaded #{workgroup.name} [#{workgroup.wg_id}]"
      end

      LOG.info "** #{@workgroups.length} workgroups loaded"
    end

    # Applies substitutions to the content
    def strip_content(subs, file)
      subs.each{ |pattern, sub| file.gsub!(pattern){ |match| match.gsub!($1, sub) } }
      file
    end

    def copy_users_to(dest)
      # create user directory
      users_dir = dest.join('data','users','us','er')
      users_dir.mkpath

      # copy users from memory to new users directory
      @users.each do |id, user|
        if id == "installer"
          # now copy the installer
          inst_dir = dest.join('data', 'users', 'in', 'st', 'installer')
          inst_dir.mkpath
          installer = @users["installer"]
          inst_dir.join("installer.xml").open("w+"){|t| t.puts strip_content(@user_subs, installer.xml.to_s)}
        else
          # create user dir
          user_dir = users_dir.join(user.anon_id)
          user_dir.mkpath

          # write the stripped user file
          user_dir.join("#{user.anon_id}.xml").open("w+"){|t| t.puts strip_content(@user_subs, user.xml.to_s)}
          LOG.info " - stripped #{user.user_id}.xml"
        end
      end

    end

    def copy_to(dest, throttle = nil)
      # ensure we have Pathname objects
      root = Pathname.new(@path.to_s)
      dest = Pathname.new(dest.to_s)

      LOG.info ""
      LOG.info "** copying patentsafe repository from #{root.to_s}"
      LOG.info "  (Throttled at #{throttle})" unless throttle == 0

      # Descend through the PatentSafe repository
      Find.find(root.to_s) do |path|

        sleep(throttle * 0.001) if throttle

        src = Pathname.new(path) # pathname to slice and dice
        rel = src.relative_path_from(root) # just the part below the top dir
        target = Pathname.new(File.join(dest.to_s, rel))
        basename = src.basename.to_s

        if src.directory?
          if SKIPDIRS.include?(basename) || basename =~ /^\./i
            Find.prune # skip dot directories and those in SKIPDIRS
          else
            target.mkpath unless target.exist?
          end
        else
          rules.each do |key, pattern, rule, subs|
            if pattern =~ basename

              case rule
              when :strip
                target.open("w+") do |t|
                  # process potentially long log files line by line
                  if %w[events.log events.txt].include?(basename)
                    LOG.info " -- processing #{basename}"
                    src.open("r"){ |s| s.each{ |l| t.puts strip_content(subs, l) } }
                  else
                    t.puts strip_content(subs, src.read)
                  end
                end
                @totals.stripped += 1
                LOG.info " - stripped #{basename}"

              when :skip
                @totals.skipped += 1
                LOG.info " - skipped #{basename}"

              when :replace
                target.open("w+"){|t| t.puts "~stripped by psstrip~"}
                @totals.replaced +=1
                LOG.info " - replaced #{basename}"

              else # :copy
                FileUtils.cp(src.to_s, target.to_s)
                @totals.copied += 1
                LOG.info " - copied #{basename}"

              end # case

              # short circuit @rules.each
              break

            end
          end # rules.each
        end # if src.directory?
      end # Find

      copy_users_to dest
      total = @totals.stripped + @totals.replaced + @totals.skipped + @totals.copied + @totals.users
      pad = total.to_s.length + 2

      LOG.info ""
      LOG.warn " PatentSafe repository copied to: #{File.expand_path(dest.to_s)}"
      LOG.warn ""
      LOG.warn "  * Files stripped: #{@totals.stripped.to_s.rjust(pad)}"
      LOG.warn "  * Files replaced: #{@totals.replaced.to_s.rjust(pad)}"
      LOG.warn "  * Files skipped:  #{@totals.skipped.to_s.rjust(pad)}"
      LOG.warn "  * Files copied:   #{@totals.copied.to_s.rjust(pad)}"
      LOG.warn "  * Users copied:   #{@totals.users.to_s.rjust(pad)}"
      LOG.warn ""
      LOG.warn " Total processed:   #{total.to_s.rjust(pad)}"
      LOG.info ""
      LOG.warn " Ended at: #{Time.now}"
      LOG.info "-----------------------------------------------------------------------"

    end # def copy_to

  end # class Repository

end # module PatentSafe


# Only run script if called from command line and not included as a lib
if __FILE__ == $PROGRAM_NAME
  # Create and run the application
  script = Script.new(ARGV, STDIN)
  script.run
end


