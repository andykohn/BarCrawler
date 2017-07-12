require 'net/http'
require 'json'

def get_alcohol_types
  url = 'http://www.thecocktaildb.com/api/json/v1/1/list.php?a=list'
  uri = URI(url)
  response = Net::HTTP.get(uri)
  alcohol_types = JSON.parse(response)
  return alcohol_types
end

def get_drinks_id(alcohol_types)

  drinks_list= Array.new
  alcohol_types['drinks'].each { |alcohol_type|
    unless alcohol_type['strAlcoholic'].nil?
      url =  "http://www.thecocktaildb.com/api/json/v1/1/filter.php?a=#{alcohol_type['strAlcoholic']}".gsub(' ',  '_')
      uri = URI(url)
      response = Net::HTTP.get(uri)
      drink_list = JSON.parse(response)
      drinks_list.concat(drink_list['drinks'])
    end
  }
   drinks_list
end

def get_drinks(drinks_list)
  detailed_drink_list= Array.new
  drinks_list.each_with_index { |id, index|
    url = "http://www.thecocktaildb.com/api/json/v1/1/lookup.php?i=#{id['idDrink']}".gsub(' ',  '_')
    uri = URI(url)
    response = Net::HTTP.get(uri)
    drink = JSON.parse(response)['drinks']
    detailed_drink_list.push drink[0]
    #print drink[0].class.name
    #print drink[0]
    drink_name = drink[0]['strDrink'].gsub(' ',  '_').gsub('/','_')
    open("./output/drinks/#{drink_name}.json", 'w') { |f|
      f.puts drink[0].to_json
    }
    if index == 3
      break
    end
  }
  detailed_drink_list
end

def get_ingredients
  ingredients = Hash.new
  url =  'http://www.thecocktaildb.com/api/json/v1/1/list.php?i=list'
  uri = URI(url)
  response = Net::HTTP.get(uri)
  ingredient_list = JSON.parse(response)
  # print drink_list['drinks']
  ingredient_list['drinks'].each_with_index { | item, index |
    #ingredient[:'ingredientId'] = index
    #ingredient[:'name'] = ingredient['strIngredient1']
    ingredients[index] = item['strIngredient1']
    single_ingredient = {:ingredientId => index,:name => item['strIngredient1']}
    #open("./output/ingredients/#{ingredient['strIngredient1']}.json", 'w') { |f|
    open("./output/ingredients/#{item['strIngredient1']}.json", 'w') { |f|
      f.puts single_ingredient.to_json
    }
  }

  ingredients
end

def create_map_ingredient_drink(drinks, ingredients)
  File.delete('./output/map_ingredient_drink.json') if File.exist?('./output/map_ingredient_drink.json')
  drinks.each_with_index { | item, index |
    #print "#{item['idDrink']} #{item['strDrink']} #{ingredients.key(item['strIngredient1'])} #{item['strIngredient1']} \n"
    # #{item['strIngredient1'] ingredients
    #print drinks['strIngredient1']

    open('./output/map_ingredient_drink.json', 'a') { |f|
      (1..15).each do |ingredient_id|
        unless ingredients.key(item["strIngredient#{ingredient_id}"]).nil?
          mapping = {:drinkId => item['idDrink'],
                     :ingredientId => ingredients.key(item["strIngredient#{ingredient_id}"]),
                     :measurement => item["strMeasure#{ingredient_id}"]}
          f.puts mapping.to_json
        end

        #mapping = {:drinkId => item['idDrink'], :ingredientId => ingredients.key(item['strIngredient1']), :measurement => item['strMeasure1']}
        #f.puts mapping.to_json

      end
    }
  }
end

alcohol_types = get_alcohol_types
drinks_id = get_drinks_id(alcohol_types)
drinks = get_drinks(drinks_id)
ingredients = get_ingredients
create_map_ingredient_drink(drinks, ingredients)




