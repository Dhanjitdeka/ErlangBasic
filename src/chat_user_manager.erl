%%% @doc User Manager - handles connected users
%%% This module manages user connections using a process-per-user model.
%%% Each user gets their own process, enabling true concurrency.
%%% Uses ETS (Erlang Term Storage) for fast user lookups.
-module(chat_user_manager).
-behaviour(gen_server).

-export([start_link/0, register_user/2, unregister_user/1, 
         get_user_pid/1, get_all_users/0, broadcast_user_list/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {
    users_table  %% ETS table: Username -> {Pid, WebSocketPid}
}).

%% API Functions

%% @doc Start the user manager
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% @doc Register a new user
%% @param Username The username
%% @param WebSocketPid The WebSocket connection process
register_user(Username, WebSocketPid) ->
    gen_server:call(?MODULE, {register_user, Username, WebSocketPid}).

%% @doc Unregister a user (on disconnect)
unregister_user(Username) ->
    gen_server:cast(?MODULE, {unregister_user, Username}).

%% @doc Get the PID for a specific user
get_user_pid(Username) ->
    gen_server:call(?MODULE, {get_user_pid, Username}).

%% @doc Get list of all connected users
get_all_users() ->
    gen_server:call(?MODULE, get_all_users).

%% @doc Broadcast updated user list to all clients
broadcast_user_list() ->
    gen_server:cast(?MODULE, broadcast_user_list).

%% gen_server Callbacks

init([]) ->
    io:format("User manager starting...~n", []),
    %% Create ETS table for fast user lookups
    %% named_table allows access by name, public allows other processes to read
    UsersTable = ets:new(chat_users, [named_table, public, set]),
    {ok, #state{users_table = UsersTable}}.

handle_call({register_user, Username, WebSocketPid}, _From, State) ->
    %% Check if username is already taken
    case ets:lookup(chat_users, Username) of
        [] ->
            %% Username available - register the user
            ets:insert(chat_users, {Username, WebSocketPid}),
            io:format("User registered: ~p~n", [Username]),
            
            %% Notify all users about the new user
            spawn(fun() -> broadcast_user_list() end),
            
            {reply, {ok, registered}, State};
        _ ->
            %% Username taken
            {reply, {error, username_taken}, State}
    end;

handle_call({get_user_pid, Username}, _From, State) ->
    case ets:lookup(chat_users, Username) of
        [{Username, Pid}] -> {reply, {ok, Pid}, State};
        [] -> {reply, {error, not_found}, State}
    end;

handle_call(get_all_users, _From, State) ->
    Users = ets:tab2list(chat_users),
    Usernames = [Username || {Username, _Pid} <- Users],
    {reply, Usernames, State};

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast({unregister_user, Username}, State) ->
    case ets:lookup(chat_users, Username) of
        [{Username, _Pid}] ->
            ets:delete(chat_users, Username),
            io:format("User unregistered: ~p~n", [Username]),
            
            %% Notify all remaining users
            spawn(fun() -> broadcast_user_list() end),
            ok;
        [] ->
            ok
    end,
    {noreply, State};

handle_cast(broadcast_user_list, State) ->
    Users = ets:tab2list(chat_users),
    Usernames = [Username || {Username, _Pid} <- Users],
    
    %% Send user list to all connected clients
    UserListMsg = json_util:encode(#{
        type => <<"user_list">>,
        users => [list_to_binary(U) || U <- Usernames]
    }),
    
    lists:foreach(fun({_Username, WebSocketPid}) ->
        WebSocketPid ! {send, UserListMsg}
    end, Users),
    
    {noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
