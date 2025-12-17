%%% @doc WebSocket Handler - manages WebSocket connections
%%% Handles WebSocket protocol upgrade and message framing.
%%% Each connection runs in its own process for true concurrency.
-module(chat_websocket_handler).
-export([start/1, init/1, handle_messages/2]).

%% @doc Start WebSocket listener on specified port
start(Port) ->
    io:format("Starting WebSocket server on port ~p...~n", [Port]),
    spawn(fun() -> listen(Port) end).

%% @doc Listen for WebSocket connections
listen(Port) ->
    {ok, ListenSocket} = gen_tcp:listen(Port, [
        binary,
        {packet, 0},
        {active, false},
        {reuseaddr, true}
    ]),
    io:format("WebSocket server listening on port ~p~n", [Port]),
    accept_loop(ListenSocket).

%% @doc Accept incoming connections
accept_loop(ListenSocket) ->
    case gen_tcp:accept(ListenSocket) of
        {ok, Socket} ->
            %% Spawn a new process for this connection
            spawn(?MODULE, init, [Socket]),
            accept_loop(ListenSocket);
        {error, Reason} ->
            io:format("Accept error: ~p~n", [Reason]),
            accept_loop(ListenSocket)
    end.

%% @doc Initialize WebSocket connection
init(Socket) ->
    %% Perform WebSocket handshake
    case do_handshake(Socket) of
        ok ->
            io:format("WebSocket connection established, entering message loop~n", []),
            %% Enter message loop
            handle_messages(Socket, undefined);
        {error, Reason} ->
            io:format("WebSocket handshake failed: ~p~n", [Reason]),
            gen_tcp:close(Socket)
    end.

%% @doc Handle incoming WebSocket messages
handle_messages(Socket, Username) ->
    io:format("Setting socket to active once (Username: ~p)~n", [Username]),
    inet:setopts(Socket, [{active, once}]),
    io:format("Waiting for messages...~n", []),
    receive
        {tcp, Socket, Data} ->
            io:format("Received TCP data (length ~p): ~p~n", [byte_size(Data), Data]),
            %% Decode WebSocket frame
            case decode_frame(Data) of
                {ok, Message} ->
                    io:format("Decoded frame message: ~p~n", [Message]),
                    %% Process message
                    NewUsername = process_websocket_message(Message, Socket, Username),
                    handle_messages(Socket, NewUsername);
                {error, Reason} ->
                    io:format("Frame decode error: ~p~n", [Reason]),
                    handle_messages(Socket, Username)
            end;
        
        {send, Message} ->
            %% Send message to client
            Frame = encode_frame(Message),
            gen_tcp:send(Socket, Frame),
            handle_messages(Socket, Username);
        
        {tcp_closed, Socket} ->
            io:format("WebSocket connection closed~n", []),
            case Username of
                undefined -> ok;
                _ -> chat_user_manager:unregister_user(Username)
            end,
            gen_tcp:close(Socket);
        
        {tcp_error, Socket, Reason} ->
            io:format("WebSocket error: ~p~n", [Reason]),
            case Username of
                undefined -> ok;
                _ -> chat_user_manager:unregister_user(Username)
            end,
            gen_tcp:close(Socket);
        
        stop ->
            gen_tcp:close(Socket);
        
        Other ->
            io:format("Received unexpected message: ~p~n", [Other]),
            handle_messages(Socket, Username)
    end.

%% @doc Process incoming WebSocket message
process_websocket_message(MessageBinary, _Socket, CurrentUsername) ->
    try
        %% Parse JSON message
        Message = json_util:decode(MessageBinary),
        io:format("Decoded message: ~p~n", [Message]),
        
        TypeRaw = maps:get(<<"type">>, Message, "unknown"),
        %% Convert to binary if it's a list
        Type = case TypeRaw of
            L when is_list(L) -> list_to_binary(L);
            B when is_binary(B) -> B;
            _ -> <<"unknown">>
        end,
        
        io:format("Message type: ~p~n", [Type]),
        
        case Type of
            <<"join">> ->
                %% User joining the chat
                UsernameRaw = maps:get(<<"username">>, Message),
                Username = case UsernameRaw of
                    ListVal when is_list(ListVal) -> ListVal;
                    BinVal when is_binary(BinVal) -> binary_to_list(BinVal)
                end,
                io:format("User joining: ~p~n", [Username]),
                
                case chat_user_manager:register_user(Username, self()) of
                    {ok, registered} ->
                        %% Join default room
                        chat_room_manager:join_room("general", Username),
                        
                        %% Send success response
                        Response = json_util:encode(#{
                            type => <<"join_success">>,
                            username => list_to_binary(Username),
                            room => <<"general">>
                        }),
                        io:format("Sending join success: ~p~n", [Response]),
                        self() ! {send, Response},
                        
                        Username;
                    {error, username_taken} ->
                        Response = json_util:encode(#{
                            type => <<"error">>,
                            message => <<"Username already taken">>
                        }),
                        self() ! {send, Response},
                        CurrentUsername
                end;
            
            <<"message">> ->
                %% Send message to room
                case CurrentUsername of
                    undefined ->
                        CurrentUsername;
                    _ ->
                        ContentRaw = maps:get(<<"content">>, Message),
                        Content = case ContentRaw of
                            ContentList when is_list(ContentList) -> ContentList;
                            ContentBin when is_binary(ContentBin) -> binary_to_list(ContentBin)
                        end,
                        
                        RoomRaw = maps:get(<<"room">>, Message, "general"),
                        Room = case RoomRaw of
                            RoomList when is_list(RoomList) -> RoomList;
                            RoomBin when is_binary(RoomBin) -> binary_to_list(RoomBin)
                        end,
                        
                        chat_message_router:route_message(#{
                            type => room_message,
                            from => CurrentUsername,
                            to => Room,
                            content => Content
                        }),
                        
                        CurrentUsername
                end;
            
            _ ->
                io:format("Unknown message type: ~p~n", [Type]),
                CurrentUsername
        end
    catch
        error:Error:Stack ->
            io:format("Error processing message: ~p~nStack: ~p~n", [Error, Stack]),
            CurrentUsername
    end.

