require 'faye/websocket'
require 'thread'
require 'redis'
require 'json'
require 'erb'

# Require tank class relative to app/middle
require_relative '../models/tank.rb'

class GameBackend 
    CREATE_CLIENT = 0;
    ADD_CLIENT    = 1
    UPDATE_CLIENT = 2;
    DELETE_CLIENT = 3;

    KEEPALIVE_TIME = 15 # in seconds
    CHANNEL = "battledome"

    def initialize(app)
      @app     = app
      @clients = []       # Connected websockets.
      @tanks = {}   # Tanks associated with clients..
      @defeated = []      # Dead tanks.

      @game_started = false;
  end

  def call(env)
        # Started the game. Two players minimum.
        if 1 < @tanks.length && !@game_started
            p "GAME STARTED"
            @game_started = true
        end

        p "Environment: #{env['PATH_INFO']}"
      # Only load the backend server when websocket attempts to connect to */chat
      if env['PATH_INFO'] == '/game' 
        if Faye::WebSocket.websocket?(env)
          ws = Faye::WebSocket.new(env, nil, {ping: KEEPALIVE_TIME })
          # Socket connection opened.
          ws.on :open do |event|
            p "*Open Game Websocket: #{ws.object_id}"
            # Create the connecting client's tank object - randomly generate its x,y.
            tank = Tank.new(ws.object_id, rand(500), rand(500)) 
            # Send the new client its tank.
            ws.send(tank.jsonify(CREATE_CLIENT))

            # Iterate over the connected clients and send them the connecting client's tank.
            @clients.each do |client|
                # Send the new client's tank data...
                client.send(tank.jsonify(ADD_CLIENT))
                # May as well send this client's tank to the new client now...
                ws.send(@tanks[client.object_id].jsonify(ADD_CLIENT)) # client's object ids are also the tank's ids.
            end

            # Store the new clients websocket and tank.
            @clients << ws
            @tanks[ws.object_id] = tank


            p "Number of clients: #{@clients.length}"
            p "Number of tanks: #{@tanks.length}"
        end

         # Handle receieved messages.
         ws.on :message do |event|

            p [:message, event.data]

            # Parse the tank json into a hash
            tank_json = JSON.parse(event.data) # return a hash

            # Use the tank id to get the tank object.
            tank = @tanks[tank_json["id"]]

            # Update the tank object.
            tank.x_pos = tank_json["x_pos"]
            tank.y_pos = tank_json["y_pos"]
            tank.angle = tank_json["angle"]
            tank.turret_rotation = tank_json["turret_rotation"]
            tank.speed = tank_json["speed"]
            tank.fire = tank_json["fire"]
            tank.fire_x = tank_json["fire_x"]
            tank.fire_y = tank_json["fire_y"]
            tank.health = tank_json["health"]
            tank.alive = tank_json["alive"]
            tank.score = tank_json["score"]

            p [:id, tank.id]
            p [:score, tank.score]

            # Broadcast the update to all of the clients.
            @clients.each do |client|
                # Ignore the client that sent the message, it is already up to date.
                if client != ws
                    # Send the tank as a json with the UPDATE_CLIENT message.
                    client.send(tank.jsonify(UPDATE_CLIENT))
                end
            end

            # If the tank is not alive, add it to the defeated list.
            if !tank.alive
                # Remove it from tanks.
                # @tanks.delete(tank.id)
                @defeated.push(tank)
                # Add it to defeated.
                p [:tanks, @tanks.length]
                p [:defeated, @defeated.length]
            end

            # Check if the game is over.
            if @tanks.length < 2 && @game_started
                p "GAME OVER"
                @game_started = false
            end

        end

        ws.on :close do |event|
            p "*Close Game Websocket: #{ws.object_id}"
            remove_client(ws)
        end

        # Return async Rack response
        ws.rack_response

    end
else
    @app.call(env)
end
end

    # Returns the tank object with the corresponding id.
    def get_tank_by_id(id)
        @tanks.each do |tank|
            if tank.id = id
                return tank
            else
                continue
            end
        end
    end

    # Remove the client.
    def remove_client(ws)
        # Remove the socket from the clients list.
        @clients.delete_if do | client | 
            # Compare the client to the current ws object.
            client == ws
        end

        # Broadcast the client's removal to all other clients.
        @clients.each do |client|
            client.send(@tanks[ws.object_id].jsonify(DELETE_CLIENT))
        end

        # Remove the tank the hash using its socket id.
        @tanks.delete(ws.object_id)

        # Set the socket to nil. 
        ws = nil


        p "Number of clients: #{@clients.length}"
        p "Number of tanks: #{@tanks.length}"
    end

end
