require 'plist'
require 'fileutils'
require 'logger'
require 'securerandom'

class Marosi
  LOGGER = Logger.new(STDOUT)

  attr_reader :source, :destination, :dryrun
  def initialize(source, destination)
    @source = source
    @destination = destination

    validate_source
    create_destination_if_missing
  end

  def validate_source
    raise "source directory #{source} does not exist" unless Dir.exists?(source)
  end

  def create_destination_if_missing
    unless Dir.exists?(destination)
      LOGGER.info("Creating destination folder #{destination}")
      Dir.mkdir(destination)
    end

    LOGGER.warn("destination #{destination} is not empty") unless Dir.empty?(destination)
  end

  def run(dryun=true)
    Dir.glob("#{source}/**/original.jpg").each do |jpg_path|
      dir = File.dirname(jpg_path)
      plist_path = dir + "/entryInfo.plist"

      if File.exists?(plist_path) && plist = Plist.parse_xml(plist_path)

        caption = plist["caption"].strip

        if caption == ''
          caption = 'no name'
        end

        new_file_name = determine_new_file_name(caption)

        destination_path = destination + "/" + new_file_name

        FileUtils.cp(jpg_path, destination_path) unless dryun
        LOGGER.info('caption:' + caption)
        LOGGER.info("#{jpg_path} => #{destination_path}")
        LOGGER.info('-----------------------')
      else
        LOGGER.warn("Could not load plist at #{plist_path} for #{jpg_path}")
      end
    end
  end

  def determine_new_file_name(caption)
    new_file_name = caption.split(/\,|\s/).join('_').downcase
    if File.exists?(destination + "/" + new_file_name + ".jpg")
      new_file_name += ("_" + SecureRandom.alphanumeric(8).downcase)
    end
    new_file_name + ".jpg"
  end
end
