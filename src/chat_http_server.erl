%%% @doc HTTP Server - serves static files and handles WebSocket upgrades
%%% Uses Erlang's built-in inets/httpd for HTTP serving.
-module(chat_http_server).
-export([start/1, stop/0]).

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
        {bind_address, {0,0,0,0}},
        {modules, [mod_alias, mod_dir, mod_get, mod_log]},
        {directory_index, ["index.html"]},
        {mime_types, [
            {"html", "text/html"},
            {"css", "text/css"},
            {"js", "application/javascript"},
            {"ico", "image/x-icon"},
            {"json", "application/json"}
        ]},
        {error_log, "/tmp/httpd_error.log"},
        {transfer_log, "/tmp/httpd_access.log"}
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
