$: << File.join(File.dirname(__FILE__), 'vendor', 'rest-client', 'lib')
require 'rubygems'
require 'rest_client'
require 'json'

class Client
  # ruby client.rb 1 e27e3bcc 127.0.0.1 1111
  def initialize(user_id, password, host, port)
    @server = RestClient::Resource.new("http://#{host}:#{port}", 
                                       :user => user_id, 
                                       :password => password)
  end

  def account
    get_json '/account.json'
  end

  def cash_balance
    account['cash_balance']
  end

  def portfolio
    account['portfolio']
  end

  def equity
    values = stocks
    cash_balance + portfolio.inject(0){|sum, (stock, qty)| sum + 
      (qty * values[stock])}
  end

  def stocks
    get_json '/stocks.json'
  end

  def buy(symbol, quantity)
    post_json("/buy/#{symbol}/#{quantity}")
  end

  def sell(symbol, quantity)
    post_json("/sell/#{symbol}/#{quantity}")
  end

  protected

  def get_json(uri)
    JSON.parse(@server[uri].get)
  end
  
  def post_json(uri)
    JSON.parse(@server[uri].post(''))
  end

end

class DeadSimpleStrategy
  def initialize(client)
    @client = client
  end
  
  def run
    loop do
      puts "Equity: #{@client.equity}"
      reap_huge_windfall
      invest_in_penny_stocks
      sleep 1
    end
  end

  # how much of current cash to invest in cheap equities
  FoolishInvestmentFraction = 0.20

  def invest_in_penny_stocks
    cheapest_stock, price = @client.stocks.sort_by{|symbol, price| price}.first
    return unless cheapest_stock
    shares = (@client.cash_balance.to_f * FoolishInvestmentFraction / price).floor
    puts "Buying #{shares} shares of #{cheapest_stock}"
    @client.buy(cheapest_stock, shares)
  end

  # Percentage of current holdings to sell each round
  FoolishSaleFraction = 0.20

  def reap_huge_windfall
    portfolio = @client.portfolio
    stock, price = @client.stocks.sort_by{|symbol, price| -price}.
      find{|(symbol, price)| portfolio.keys.include?(symbol)}
    return unless stock
    holdings = portfolio[stock]
    to_sell = (FoolishSaleFraction * holdings).ceil
    puts "Selling #{to_sell} shares of #{stock}"
    @client.sell(stock, to_sell)
  end
end

if $0 == __FILE__
  DeadSimpleStrategy.new(Client.new(*ARGV)).run
end
