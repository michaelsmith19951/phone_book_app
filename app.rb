require "sinatra"
require 'mysql2'
require 'aws-sdk-s3'
require 'bcrypt'
enable :sessions

load 'local_ENV.rb' if File.exist?('local_ENV.rb')
client = Mysql2::Client.new(:username => ENV['RDS_USERNAME'], :password => ENV['RDS_PASSWORD'], :host => ENV['RDS_HOSTNAME'], :port => ENV['RDS_PORT'], :database => ENV['RDS_DB_NAME'], :socket => '/tmp/mysql.sock')

get '/' do
  	erb :login_page, locals:{error: "", error2: ""}
end

post '/login_page' do
	user_name_input = params[:user_name_input]
	user_name_input = client.escape(user_name_input)
	results2 = client.query("SELECT * FROM useraccounts WHERE `username` = '#{user_name_input}'")
	password = params[:password]
	session[:user_name_input] = user_name_input
	logininfo = []
	results2.each do |row|
		logininfo << [[row['username']], [row['password']]]
	end
	logininfo.each do |accounts|
		salt = accounts[1][0].split('')
		salt = salt[0..28].join
		encrypt = BCrypt::Engine.hash_secret(password, salt)
		if accounts[0][0] == user_name_input && accounts[1][0] == encrypt
			redirect '/user_input_page'
		end	
	end
 	erb :login_page, locals:{logininfo: logininfo, error: "Incorrect username/password", error2: ""}
