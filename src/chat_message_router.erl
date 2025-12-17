%%% @doc Message Router - routes messages between users and rooms
%%% Handles message delivery with concurrent processing.
%%% Each message is processed in its own process for maximum throughput.
-module(chat_message_router).
-behaviour(gen_server).

-export([start_link/0, route_message/1, store_message/1, get_room_history/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {
    message_history  %% ETS table: stores recent messages per room
}).

-record(message, {
    id,
    from,
    to,          %% room name or username
    content,
    timestamp,
    type         %% room_message | direct_message
}).

%% API Functions

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% @doc Route a message to its destination
%% Messages are processed concurrently for high throughput
route_message(MessageData) ->
    gen_server:cast(?MODULE, {route_message, MessageData}).

%% @doc Store a message in history
store_message(Message) ->
    gen_server:cast(?MODULE, {store_message, Message}).

%% @doc Get message history for a room
get_room_history(RoomName) ->
    gen_server:call(?MODULE, {get_room_history, RoomName}).

%% gen_server Callbacks

init([]) ->
    io:format("Message router starting...~n", []),
    %% Create ETS table for message history
    %% ordered_set keeps messages in chronological order
    HistoryTable = ets:new(message_history, [named_table, public, ordered_set]),
    {ok, #state{message_history = HistoryTable}}.

handle_call({get_room_history, RoomName}, _From, State) ->
    %% Retrieve last 50 messages for the room
    Pattern = {{RoomName, '_'}, '_'},
    Messages = ets:match_object(message_history, Pattern),
    
    %% Sort by timestamp and take last 50
    SortedMessages = lists:reverse(lists:sort(Messages)),
    RecentMessages = lists:sublist(SortedMessages, 50),
    
    {reply, {ok, RecentMessages}, State};

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast({route_message, MessageData}, State) ->
    %% Spawn a new process to handle this message concurrently
    %% This allows multiple messages to be processed simultaneously
    spawn(fun() -> process_message(MessageData) end),
    {noreply, State};

handle_cast({store_message, Message}, State) ->
    %% Generate unique message ID
    MessageId = {Message#message.to, erlang:unique_integer([monotonic, positive])},
    
    %% Store in ETS
    ets:insert(message_history, {MessageId, Message}),
    
    {noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% Internal Functions

%% @doc Process and deliver a message
%% This runs in its own process for concurrency
process_message(#{type := Type, from := From, to := To, content := Content}) ->
    Timestamp = erlang:system_time(millisecond),
    
    %% Create message record
    Message = #message{
        id = erlang:unique_integer([monotonic, positive]),
        from = From,
        to = To,
        content = Content,
        timestamp = Timestamp,
        type = Type
    },
    
    %% Store in history
    store_message(Message),
    
    %% Route based on type
    case Type of
        room_message ->
            deliver_to_room(From, To, Content, Timestamp);
        direct_message ->
            deliver_to_user(From, To, Content, Timestamp);
        _ ->
            io:format("Unknown message type: ~p~n", [Type])
    end.

%% @doc Deliver message to all users in a room
deliver_to_room(From, RoomName, Content, Timestamp) ->
    case chat_room_manager:get_room_members(RoomName) of
        {ok, Members} ->
            %% Create message JSON
            MsgJson = json_util:encode(#{
                type => <<"message">>,
                from => list_to_binary(From),
                room => list_to_binary(RoomName),
                content => list_to_binary(Content),
                timestamp => Timestamp
            }),
            
            %% Send to all room members concurrently
            lists:foreach(fun(Member) ->
                spawn(fun() ->
                    case chat_user_manager:get_user_pid(Member) of
                        {ok, Pid} ->
                            Pid ! {send, MsgJson};
                        _ ->
                            ok
                    end
                end)
            end, Members),
            
            io:format("Message from ~p delivered to room ~p (~p members)~n", 
                     [From, RoomName, length(Members)]);
        _ ->
            io:format("Room not found: ~p~n", [RoomName])
    end.

%% @doc Deliver message to a specific user
deliver_to_user(From, ToUser, Content, Timestamp) ->
    case chat_user_manager:get_user_pid(ToUser) of
        {ok, Pid} ->
            MsgJson = json_util:encode(#{
                type => <<"direct_message">>,
                from => list_to_binary(From),
                content => list_to_binary(Content),
                timestamp => Timestamp
            }),
            Pid ! {send, MsgJson},
            io:format("Direct message from ~p to ~p delivered~n", [From, ToUser]);
        _ ->
            io:format("User not found: ~p~n", [ToUser])
    end.
