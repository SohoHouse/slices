require 'rails/generators'

module GeneratorHelpers
  def run_generator(command)
    commands = command.split
    generator = commands.shift
    commands << "--quiet"
    Rails::Generators.invoke generator, commands
  end
end

RSpec::Matchers.define :exist do
  match do |path|
    File.exist? path
  end
end

RSpec::Matchers.define :contain do |expected|
  match do |path|
    if File.exist?(path)
      actual = File.read path
      actual.gsub(/\s/, '').include? expected.gsub(/\s/, '')
    else
      false
    end
  end

  failure_message do |path|
    if File.exist? path
      "#{path} did not contain the expected content"
    else
      "#{path} did not exist"
    end
  end
end
