%%% @doc Main chat application module
%%% This is the entry point for the WhatsApp-like chat application.
%%% It provides a simple interface to start the server.
-module(chat_app).
-export([start/0, start/1, stop/0]).

%% @doc Start the chat server on default port 8080
start() ->
    start(8080).

%% @doc Start the chat server on specified port
%% @param Port The port number to listen on
start(Port) ->
    io:format("~n=== WhatsApp-like Chat Server ===~n", []),
    io:format("Starting server on port ~p...~n", [Port]),
    
    %% Start the application supervisor
    case chat_supervisor:start_link() of
        {ok, SupervisorPid} ->
            io:format("✓ Chat supervisor started~n", []),
            
            %% Start the WebSocket server on port 8081
            chat_websocket_handler:start(8081),
            io:format("✓ WebSocket server started on port 8081~n", []),
            
            %% Start the HTTP server
            case chat_http_server:start(Port) of
                {ok, _HttpPid} ->
                    io:format("✓ HTTP server started on port ~p~n", [Port]),
                    io:format("~nServer is ready!~n", []),
                    io:format("Open your browser at: http://localhost:~p~n~n", [Port]),
                    {ok, SupervisorPid};
                {error, Reason} ->
                    io:format("✗ Failed to start HTTP server: ~p~n", [Reason]),
                    {error, Reason}
            end;
        {error, Reason} ->
            io:format("✗ Failed to start supervisor: ~p~n", [Reason]),
            {error, Reason}
    end.

%% @doc Stop the chat server
stop() ->
    io:format("Stopping chat server...~n", []),
    chat_http_server:stop(),
    chat_supervisor:stop(),
    io:format("Server stopped.~n", []),
    ok.
