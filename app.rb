require 'sinatra'
require 'broadlink_rm'
require 'json'

require 'sinatra/reloader' if development?

class App < Sinatra::Application
  enable :method_override
  
  get "/" do
    @devices = Device.all
    puts @devices[0][:name]
    erb :index
  end

  get "/discover" do
    @device = Device.discover
    erb :discover
  end

  post "/device" do
    Device.create!(params)
    redirect '/'
  end

  delete "/device" do
    Device.delete!(params)
    redirect '/'
  end

  namespace '/device' do
    get %r{/(?<device_name>.+)\/(?<cmd_name>.+)} do |device_name, cmd_name|
      @device = Device.find_by_name(device_name)
      @device.execute_command(cmd_name)
      redirect '/device/' + device_name
    end
  
    get %r{/(?<device_name>.+)} do |device_name|
      @device = Device.find_by_name(device_name)
      redirect '/device/' + device_name
    end

    post %r{/(?<device_name>.+)/learn} do |device_name|
      @device = Device.find_by_name(device_name)
      @device.learn(params[:cmd_name], params[:timeout].to_i)
      redirect '/device/' + device_name
    end

    delete %r{/(?<device_name>.+)} do |device_name|
      @device = Device.find_by_name(device_name)
      @device.delete_command(params[:cmd_name])
      redirect '/device/' + device_name
    end
  end
end
