require 'rubygems'
require 'mechanize'
require 'pry'
require 'nokogiri'
require 'open-uri'

# if there is a need for proxy server
@agent = Mechanize.new
# agent.set_proxy('http://2unblocksite.cf/', 8080)


# https://newyork.craigslist.org/search/aap?query=lease+break

# XPATH for individual listing:
# //*[@id="searchform"]/div[2]/div[3]/p[1]/span/span[2]/a/@href'

# regex for parsing phone numbers: /\d{2}[\s\d-]{5,}/

# regex for parsing email addresses: /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i


CLNY = "https://newyork.craigslist.org"

CLURL = "https://newyork.craigslist.org/search/aap"

# takes a string (search key word) as an argument
def lease_break_url(string)
	formated_string = string.gsub(" ", "+")
	CLURL + "?" + "query=" + formated_string
end

# get the response in XML format given a url path
def get_response_url
	doc = Nokogiri::HTML(open(lease_break_url))
end

# returns the url path for each listing
def get_listings_path
 listings = get_response_url.css('p.row')
 arr = Array.new
 listings.each do |url|
 	# arr << url.xpath('//*[@id="searchform"]/div[2]/div[3]/p[1]/span/span[2]/a/@href').first.value
 	arr << url.css('a @href').first.value
 end
 # File.open('results.txt', 'w') { |file| file.write(arr) }
 arr
end


# return an array of hashes containing information about every listing scraped
def listing_xml
	content = {}
	arr = []
	listings_href = get_listings_path
	listings_href.each do |href|
		doc = Nokogiri::HTML(open(CLNY + href))
		description = doc.xpath('//*[@id="postingbody"]').first.text
		room = doc.css('p.attrgroup span').first.text
		title = doc.css('span.postingtitletext').text
		price = doc.css('span.price').text
		image = doc.css('div.tray img @src').text ? doc.css('div.tray img @src').text : "no image"
		reply_href = doc.css(".replylink @href").text
		# binding.pry
		ext_number = description.scan(/\d{2}[\s\d-]{5,}/)
		ext_email = description.scan(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i)
		binding.pry
		arr << {title: title,
						price: price,
						room: room,
						description: description,
						image: image,
						reply_href: CLNY + reply_href,
						number: ext_number.uniq,
						email: ext_email.uniq


		       }
	end
	binding.pry
	arr
end


def get_email_from_reply_button
	arr = []
	listing_xml.each do |node|
		url_link = node[:reply_href]
		doc = Nokogiri::HTML(open(url_link))
		arr << doc.css(".anonemail").text
		binding.pry
	end
	binding.pry
end

get_listings_path
listing_xml
get_email_from_reply_button
