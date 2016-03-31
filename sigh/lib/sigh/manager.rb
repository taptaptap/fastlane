require 'plist'
require 'sigh/runner'

module Sigh

  ProfileWithPath = Struct.new(:profile, :path)

  class Manager
    def self.start
      tuples = Sigh::Runner.new.run

      return nil unless tuples

      dir = Sigh.config[:output_path]
      FileUtils.mkdir_p(dir) unless dir == '.'

      if tuples.count == 1 && Sigh.config[:filename] && !Sigh.config[:filename].include?('%')
        UI.important("Found #{tuples.count} profiles but only 1 will be saved. Remove --filename?")
      end

      result = []
      tuples.each do |tuple|
        output = output_file_name(tuple[:profile], dir, tuple[:path])
        begin
          FileUtils.mv(tuple[:path], output)
        rescue
          # in case it already exists
        end
        install_profile(output) unless Sigh.config[:skip_install]
        puts output.green
        result << output
      end

      return result
    end

    def self.output_file_name(profile, directory, path)
      if Sigh.config[:filename]
        if Sigh.config[:filename] == '%name' # FIXME: accept more placeholders and replace them in :filename
          output = File.join(File.expand_path(directory), profile.name)
        else
          output = File.join(File.expand_path(directory),  File.basename(Sigh.config[:filename]))
        end
      else
        output = File.join(File.expand_path(directory),  File.basename(path))
      end
      output += '.mobileprovision' unless output.include? 'mobileprovision'
      output
    end


    def self.download_all
      require 'sigh/download_all'
      DownloadAll.new.download_all
    end

    def self.install_profile(profile)
      udid = FastlaneCore::ProvisioningProfile.uuid(profile)
      ENV["SIGH_UDID"] = udid if udid

      FastlaneCore::ProvisioningProfile.install(profile)
    end
  end
end
