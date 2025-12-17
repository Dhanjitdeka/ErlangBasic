%%% @doc Supervisor for the chat application
%%% Follows OTP principles with supervision tree.
%%% This supervisor manages all the core chat processes and ensures
%%% fault tolerance by restarting failed processes.
-module(chat_supervisor).
-behaviour(supervisor).

-export([start_link/0, stop/0, init/1]).

%% @doc Start the supervisor
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% @doc Stop the supervisor
stop() ->
    case whereis(?MODULE) of
        undefined -> ok;
        Pid -> 
            exit(Pid, shutdown),
            ok
    end.

%% @doc Supervisor callback - initialize child processes
%% Strategy: one_for_one - if a child dies, only restart that child
%% This provides good isolation between components
init([]) ->
    io:format("Initializing chat supervisor...~n", []),
    
    %% Define child specifications
    %% Each child is a critical component of the chat system
    ChildSpecs = [
        %% User manager - handles all connected users
        #{
            id => chat_user_manager,
            start => {chat_user_manager, start_link, []},
            restart => permanent,
            shutdown => 5000,
            type => worker,
            modules => [chat_user_manager]
        },
        %% Room manager - manages chat rooms
        #{
            id => chat_room_manager,
            start => {chat_room_manager, start_link, []},
            restart => permanent,
            shutdown => 5000,
            type => worker,
            modules => [chat_room_manager]
        },
        %% Message router - routes messages between users and rooms
        #{
            id => chat_message_router,
            start => {chat_message_router, start_link, []},
            restart => permanent,
            shutdown => 5000,
            type => worker,
            modules => [chat_message_router]
        }
    ],
    
    %% Supervision strategy
    %% MaxRestarts = 5, MaxTime = 60 seconds
    %% If more than 5 restarts happen in 60 seconds, supervisor gives up
    SupFlags = #{
        strategy => one_for_one,
        intensity => 5,
        period => 60
    },
    
    {ok, {SupFlags, ChildSpecs}}.
