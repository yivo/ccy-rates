# encoding: UTF-8
# frozen_string_literal: true

require "json"
require "date"
require "active_support/core_ext/string/filters"
require "active_support/core_ext/array/grouping"
require "nokogiri"
require "colorize"
require "faraday"

def useful_currencies
  ["USD", "EUR", "CAD", "RUB", "BTC"]
end

def normalize_currency_name(ccy)
  ccy = ccy.squish.upcase
  case ccy
    when "RUR" then "RUB"
    else ccy
  end
end

def colorize_currency_name(ccy, colorizable)
  case ccy
    when "USD" then colorizable.colorize(:red)
    else colorizable
  end
end

def colorize_currency_rate(ccy, rate)
  case ccy
    when "USD" then rate.colorize(:white)
    else rate
  end
end

def format_currency_rate(ccy, rate)
  "%.8f" % rate
end

def print_rates(source, rates)
  existing_currencies = useful_currencies.select { |ccy| rates.key?(ccy) }
  existing_rates      = existing_currencies.map { |ccy| rates[ccy] }.compact
  return if existing_currencies.empty? || existing_rates.empty?

  # Support data for padding calculation.
  longest_currency_name  = existing_currencies.sort_by(&:length).last
  heading_padding_length = longest_currency_name.length + (15 - existing_rates.first[:buy].round.to_s.size - 1 - 8)

  # If source doesn't buy currency from us.
  buy_only               = existing_rates.none? { |rate| rate.key?(:sell) }

  print source.colorize(:yellow), "\n"
  print " " * heading_padding_length, "YOU BUY".underline
  print " " * 8, "YOU SELL".underline unless buy_only
  print "\n"

  existing_rates.each do |rate|
    ccy = rate[:ccy]
    print colorize_currency_name(ccy, ccy.ljust(useful_currencies.map(&:length).max)),
          colorize_currency_rate(ccy, format_currency_rate(ccy, rate[:buy]).rjust(15))
    print colorize_currency_rate(ccy, format_currency_rate(ccy, rate[:sell]).rjust(15)) unless buy_only
    print "\n"
  end
  
  print "\n"
end

def privatbank_exchange_office_rates
  url   = "https://api.privatbank.ua/p24api/pubinfo?json&exchange&coursid=5"
  rates = {}
  JSON.load(Faraday.get(url).body).tap do |x|
    x.each do |y|
      ccy        = normalize_currency_name(y["ccy"])
      rates[ccy] = { ccy: ccy, buy: y["sale"].to_f, sell: y["buy"].to_f }
    end
  end
  print_rates("PrivatBank (currency exchange office)", rates)
rescue Faraday::Error => e
  warn "Failed to load #{url}: #{e.inspect}."
end

def privatbank_cashless_rates
  url   = "https://api.privatbank.ua/p24api/pubinfo?json&exchange&coursid=11"
  rates = {}
  JSON.load(Faraday.get(url).body).tap do |x|
    x.each do |y|
      ccy        = normalize_currency_name(y["ccy"])
      rates[ccy] = { ccy: ccy, buy: y["sale"].to_f, sell: y["buy"].to_f }
    end
  end
  print_rates("PrivatBank (cashless)", rates)
rescue Faraday::Error => e
  warn "Failed to load #{url}: #{e.inspect}."
end

def national_bank_of_ukraine_rates
  url   = "https://bank.gov.ua/NBUStatService/v1/statdirectory/exchange?json"
  rates = {}
  JSON.load(Faraday.get(url).body).tap do |x|
    x.each do |y|
      ccy        = normalize_currency_name(y["cc"])
      rates[ccy] = { ccy: ccy, buy: y["rate"].to_f }
    end
  end
  print_rates("National Bank of Ukraine", rates)
rescue Faraday::Error => e
  warn "Failed to load #{url}: #{e.inspect}."
end

def finance_ua_black_market_rates
  url      = "https://finance.ua/"
  rates    = {}
  document = Nokogiri::HTML.fragment(Faraday.get(url).body) { |config| config.nonet.huge.nowarning.noerror }
  td_els   = document.at_css("#table-currency-tab0").css("> table > tbody > tr:nth-child(2n+1) > td")
  td_els.to_a.in_groups_of 3, false do |group|
    ccy        = normalize_currency_name(group[0].text)
    rates[ccy] = { ccy: ccy, buy: group[2].text.squish.to_f, sell: group[1].text.squish.to_f }
  end
  print_rates("Black Market (finance.ua)", rates)
rescue Faraday::Error => e
  warn "Failed to load #{url}: #{e.inspect}."
end

def finance_i_ua_black_market_rates
  url      = "https://finance.i.ua/"
  rates    = {}
  document = Nokogiri::HTML.fragment(Faraday.get(url).body) { |config| config.nonet.huge.nowarning.noerror }
  document.at_css(".widget-currency_cash").css("tbody tr").each do |tr|
    ccy        = normalize_currency_name(tr.at_css("th").text)
    tds        = tr.css("td")
    rates[ccy] = { ccy: ccy, buy: tds[1].text.squish.to_f, sell: tds[0].text.squish.to_f }
  end
  print_rates("Black Market (finance.i.ua)", rates)
rescue Faraday::Error => e
  warn "Failed to load #{url}: #{e.inspect}."
end

print "Today's currency exchange rates in Ukraine".colorize(:yellow),
      "\n",
      Date.today.strftime("%A, %B %e, %Y").underline,
      "\n\n"

national_bank_of_ukraine_rates
privatbank_exchange_office_rates
privatbank_cashless_rates
finance_ua_black_market_rates
finance_i_ua_black_market_rates
