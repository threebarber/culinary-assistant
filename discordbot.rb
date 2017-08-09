require 'nokogiri'
require 'discordrb'
require 'faraday'
require 'open-uri'
require 'rest-client'

file      = File.read('config.json')
config    = JSON.parse(file)

bot = Discordrb::Commands::CommandBot.new token: config['token'], client_id: config['client_id'], prefix: '!'

bot.command :checkstock  do |event, url|

  sizearr,stockarr = [],[]

  if url.include?('?variant')
    url = url.split('?variant')[0]
  end

  @doc = Nokogiri::XML(open(url+".xml"))

  @doc.xpath('//option1').each do |size|
      size = size.text.to_s
      sizearr << size
  end

  @doc.xpath('//inventory-quantity').each do |stock|
    stock = stock.text.to_s
    stockarr << stock
  end

  sizearr.zip(stockarr).each do |size, stock|
    event.channel.send_embed() do |embed|
      embed.colour = 0x808080
      embed.add_field(name: "Size/Variant", value: size,inline: true)
      embed.add_field(name: "Stock", value: stock, inline: true)
    end
  end
  return
end

bot.command :proxy do |event|
  response = Faraday.get "https://gimmeproxy.com/api/getProxy?country=US&maxCheckPeriod=1000"
  proxyjson = JSON.parse(response.body)
  event.user.pm("#{proxyjson['ipPort']}")
end

bot.command(:releases) do |event,searchmonth, searchday|

  @doc = Nokogiri::HTML(open('http://www.solelinks.com/'))

  datearr,solelinkarr,imgarr   = [],[],[]

  @doc.css('.srp-linked-content').each do |date|
    date = date.text.to_s
    datearr << date.downcase
  end

  @doc.css('.srp-post-thumbnail').each do |img|
    img = img['src']
    imgarr << img
  end

  @doc.css('.postmoreinfolink').each do |href|
    solelink = href['href']
    solelinkarr << solelink
  end

  datearr.zip(solelinkarr,imgarr).uniq.each do |date,solelink,img|
    searchdate = searchmonth+" "+searchday
    if date == searchdate
      itemname = solelink.split('.com/')[1].tr("-"," ").split('/')[0]
      event.channel.send_embed() do |embed|
      embed.colour = 0x808080
      embed.image = Discordrb::Webhooks::EmbedImage.new(url: img)
      embed.add_field(name: "Sneaker", value: itemname)
      embed.add_field(name: "Link", value: solelink)
    end
    end
  end
end

bot.command(:goodwill) do |event, shoeurl|

  @doc = Nokogiri::HTML(open(shoeurl))
  attributearr,sizearr   = [],[]

  @doc.css('.attribute-item').each do |attri|
    attributearr << attri['data-value']
    sizearr << attri.text
  end

  attributearr.zip(sizearr).each do |attri, size|
    event.channel.send_embed() do |embed|
      embed.colour = 0x808080
      embed.add_field(name: "Size", value: size, inline: true)
      embed.add_field(name: "Attribute", value: attri, inline:true)
    end
  end
  return
end

  bot.command(:usage) do |event|
      embed.title = "Source"
      embed.colour = 0x808080
      embed.description = "[Bot repository](https://github.com/threebarber)"
      embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: "threebarber", url: "https://github.com/threebarber", icon_url: "https://avatars0.githubusercontent.com/u/19513830?v=4&s=460")
      embed.add_field(name: "Commands", value: "!checkstock <shopify item url>\n Retrieves stock for each size\n\n !proxy\n DM's the user a (usually)  working proxy\n\n !releases <date>\nReturns a name/image of shoes matching user-supplied release date (ie aug 05)\n\n!goodwill <shoe url>\n Returns item size with corresponding data value for backdooring")
    end

  bot.command(:cook) do |event|
    event.channel.send_embed do |embed|
      embed.title = "Adidas Bot Started"
      embed.colour = 0x808080
      embed.description = "50 bruteforcer tasks initiated..."
      embed.add_field(name: "Task Status....", value: "32 tasks through splash 18 in progress....")
      embed.add_field(name:"jk ur washed lol", value:" >_<")
    end
  end

bot.run
