%%% @doc Simple JSON encoder/decoder
%%% Minimal JSON support for chat messages
-module(json_util).
-export([encode/1, decode/1]).

%% @doc Encode Erlang term to JSON binary
encode(Map) when is_map(Map) ->
    Pairs = maps:fold(fun(K, V, Acc) ->
        Key = encode_value(K),
        Value = encode_value(V),
        [<<Key/binary, ":", Value/binary>> | Acc]
    end, [], Map),
    Body = list_to_binary(string:join([binary_to_list(P) || P <- lists:reverse(Pairs)], ",")),
    <<"{", Body/binary, "}">>;
encode(Term) ->
    encode_value(Term).

encode_value(Term) when is_binary(Term) ->
    %% Escape quotes in string
    Escaped = binary:replace(Term, <<"\"">>, <<"\\\"">>, [global]),
    <<"\"", Escaped/binary, "\"">>;
encode_value(Term) when is_list(Term) ->
    try list_to_binary(Term) of
        Bin -> encode_value(Bin)
    catch
        _:_ ->
            %% It's a list of terms
            Values = [encode_value(V) || V <- Term],
            Body = list_to_binary(string:join([binary_to_list(V) || V <- Values], ",")),
            <<"[", Body/binary, "]">>
    end;
encode_value(Term) when is_atom(Term) ->
    encode_value(atom_to_binary(Term, utf8));
encode_value(Term) when is_integer(Term) ->
    list_to_binary(integer_to_list(Term));
encode_value(Term) when is_float(Term) ->
    list_to_binary(float_to_list(Term));
encode_value(true) ->
    <<"true">>;
encode_value(false) ->
    <<"false">>;
encode_value(null) ->
    <<"null">>;
encode_value(Term) when is_map(Term) ->
    encode(Term).

%% @doc Decode JSON binary to Erlang term
%% Simple implementation for basic JSON objects
decode(Bin) when is_binary(Bin) ->
    String = binary_to_list(Bin),
    {Value, _} = parse_value(string:trim(String)),
    Value.

parse_value([${ | Rest]) ->
    parse_object(Rest, #{});
parse_value([$[ | Rest]) ->
    parse_array(Rest, []);
parse_value([$" | Rest]) ->
    parse_string(Rest, []);
parse_value("true" ++ Rest) ->
    {true, Rest};
parse_value("false" ++ Rest) ->
    {false, Rest};
parse_value("null" ++ Rest) ->
    {null, Rest};
parse_value(String) ->
    parse_number(String, []).

parse_object([$} | Rest], Acc) ->
    {Acc, Rest};
parse_object(String, Acc) ->
    String1 = string:trim(String),
    {Key, Rest1} = parse_string(string:trim(String1, leading, [$"]), []),
    Rest2 = string:trim(Rest1),
    [$: | Rest3] = Rest2,
    {Value, Rest4} = parse_value(string:trim(Rest3)),
    NewAcc = maps:put(list_to_binary(Key), Value, Acc),
    Rest5 = string:trim(Rest4),
    case Rest5 of
        [$, | Rest6] -> parse_object(Rest6, NewAcc);
        [$} | Rest6] -> {NewAcc, Rest6};
        _ -> {NewAcc, Rest5}
    end.

parse_array([$] | Rest], Acc) ->
    {lists:reverse(Acc), Rest};
parse_array(String, Acc) ->
    String1 = string:trim(String),
    {Value, Rest1} = parse_value(String1),
    Rest2 = string:trim(Rest1),
    case Rest2 of
        [$, | Rest3] -> parse_array(Rest3, [Value | Acc]);
        [$] | Rest3] -> {lists:reverse([Value | Acc]), Rest3};
        _ -> {lists:reverse([Value | Acc]), Rest2}
    end.

parse_string([$" | Rest], Acc) ->
    {lists:reverse(Acc), Rest};
parse_string([$\\, $" | Rest], Acc) ->
    parse_string(Rest, [$" | Acc]);
parse_string([C | Rest], Acc) ->
    parse_string(Rest, [C | Acc]);
parse_string([], Acc) ->
    {lists:reverse(Acc), []}.

parse_number(String, Acc) ->
    case String of
        [C | Rest] when C >= $0, C =< $9; C == $-; C == $.; C == $e; C == $E ->
            parse_number(Rest, [C | Acc]);
        _ ->
            NumStr = lists:reverse(Acc),
            Num = try
                list_to_integer(NumStr)
            catch
                error:badarg ->
                    try
                        list_to_float(NumStr)
                    catch
                        error:badarg ->
                            %% Invalid number format, return 0 as fallback
                            0
                    end
            end,
            {Num, String}
    end.