%% @doc Perform WebSocket handshake
do_handshake(Socket) ->
    case gen_tcp:recv(Socket, 0, 5000) of
        {ok, Data} ->
            %% Parse HTTP request
            case parse_handshake(Data) of
                {ok, Key} ->
                    %% Generate accept key
                    AcceptKey = generate_accept_key(Key),
                    
                    %% Send handshake response
                    Response = [
                        "HTTP/1.1 101 Switching Protocols\r\n",
                        "Upgrade: websocket\r\n",
                        "Connection: Upgrade\r\n",
                        "Sec-WebSocket-Accept: ", AcceptKey, "\r\n",
                        "\r\n"
                    ],
                    gen_tcp:send(Socket, Response),
                    io:format("WebSocket handshake complete, setting socket to binary mode~n", []),
                    % Ensure socket is in binary mode
                    inet:setopts(Socket, [binary, {packet, 0}, {active, false}]),
                    ok;
                {error, Reason} ->
                    {error, Reason}
            end;
        {error, Reason} ->
            {error, Reason}
    end.

%% @doc Parse WebSocket handshake request
parse_handshake(Data) ->
    %% Look for Sec-WebSocket-Key header
    case binary:split(Data, <<"\r\n">>, [global]) of
        Lines when is_list(Lines) ->
            case find_websocket_key(Lines) of
                {ok, Key} -> {ok, Key};
                error -> {error, no_key}
            end;
        _ ->
            {error, invalid_request}
    end.

%% @doc Find WebSocket key in headers
find_websocket_key([]) ->
    error;
find_websocket_key([Line | Rest]) ->
    case binary:split(Line, <<": ">>) of
        [<<"Sec-WebSocket-Key">>, Key] -> {ok, Key};
        _ -> find_websocket_key(Rest)
    end.

%% @doc Generate WebSocket accept key
generate_accept_key(Key) ->
    %% WebSocket magic string
    Magic = <<"258EAFA5-E914-47DA-95CA-C5AB0DC85B11">>,
    %% Concatenate and hash
    Hash = crypto:hash(sha, <<Key/binary, Magic/binary>>),
    %% Base64 encode
    base64:encode(Hash).

%% @doc Decode WebSocket frame
decode_frame(<<_Fin:1, _Rsv:3, _Opcode:4, _Mask:1, Len:7, Rest/binary>>) when Len < 126 ->
    decode_payload(Rest, Len);
decode_frame(<<_Fin:1, _Rsv:3, _Opcode:4, _Mask:1, 126:7, Len:16, Rest/binary>>) ->
    decode_payload(Rest, Len);
decode_frame(_) ->
    {error, invalid_frame}.

%% @doc Decode WebSocket payload
decode_payload(<<MaskKey:4/binary, Masked/binary>>, Len) ->
    Payload = unmask_payload(Masked, MaskKey, Len),
    {ok, Payload};
decode_payload(_, _) ->
    {error, invalid_payload}.

%% @doc Unmask WebSocket payload
unmask_payload(Masked, MaskKey, Len) ->
    <<Payload:Len/binary, _/binary>> = Masked,
    unmask(Payload, MaskKey, <<>>).

unmask(<<>>, _, Acc) ->
    Acc;
unmask(<<Byte:8, Rest/binary>>, <<M1:8, M2:8, M3:8, M4:8>>, Acc) ->
    unmask(Rest, <<M2:8, M3:8, M4:8, M1:8>>, <<Acc/binary, (Byte bxor M1):8>>).

%% @doc Encode WebSocket frame
encode_frame(Payload) when is_binary(Payload) ->
    Len = byte_size(Payload),
    if
        Len < 126 ->
            <<1:1, 0:3, 1:4, 0:1, Len:7, Payload/binary>>;
        Len < 65536 ->
            <<1:1, 0:3, 1:4, 0:1, 126:7, Len:16, Payload/binary>>;
        true ->
            <<1:1, 0:3, 1:4, 0:1, 127:7, Len:64, Payload/binary>>
    end.
