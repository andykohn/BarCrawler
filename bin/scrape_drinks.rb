require 'net/http'
require 'json'

def get_alcohol_types
  url = 'http://www.thecocktaildb.com/api/json/v1/1/list.php?a=list'
  uri = URI(url)
  response = Net::HTTP.get(uri)
  alcohol_types = JSON.parse(response)
  return alcohol_types
end

def get_json(alcohol_types, element)

  drinks_list= Array.new
  alcohol_types['drinks'].each { |alcohol_type|
    unless alcohol_type['strAlcoholic'].nil?
      url =  "http://www.thecocktaildb.com/api/json/v1/1/filter.php?a=#{alcohol_type[element]}".gsub(' ',  '_')
      uri = URI(url)
      response = Net::HTTP.get(uri)
      drink_list = JSON.parse(response)
      drinks_list.concat(drink_list['drinks'])
    end
  }
   drinks_list
end

def parse_drinks(drinks_list, element)
  detailed_drink_list= Array.new
  drinks_list.each_with_index { |id, index|
    url = "http://www.thecocktaildb.com/api/json/v1/1/lookup.php?i=#{id[element]}".gsub(' ',  '_')
    uri = URI(url)
    response = Net::HTTP.get(uri)
    drink = JSON.parse(response)['drinks']
    detailed_drink_list.push drink[0]

    drink_name = drink[0]['strDrink'].gsub(' ',  '_').gsub('/','_')
    open("./output/#{drink_name}.json", 'w') { |f|
      f.puts drink[0].to_json
    }
  }
  detailed_drink_list
end

alcohol_types = get_alcohol_types
drinks_list = get_json(alcohol_types, 'strAlcoholic')
parse_drinks(drinks_list, 'idDrink')

#open('./output/drinkslist.backup', 'w') { |f|
#  f.puts detailed_drink_list.to_json
#}