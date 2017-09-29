# encoding: UTF-8
# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name            = "ccy-rates"
  s.version         = "1.0.1"
  s.author          = "Yaroslav Konoplov"
  s.email           = "eahome00@gmail.com"
  s.summary         = "Currency exchange rates in your shell."
  s.description     = "ccy-rates is a command-line utility that allows you to easily grab the currency exchange rates at National Bank of Ukraine, PrivatBank and black market."
  s.homepage        = "https://github.com/yivo/ccy-rates"
  s.license         = "Apache-2.0"

  s.files           = `git ls-files -z`.split("\x0")
  s.test_files      = `git ls-files -z -- {test,spec,features}/*`.split("\x0")
  s.require_paths   = ["lib"]
  s.executables     = s.files.grep(/\Abin\//) { |f| File.basename(f) }

  s.add_dependency "nokogiri",      "~> 1.6"
  s.add_dependency "faraday",       "~> 0.12"
  s.add_dependency "activesupport", ">= 3.0", "< 6.0"
  s.add_dependency "colorize",      "~> 0.8"
end
