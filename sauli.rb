require 'selenium-webdriver'
require 'nokogiri'
require 'capybara'
require 'capybara/dsl'
# Configurations
Capybara.register_driver :selenium do |app|  
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: Selenium::WebDriver::Chrome::Options.new(args: %w[headless disable-gpu window-size=1024,768]))
end
Capybara.javascript_driver = :chrome
Capybara.configure do |config|  
  config.default_max_wait_time = 10 # seconds
  config.default_driver = :selenium
end
# Visit
browser = Capybara.current_session
driver = browser.driver.browser

driver.navigate.to "http://192.168.1.1"

class Sauli
  include Capybara::DSL

  def initialize(driver)
    @driver = driver
  end
  
  def login
    find("input[type='password']").set(ENV["SAULI_PASSWORD"])
    click_on "Log in"
    wait_for_login
  end

  def wait_for_login
    loop do
      sleep(0.5)
      if all("#basic").length > 0
        break
      elsif all("#confirm-yes").length > 0
        find("#confirm-yes").click
      end
    end
  end

  def data_used
    if all("#basic.selected").length == 0
      find("#basic").click
    end
    
    find("input[id='data']").value.split(" ").first.to_f
  end

  def sms_received
    if all("#advanced.selected").length == 0
      find("#advanced").click
    end

    find("#sms").click
    find("a", text: "Inbox").click
    loop do
      sleep 0.5
      break if all("#tableSmsInboxBody").length > 0
    end

    return [] if all("#msg_0").length == 0

    messages = []
    
    find("#msg_0").click


    loop do
      messages << {
        sender: find("#phoneNumber").text,
        received_at: find("#recvTime").text,
        content: find("#msgContent").text
      }
      
      if all("#msgNext.next-icon-blue").length == 1
        find("#msgNext.next-icon-blue").click
      else
        return messages
      end
    end
  end

  def logout
    find("#topLogout").click
    click_on "yes"
  end
  
end

sauli = Sauli.new(driver)
sauli.login

puts "Data left: #{sauli.data_used} GB"

sauli.sms_received.each do |sms|
  puts "---"
  puts [ sms[:sender], sms[:received_at] ].join("\t")
  puts sms[:content]
end

sauli.logout




