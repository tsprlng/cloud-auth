CompanyName = 'Company'
CompanyDirName = 'company'
RootConfigProperty = CompanyDirName
	# we put everything in our config file under this root property, to be sure we're reading the right file

AwsAccountEnvVar = 'AWS_ACCOUNT'
AwsEnvironmentEnvVar = 'AWS_ENV'
GcpProjectEnvVar = 'GCP_PROJECT'
GcpEnvironmentEnvVar = 'GCP_ENV'
GkeEnvironmentEnvVar = 'GKE_ENV'

# in addition to these constants, this provides a Config class which is also a callable
# Config('thing1.thing2') pulls the value from the config file under {company: { thing1: { thing2: "this one here" }}}
# Config.cache_dir is a method which returns a named directory under ~/.cache/company/, with an optional config variable for a path override

require 'fileutils'
require 'yaml'

ConfigFilePath = File.expand_path(ENV['COMPANY_CONFIG_FILE'] || File.join(ENV['XDG_CONFIG_HOME'] || '~/.config', "#{CompanyDirName}.yml"))
ConfigFromFile = YAML.load_file(ConfigFilePath)[RootConfigProperty] or raise "Config not found"

class NoDefault; end

class Config
	def self.debug(*stuff)
		#p(*stuff)  # uncomment to enable
	end

	def self._find_in_tree(start, propertyString)
		debug [start.class, propertyString]
		return nil if start.nil?
		case propertyString
			when '', nil
				debug "=> #{start.inspect}"
				start
			when /\A'([a-z\-\.]+)'(\.(.+))?\Z/
				_find_in_tree(start[$1], $3)
			when /\A([a-z\-]+)(\.(.+))?\Z/
				_find_in_tree(start[$1], $3)
			else
				(raise "Failed to parse #{propertyString.inspect}")
		end
	end

	def self.config(propertyString, default=NoDefault)
		_find_in_tree(ConfigFromFile, propertyString) || (
			(default == NoDefault) ? raise : default
		)
	rescue
		raise "Couldn't find config property #{("#{RootConfigProperty}."+propertyString).inspect}"
	end

	def self.cache_dir(name, propertyString=nil)
		dir_path = nil
		dir_path = config(propertyString, nil) if propertyString
		dir_path ||= File.join((ENV['XDG_CACHE_HOME'] || '~/.cache'), CompanyDirName, name)

		dir_path = File.expand_path(dir_path)
		FileUtils.mkdir_p(dir_path)
		debug "cache dir: #{dir_path}"
		dir_path
	end
end

def Config(*args)
	Config.config(*args)
end
