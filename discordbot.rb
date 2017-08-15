require 'nokogiri'
require 'discordrb'
require 'faraday'
require 'open-uri'
require 'rest-client'


file      = File.read('config.json')
config    = JSON.parse(file)

bot = Discordrb::Commands::CommandBot.new token: config['token'], client_id: config['client_id'], prefix: '!'
@tgwo,@dsm,@eflash,@kith = true,true,true,true
@agentList = ["Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:21.0) Gecko/20130331 Firefox/21.0","Mozilla/5.0 (Windows NT 6.2; WOW64; rv:21.0) Gecko/20100101 Firefox/21.0","Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.93 Safari/537.36"]
@user_agent = @agentList.sample

bot.command :checkstock  do |event, url|

  sizearr,stockarr = [],[]

  if url.include?('?variant')
    url = url.split('?variant')[0]
  end

  @doc = Nokogiri::XML(open(url+".xml", 'User-Agent' => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_0) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.854.0 Safari/535.2"))

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

  form = @doc.xpath('//@action')
    event.channel.send_embed() do |embed|
      embed.colour = 0x808080
      embed.title = "ATC Form"
      embed.description = form[0]
    end


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
    event.channel.send_embed do |embed|
      embed.title = "Source"
      embed.colour = 0x808080
      embed.description = "[Bot repository](https://github.com/threebarber)"
      embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: "threebarber", url: "https://github.com/threebarber", icon_url: "https://avatars0.githubusercontent.com/u/19513830?v=4&s=460")
      embed.add_field(name: "Commands", value: "!checkstock <shopify item url>\n Retrieves stock for each size\n\n !proxy\n DM's the user a (usually)  working proxy\n\n !releases <date>\nReturns a name/image of shoes matching user-supplied release date (ie aug 05)\n\n!goodwill <shoe url>\n Returns item size with corresponding data value for backdooring")
      embed.add_field(name: "Commands (Cont.)", value: "!monitortgwo - monitor thegoodwillout !stoptgwo - stop monitoring thegoodwillout\n!monitordsm - start monitoring dsm - !stopdsm - stop monitoring dsm\n!monitoreflash - monitor dsm eflash - !stopeflash - stop monitoring eflash\n!monitorkith - monitor KITH - !stopkith - stop monitoring KITH")
    end
  end

    bot.command(:monitortgwo) do |event|
      monitorTGWO(event)
    end

    bot.command(:monitordsm) do |event|
      monitorDSM(event)
    end

    bot.command(:stopdsm) do |event|
      @dsm = false
      event.channel.send_embed do |embed|
        embed.title = "Stopping dsm monitor"
        embed.colour = 0x808080
      end
    end

    bot.command(:stoptgwo) do |event|
      @tgwo = false
      event.channel.send_embed do |embed|
        embed.title = "Stopping thegoodwillout monitor"
        embed.colour = 0x808080
      end
    end

    bot.command(:monitoreflash) do |event|
      monitorEFLASH(event)
    end

    bot.command(:stopeflash) do |event|
      @eflash = false
      event.channel.send_embed do |embed|
        embed.title = "Stopping eflash monitor..."
        embed.colour = 0x808080
      end
    end

    bot.command(:monitorkith) do |event|
      monitorKITH(event)
    end

    bot.command(:stopkith) do |event|
      @kith = false
      event.channel.send_embed do |embed|
        embed.title = "Stopping KITH monitor..."
        embed.colour = 0x808080
      end
    end

  def monitorTGWO(event)
    event.channel.send_embed do |embed|
      embed.title = "Starting TGWO Monitor..."
      embed.colour = 0x808080
    end
    @tgwo = true
    linklist,newlinklist = [],[]
    user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_0) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.854.0 Safari/535.2"
    doc = Nokogiri::XML(open("https://www.thegoodwillout.com/media/sitemap/en/sitemap.xml",'User-Agent' => user_agent))

    doc.css("url loc").each do |loc|
      link = loc.text
      linklist << link
    end

    while true
      break if @tgwo == false
      doc = Nokogiri::XML(open("https://www.thegoodwillout.com/media/sitemap/en/sitemap.xml",'User-Agent' => user_agent))
      doc.css("url loc").each do |loc|
        newlink = loc.text
        newlinklist << newlink
      end

      newlinklist.each do |link|
        if linklist.include? link
        else
          puts "new link: "+link
           linklist << link
           event.channel.send_embed do |embed|
             embed.title = "TGWO"
             embed.colour = 0x808080
             embed.description = "NEW ITEM"
             embed.add_field(name: "Link", value: link)
           end
         end
        end
      end
    end

    def monitorDSM(event)
      event.channel.send_embed do |embed|
        embed.title = "Starting DSM Monitor..."
        embed.colour = 0x808080
      end
      @dsm = true
      linklist,newlinklist = [],[]
      doc = Nokogiri::XML(open("http://shop.doverstreetmarket.com/us/sitemap.xml",'User-Agent' => @user_agent))

      doc.css("url loc").each do |loc|
        link = loc.text
        linklist << link
      end

      while true
        break if @dsm == false
        doc = Nokogiri::XML(open("http://shop.doverstreetmarket.com/us/sitemap.xml",'User-Agent' => @user_agent))
        doc.css("url loc").each do |loc|
          newlink = loc.text
          newlinklist << newlink
        end

        newlinklist.each do |link|
          if linklist.include? link
          else
            puts "new link: "+link
             linklist << link
             event.channel.send_embed do |embed|
               embed.title = "DSM"
               embed.colour = 0x808080
               embed.description = "NEW ITEM"
               embed.add_field(name: "Link", value: link)
             end
           end
          end
        end
      end

      def monitorEFLASH(event)
        event.channel.send_embed do |embed|
          embed.title = "Starting EFLASH Monitor..."
          embed.colour = 0x808080
        end
        @eflash = true
        linklist,newlinklist = [],[]
        doc = Nokogiri::XML(open("https://eflash.doverstreetmarket.com/sitemap_products_1.xml",'User-Agent' => @user_agent))

        doc.css("url loc").each do |loc|
          link = loc.text
          linklist << link
        end

        while true
          sleep(30)
          break if @eflash == false
          doc = Nokogiri::XML(open("https://eflash.doverstreetmarket.com/sitemap_products_1.xml",'User-Agent' => @user_agent))
          doc.css("url loc").each do |loc|
            newlink = loc.text
            newlinklist << newlink
          end

          newlinklist.each do |link|
            if linklist.include? link
            else
              puts "new link: "+link
               linklist << link
               event.channel.send_embed do |embed|
                 embed.title = "DSM E-FLASH"
                 embed.colour = 0x808080
                 embed.description = "NEW ITEM"
                 embed.add_field(name: "Link", value: link)
               end
             end
            end
          end
        end

        def monitorKITH(event)
          event.channel.send_embed do |embed|
            embed.title = "Starting KITH Monitor..."
            embed.colour = 0x808080
          end
          @kith = true
          linklist,newlinklist = [],[]
          doc = Nokogiri::XML(open("https://kith.com/sitemap_products_1.xml",'User-Agent' => @user_agent))

          doc.css("url loc").each do |loc|
            link = loc.text
            linklist << link
          end

          while true
            break if @kith == false
            sleep(30)
            doc = Nokogiri::XML(open("https://kith.com/sitemap_products_1.xml",'User-Agent' => @user_agent))
            doc.css("url loc").each do |loc|
              newlink = loc.text
              newlinklist << newlink
            end

            newlinklist.each do |link|
              if linklist.include? link
              else
                puts "new link: "+link
                 linklist << link
                 event.channel.send_embed do |embed|
                   embed.title = "DSM E-FLASH"
                   embed.colour = 0x808080
                   embed.description = "NEW ITEM"
                   embed.add_field(name: "Link", value: link)
                 end
               end
              end
            end
          end

bot.run
