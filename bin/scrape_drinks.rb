require 'net/http'
require 'json'

def get_alcohol_types
  url = 'http://www.thecocktaildb.com/api/json/v1/1/list.php?a=list'
  uri = URI(url)
  response = Net::HTTP.get(uri)
  JSON.parse(response)
  #alcohol_types = JSON.parse(response)
  # alcohol_types
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
  File.delete('./output/drink.json') if File.exist?('./output/drink.json')
  drinks_list.each_with_index { |id, index|
    url = "http://www.thecocktaildb.com/api/json/v1/1/lookup.php?i=#{id['idDrink']}".gsub(' ',  '_')
    uri = URI(url)
    response = Net::HTTP.get(uri)
    drink = JSON.parse(response)['drinks']
    detailed_drink_list.push drink[0]
    open('./output/drink.json', 'a') { |f|
      f.puts drink[0].to_json
    }
    #if index == 2
    #  break
    #end
  }
  detailed_drink_list
end

def get_ingredients
  ingredients = Hash.new
  url =  'http://www.thecocktaildb.com/api/json/v1/1/list.php?i=list'
  uri = URI(url)
  response = Net::HTTP.get(uri)
  ingredient_list = JSON.parse(response)
  File.delete('./output/ingredients.json') if File.exist?('./output/ingredients.json')
  ingredient_list['drinks'].each_with_index { | item, index |
    ingredients[index] = item['strIngredient1']
    single_ingredient = {:ingredientId => index,:name => item['strIngredient1']}
    open('./output/ingredients.json', 'a') { |f|
      f.puts single_ingredient.to_json
    }

  }
  ingredients
end

def create_map_ingredient_drink(drinks, ingredients)
  File.delete('./output/map_ingredient_drink.json') if File.exist?('./output/map_ingredient_drink.json')
  drinks.each_with_index { | item |

    open('./output/map_ingredient_drink.json', 'a') { |f|
      (1..15).each do |ingredient_id|
        unless ingredients.key(item["strIngredient#{ingredient_id}"]).nil?
          mapping = {:drinkId => item['idDrink'],
                     :ingredientId => ingredients.key(item["strIngredient#{ingredient_id}"]),
                     :measurement => item["strMeasure#{ingredient_id}"],
                     :iorder => ingredient_id
          }
          f.puts mapping.to_json
        end

      end
    }
  }
end

alcohol_types = get_alcohol_types
drinks_id = get_drinks_id(alcohol_types)
drinks = get_drinks(drinks_id)
ingredients = get_ingredients
create_map_ingredient_drink(drinks, ingredients)


=begin

Creating drinks table:
CREATE EXTERNAL TABLE IF NOT EXISTS drinks_db.drinks (
  `idDrink` INT,
  `strDrink` string,
  `strCategory` string,
  `strAlcoholic` string,
  `strGlass` string,
  `strInstructions` string,
  `strDrinkThumb` string,
  `dateModified` string
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES (
  'serialization.format' = '1','ignore.malformed.json' = 'true'
) LOCATION 's3://drinkslistak/drinks/'
TBLPROPERTIES ('has_encrypted_data'='false')


Creating ingredients table:
CREATE EXTERNAL TABLE IF NOT EXISTS drinks_db.ingredients (
  `ingredientId` INT,
  `name` string
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES (
  'serialization.format' = '1','ignore.malformed.json' = 'true'
) LOCATION 's3://drinkslistak/ingredients/'
TBLPROPERTIES ('has_encrypted_data'='false')


Creating map_ingredient_drink table:
CREATE EXTERNAL TABLE IF NOT EXISTS drinks_db.map_ingredient_drink (
  `drinkId` INT,
  `ingredientId` INT,
  `measurement` string,
  `order` INT
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES (
  'serialization.format' = '1','ignore.malformed.json' = 'true'
) LOCATION 's3://drinkslistak/map_ingredient_drink/'
TBLPROPERTIES ('has_encrypted_data'='false')

=end



