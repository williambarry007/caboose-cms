require 'faye/websocket'

module Caboose
  class MediaImageSocket
    
    KEEPALIVE_TIME = 15 # in seconds

    def initialize(app)
      @app = app
      @clients = {}
      @image_ids = {}
    end

    def call(env)             
      if Faye::WebSocket.websocket?(env)
                        
        uri = env['REQUEST_URI']
        #Caboose.log(uri)
        
        # GET /admin/images/:id/wait
        if uri =~ /\/admin\/images\/\d*\/wait/                    
          image_id = uri.gsub('/admin/images/', '').gsub('/wait', '').to_i
          #Caboose.log("Waiting on image_id #{image_id}...")          
          ws = Faye::WebSocket.new(env, nil, { :ping =>  KEEPALIVE_TIME })
          ws.on :open do |event|
            Caboose.log("Opening browser web socket for image #{image_id}...")
            @clients[image_id] = [] if @clients[image_id].nil?            
            @clients[image_id] << ws
          end
          ws.on :message do |event|            
            Caboose.log("Received browser message for image #{image_id}")
            @clients[image_id].each { |client| client.send(event.data) }
          end
          ws.on :close do |event|
            Caboose.log("Closing browser web socket for image #{image_id}...")
            #p [:close, ws.object_id, event.code, event.reason]
            @clients.delete(ws)
            ws = nil
          end                    
          ws.rack_response
          
        # GET /admin/images/:id/finished
        elsif uri =~ /\/admin\/images\/\d*\/finished/          
          image_id = uri.gsub('/admin/images/', '').gsub('/finished', '').to_i                    
          ws = Faye::WebSocket.new(env, nil, { :ping =>  KEEPALIVE_TIME })
          ws.on :open do |event|
            #p [:open, ws.object_id]
            Caboose.log("Opening server web socket for image #{image_id}...")
            @image_ids[ws.object_id] = image_id
          end
          ws.on :message do |event|
            #p [:message, event.data]
            Caboose.log("Receieved server message for image #{image_id}")
            image_id = @image_ids[ws.object_id]            
            @clients[image_id].each { |client| client.send(event.data) }
          end
          ws.on :close do |event|
            #p [:close, ws.object_id, event.code, event.reason]
            Caboose.log("Closing server web socket for image #{image_id}...")
            @image_ids.delete(ws.object_id)
            ws = nil
          end                    
          ws.rack_response
        end
        
      else
        @app.call(env)
      end
      
    end
  end
end

