require "uri"
require "typhoeus"
require "json"

@start_candies = 100
@stop_candies = 105

@steps = 1

@username = ""
@password = ""

def headers
{ "X-CSRF-Token" => @token, "Cookie" => @cookies }
end

def grab_cookie(headers)
  cookie_string = ""
  
  headers["Set-Cookie"].each do |c| 
    cookie_string += c.split(";").first + "; "
  end
  
  @cookies = cookie_string
  
  #puts cookie_string
end

def grab_token
  response = Typhoeus::Request.get("https://www.hackerrank.com/")
  
  #puts response.body
  
  #yes I'm bad for using regex on an non-regular language
  regex = /(meta content=")\S+\s(name="csrf-token")/
  
  csrf_string = response.body.match(regex).to_s
  
  regex = /\"\S+=\"/
  
  csrf_string = csrf_string.match(regex).to_s
  
  @token = csrf_string.gsub(/\"/, "")
end

def login
  data = {"user[login]" => @username,
          "user[remember_me]" => "1",
          "user[password]" => @password,
          "commit" => "Sign in",
          "remote" => "true",
          "utf8" => "true" }
  
  response = Typhoeus::Request.post("https://www.hackerrank.com/users/sign_in.json",
    :headers => headers, :params => data)

  grab_cookie(response.headers_hash)
  
  result = JSON.parse(response.body)
  
  #return true if login successful
  result.keys[0] == "created_at"
end

def start_game
  #skips numbers divisible by 6 (unwinnable)
  @start_candies += @steps if @start_candies % 6 == 0
  
  data = { "n" => @start_candies,
           "remote" => "true",
           "utf8" => "true" }

  response = Typhoeus::Request.post("https://www.hackerrank.com/splash/challenge.json",
    :headers => headers, :params => data)
    
  grab_cookie(response.headers_hash)  
  
  result = JSON.parse(response.body)
  
  #checks for successful game start
  if result.values[0] == result.values[1]
    @candies = @start_candies
    return true
  else
    return false
  end
end

def pick_candies
  if @candies > 5
    move = @candies % 6
  else
    move = @candies
  end
    
  #puts "I picked #{move}"    
    
  data = { "move" => move,
           "remote" => "true",
           "utf8" => "true" }
           
  response = Typhoeus::Request.put("https://www.hackerrank.com/splash/challenge.json",
    :headers => headers, :params => data)
  
  grab_cookie(response.headers_hash)
  
  #remove puts to hide output
  puts result = JSON.parse(response.body)
  
  @candies = result["game"]["current"]
  
  #puts @candies.to_s + " left"
  
  #return 2 if game won, 1 if need to continue, 0 if incorrect response (error)
  if result["message"] == "`Congrats! You won the game. Now go ahead and play for more candies. Enjoy :)`"
    return 2
  elsif result["message"] != nil
    return 1
  else
    return 0
  end
end

def game_loop
  while true do
    if start_game
      puts "game started--#{@candies} candies"
      break
    else
      puts "game not started"
    end
  end

  while true do
    if pick_candies == 2
      puts "won #{@start_candies}"
      @start_candies += @steps
      break
    end
  end
end

grab_token

while true do
  if login
    puts "logged in"
    break
  else
    puts "login failed"
  end
end

until @start_candies > @stop_candies
  game_loop
end



