if RUBY_ENGINE == 'jruby'
  puts "Unfortunatelly as far as I know markdown does not work in JRuby, so this script won't work too."
  exit
end


begin
  require 'sinatra'

  get '/' do
    markdown File.read('README.md')
  end
rescue LoadError
  puts "This script requires sinatra gem. You have to do:\ngem install sinatra"
end
