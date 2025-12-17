%%% @doc HTTP Server - serves static files and handles WebSocket upgrades
%%% Uses Erlang's built-in inets/httpd for HTTP serving.
-module(chat_http_server).
-export([start/1, stop/0]).

%% @doc Get the static directory path
%% Uses relative path from the application root
get_static_dir() ->
    %% Get the application directory
    case code:priv_dir(erlang_chat) of
        {error, bad_name} ->
            %% Fallback to relative path if app not found
            filename:join([filename:dirname(code:which(?MODULE)), "..", "priv", "static"]);
        PrivDir ->
            filename:join(PrivDir, "static")
    end.

%% @doc Start HTTP server on specified port
start(Port) ->
    io:format("Starting HTTP server on port ~p...~n", [Port]),
    
    %% Start inets application
    application:start(inets),
    
    %% Get static directory
    StaticDir = get_static_dir(),
    io:format("Serving static files from: ~s~n", [StaticDir]),
    
    %% Configure and start httpd
    Config = [
        {port, Port},
        {server_name, "chat_server"},
        {server_root, "/tmp"},
        {document_root, StaticDir},
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
