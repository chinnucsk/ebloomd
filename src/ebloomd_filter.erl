%% @license The FreeBSD License
%% @copyright 2012 Wooga GmbH

-module (ebloomd_filter).
-compile ([export_all]).

-behavior (gen_server).
-export ([
    init/1, handle_call/3, handle_cast/2,
    handle_info/2, terminate/2, code_change/3]).


insert(FilterPid, Element) ->
    gen_server:cast(FilterPid, {insert, Element}).

contains(FilterPid, Element) ->
    contains(FilterPid, Element, infinity).

contains(FilterPid, Element, Timeout) ->
    gen_server:call(FilterPid, {contains, Element}, Timeout).


start(Size, ErrRate, Seed) ->
    gen_server:start(?MODULE, [Size, ErrRate, Seed], []).


init(Settings = [Size, ErrRate, Seed]) ->
    % State is the reference to the mutable filter.
    {ok, Ref} = ebloom:new(Size, ErrRate, Seed),
    {ok, {Ref, Settings}}.



% purge by replacing the filter altogether.
handle_call(purge, _From, {_Ref, Settings}) ->
    {ok, NewS} = init(Settings),
    {reply, done, NewS};


% Check for element membership with the filter.
handle_call({contains, Element}, _From, S = {Ref, _}) when is_binary(Element) ->
    {reply, ebloom:contains(Ref, Element), S};

handle_call({contains, Element}, From, S) ->
    handle_call({contains, term_to_binary(Element)}, From, S);

handle_call(_Message, _From, State) ->
    {reply, undefined, State}.


% Insert a new element into the bloom filter.
handle_cast({insert, Element}, S = {Ref, _}) when is_binary(Element) ->
    ebloom:insert(Ref, Element),
    {noreply, S};

handle_cast({insert, Element}, S) ->
    handle_cast({insert, term_to_binary(Element)}, S);


% Ignore undefined calls.
handle_cast(_Request, State) -> {noreply, State}.
handle_info(_Info, State) -> {noreply, State}.
code_change(_OldVsn, State, _Extra) -> {ok, State}.
terminate(_Reason, _State) -> terminated.