end
post '/login_page_new' do
	results2 = client.query("SELECT * FROM useraccounts")
	user_name_input = params[:user_name_input]
	password = params[:password]
	confirmpass = params[:confirmpass]
	session[:user_name_input] = user_name_input
	password = client.escape(password)
	encryption = BCrypt::Password.create(password)
	loginname1 = user_name_input.split('')
	counter = 0
	loginname1.each do |elements|
		if elements == " "
			counter += 1
		end
	end
	username_arr = []
	results2.each do |row|
		username_arr << row['username']
	end
	if counter >= 2
		erb :login_page, locals:{error: "", error2: "Invalid username format"}
	elsif username_arr.include?(user_name_input)
		erb :login_page, locals:{error: "", error2: "Username already exists"}	 
	elsif password != confirmpass
		erb :login_page, locals:{error: "", error2: "Passwords do not match"}
	else
		user_name_input = client.escape(user_name_input)
		client.query("INSERT INTO useraccounts(username, password)
  		VALUES('#{user_name_input}', '#{encryption}')")
   		redirect '/user_input_page'
   	end
end
get '/user_input_page' do
	user_name_input = session[:user_name_input]
	user_name_input = client.escape(user_name_input)
	results = client.query("SELECT * FROM usertable WHERE `Owner`='#{user_name_input}'")
	info = []
  		results.each do |row|
    	info << [[row['Index']], [row['name_input']], [row['phone_number_input']], [row['address_input']], [row['city_input']], [row['state_input']], [row['zip_input']], [row['Owner']], [row['Number']]]
 	end
	erb :user_input_page, locals:{info: info, user_name_input: session[:user_name_input]}
end
post '/user_input_page_add' do
	number = params[:number]
	phone_number_input = params[:phone_number_input]
	name_input = params[:name_input]
	address_input = params[:address_input]
	city_input = params[:city_input]
	state_input = params[:state_input]
	zip_input = params[:zip_input]
	user_name_input = session[:user_name_input]
	number = client.escape(number)
	phone_number_input = client.escape(phone_number_input)
	name_input = client.escape(name_input)
	address_input = client.escape(address_input)
	city_input = client.escape(city_input)
	state_input = client.escape(state_input)
	zip_input = client.escape(zip_input)
	user_name_input = client.escape(user_name_input)
	client.query("INSERT INTO usertable(number, name_input, phone_number_input, address_input, city_input, state_input, zip_input, owner)
  	VALUES('#{number}', '#{name_input}', '#{phone_number_input}', '#{address_input}', '#{city_input}', '#{state_input}', '#{zip_input}', '#{user_name_input}')")
  	results = client.query("SELECT * FROM usertable WHERE `Owner`='#{user_name_input}'")
	info = []
  	results.each do |row|
    	info << [[row['Index']], [row['name_input']], [row['phone_number_input']], [row['address_input']], [row['city_input']], [row['state_input']], [row['zip_input']], [row['Owner']], [row['Number']]]
 	end
	erb :user_input_page, locals:{info: info, user_name_input: session[:user_name_input]}
end
post '/user_input_page_update' do
	index_arr = params[:index_arr]
	number_arr = params[:number_arr]
	name_arr = params[:name_arr]
	phone_number_arr = params[:phone_number_arr]
	address_arr = params[:address_arr]
	city_arr = params[:city_arr]
	state_arr = params[:state_arr]
	zip_arr = params[:zip_arr]
	user_name_input = session[:user_name_input]
	user_name_input = client.escape(user_name_input)
	counter = 0
	unless index_arr == nil
		index_arr.each do |ind|
			ind = client.escape(ind)
			number_arr[counter] = client.escape(number_arr[counter])
			client.query("UPDATE `usertable` SET `Number`='#{number_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{loginname}'")
			name_arr[counter] = client.escape(name_arr[counter])
			client.query("UPDATE `usertable` SET `Name`='#{name_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{user_name_input}'")
			phone_number_arr[counter] = client.escape(phone_number_arr[counter])
			client.query("UPDATE `usertable` SET `Phone`='#{phone_number_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{user_name_input}'")
			address_arr[counter] = client.escape(address_arr[counter])
			client.query("UPDATE `usertable` SET `Address`='#{address_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{user_name_input}'")
			city_arr[counter] = client.escape(city_arr[counter])
			client.query("UPDATE `usertable` SET `Name`='#{city_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{user_name_input}'")
			state_arr[counter] = client.escape(state_arr[counter])
			client.query("UPDATE `usertable` SET `Name`='#{state_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{user_name_input}'")
			zip_arr[counter] = client.escape(zip_arr[counter])
			client.query("UPDATE `usertable` SET `Name`='#{zip_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{user_name_input}'")
			counter += 1
		end
	end
	results = client.query("SELECT * FROM usertable WHERE `Owner`='#{user_name_input}'")
	info = []
  	results.each do |row|
    	info << [[row['Index']], [row['name_input']], [row['phone_number_input']], [row['address_input']], [row['city_input']], [row['state_input']], [row['zip_input']], [row['Owner']], [row['Number']]]
 	end
	erb :user_input_page, locals:{info: info, user_name_input: session[:user_name_input]}
end
post '/user_input_page_delete' do
	number = params[:number]
	index_arr = params[:index_arr]
	number_arr = params[:number_arr]
	name_arr = params[:name_arr]
	phone_number_arr = params[:phone_number_arr]
	address_arr = params[:address_arr]
	city_arr = params[:city_arr]
	state_arr = params[:state_arr]
	zip_arr = params[:zip_arr]
	user_name_input = session[:user_name_input]
	user_name_input = client.escape(user_name_input)
	counter = 0
	unless index_arr == nil
		index_arr.each do |ind|
			ind = client.escape(ind)
			number_arr[counter] = client.escape(number_arr[counter])
			client.query("UPDATE `usertable` SET `Number`='#{number_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{loginname}'")
			name_arr[counter] = client.escape(name_arr[counter])
			client.query("UPDATE `usertable` SET `Name`='#{name_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{user_name_input}'")
			phone_number_arr[counter] = client.escape(phone_number_arr[counter])
			client.query("UPDATE `usertable` SET `Phone`='#{phone_number_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{user_name_input}'")
			address_arr[counter] = client.escape(address_arr[counter])
			client.query("UPDATE `usertable` SET `Address`='#{address_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{user_name_input}'")
			city_arr[counter] = client.escape(city_arr[counter])
			client.query("UPDATE `usertable` SET `Name`='#{city_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{user_name_input}'")
			state_arr[counter] = client.escape(state_arr[counter])
			client.query("UPDATE `usertable` SET `Name`='#{state_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{user_name_input}'")
			zip_arr[counter] = client.escape(zip_arr[counter])
			client.query("UPDATE `usertable` SET `Name`='#{zip_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{user_name_input}'")
			counter += 1
		end
	end
	number = client.escape(number)
	client.query("DELETE FROM `usertable` WHERE `Number`='#{number}' AND `Owner`='#{user_name_input}'")
	results = client.query("SELECT * FROM usertable WHERE `Owner`='#{user_name_input}'")
	info = []
  	results.each do |row|
    	info << [[row['Index']], [row['name_input']], [row['phone_number_input']], [row['address_input']], [row['city_input']], [row['state_input']], [row['zip_input']], [row['Owner']], [row['Number']]]
 	end
	erb :user_input_page, locals:{info: info, user_name_input: session[:user_name_input]}
end