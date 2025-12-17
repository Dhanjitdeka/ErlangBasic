%%% @doc Room Manager - manages chat rooms
%%% Handles creation of chat rooms and room membership.
%%% Uses ETS for efficient room storage and lookup.
-module(chat_room_manager).
-behaviour(gen_server).

-export([start_link/0, create_room/1, join_room/2, leave_room/2,
         get_room_members/1, get_all_rooms/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {
    rooms_table  %% ETS table: RoomName -> [Members]
}).

%% API Functions

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% @doc Create a new chat room
create_room(RoomName) ->
    gen_server:call(?MODULE, {create_room, RoomName}).

%% @doc Join a chat room
join_room(RoomName, Username) ->
    gen_server:call(?MODULE, {join_room, RoomName, Username}).

%% @doc Leave a chat room
leave_room(RoomName, Username) ->
    gen_server:cast(?MODULE, {leave_room, RoomName, Username}).

%% @doc Get members of a room
get_room_members(RoomName) ->
    gen_server:call(?MODULE, {get_room_members, RoomName}).

%% @doc Get all rooms
get_all_rooms() ->
    gen_server:call(?MODULE, get_all_rooms).

%% gen_server Callbacks

init([]) ->
    io:format("Room manager starting...~n", []),
    RoomsTable = ets:new(chat_rooms, [named_table, public, set]),
    
    %% Create a default "general" room
    ets:insert(chat_rooms, {"general", []}),
    io:format("Created default room: general~n", []),
    
    {ok, #state{rooms_table = RoomsTable}}.

handle_call({create_room, RoomName}, _From, State) ->
    case ets:lookup(chat_rooms, RoomName) of
        [] ->
            ets:insert(chat_rooms, {RoomName, []}),
            io:format("Room created: ~p~n", [RoomName]),
            {reply, {ok, created}, State};
        _ ->
            {reply, {error, room_exists}, State}
    end;

handle_call({join_room, RoomName, Username}, _From, State) ->
    case ets:lookup(chat_rooms, RoomName) of
        [{RoomName, Members}] ->
            %% Check if user is already in room
            case lists:member(Username, Members) of
                true ->
                    {reply, {ok, already_member}, State};
                false ->
                    NewMembers = [Username | Members],
                    ets:insert(chat_rooms, {RoomName, NewMembers}),
                    io:format("User ~p joined room ~p~n", [Username, RoomName]),
                    {reply, {ok, joined}, State}
            end;
        [] ->
            %% Room doesn't exist, create it and join
            ets:insert(chat_rooms, {RoomName, [Username]}),
            io:format("Created room ~p and added user ~p~n", [RoomName, Username]),
            {reply, {ok, joined}, State}
    end;

handle_call({get_room_members, RoomName}, _From, State) ->
    case ets:lookup(chat_rooms, RoomName) of
        [{RoomName, Members}] -> {reply, {ok, Members}, State};
        [] -> {reply, {error, room_not_found}, State}
    end;

handle_call(get_all_rooms, _From, State) ->
    Rooms = ets:tab2list(chat_rooms),
    RoomNames = [RoomName || {RoomName, _Members} <- Rooms],
    {reply, RoomNames, State};

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast({leave_room, RoomName, Username}, State) ->
    case ets:lookup(chat_rooms, RoomName) of
        [{RoomName, Members}] ->
            NewMembers = lists:delete(Username, Members),
            ets:insert(chat_rooms, {RoomName, NewMembers}),
            io:format("User ~p left room ~p~n", [Username, RoomName]),
            ok;
        [] ->
            ok
    end,
    {noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
