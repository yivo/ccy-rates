ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __FILE__)

require "bundler"
require "bundler/setup"
Bundler.require :default, :development
require "active_support/core_ext/string"
require "active_support/core_ext/array"
require "json"

def print_courses(source, courses)
  print source.colorize(:yellow), "\n"
  print " " * 3, "    ", "YOU BUY".underline, " " * 7, "YOU SELL".underline, "\n"
  
  ["USD", "EUR", "RUB", "BTC"].each do |ccy|
    if (course = courses[ccy])
      print ccy.ljust(4).colorize(ccy === "USD" ? :red : :default), 
            ("%.8f" % course[:buy]).rjust(14).colorize(ccy === "USD"  ? :light_magenta : :default), 
            ("%.8f" % course[:sell]).rjust(14).colorize(ccy === "USD" ? :light_magenta : :default), "\n"
    end  
  end
  
  print "\n"
end    

def privat_courses
  courses = {}
  JSON.load(Faraday.get("https://api.privatbank.ua/p24api/pubinfo?json&exchange&coursid=3").body).tap do |x|
    x.each { |y| courses[y["ccy"] == "RUR" ? "RUB" : y["ccy"]] = { buy: y["buy"].to_f, sell: y["sale"].to_f } }
  end
  print_courses("PrivatBank", courses)
end    

def black_market_courses
  courses  = {}
  document = Nokogiri::HTML.fragment(Faraday.get("https://finance.ua/").body) { |config| config.nonet.huge.nowarning.noerror }
  td_els   = document.at_css("#table-currency-tab0").css("> table > tbody > tr:nth-child(2n+1) > td")
  td_els.to_a.in_groups_of 3, false do |group|
    courses[group[0].text.squish.upcase] = { buy: group[2].text.squish.upcase.to_f, sell: group[1].text.squish.upcase.to_f }
  end
  print_courses("Black Market", courses)
end

privat_courses
black_market_courses
