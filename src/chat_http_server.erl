%%% @doc HTTP Server - serves static files and handles WebSocket upgrades
%%% Uses Erlang's built-in inets/httpd for HTTP serving.
-module(chat_http_server).
-export([start/1, stop/0, handle_request/3]).

-define(STATIC_DIR, "/home/runner/work/ErlangBasic/ErlangBasic/priv/static").

%% @doc Start HTTP server on specified port
start(Port) ->
    io:format("Starting HTTP server on port ~p...~n", [Port]),
    
    %% Start inets application
    application:start(inets),
    
    %% Configure and start httpd
    Config = [
        {port, Port},
        {server_name, "chat_server"},
        {server_root, "/tmp"},
        {document_root, ?STATIC_DIR},
        {modules, [?MODULE]},
        {mime_types, [
            {"html", "text/html"},
            {"css", "text/css"},
            {"js", "application/javascript"},
            {"ico", "image/x-icon"}
        ]}
    ],
    
    case inets:start(httpd, Config) of
        {ok, Pid} ->
            io:format("HTTP server started successfully~n", []),
            {ok, Pid};
        {error, Reason} ->
            io:format("Failed to start HTTP server: ~p~n", [Reason]),
            {error, Reason}
    end.

%% @doc Stop HTTP server
stop() ->
    inets:stop().

%% @doc Handle incoming HTTP requests
%% This is called by inets for each request
handle_request(SessionID, _Env, Input) ->
    %% For now, we'll let inets handle file serving
    %% WebSocket handling will be added via a separate module
    mod_get:do(SessionID, Input).
