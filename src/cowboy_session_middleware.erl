%%%-------------------------------------------------------------------
%%% @author dasudian
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 六月 2015 下午5:00
%%%-------------------------------------------------------------------
-module(cowboy_session_middleware).
-behaviour(cowboy_middleware).

%% API
-export([execute/2]).

execute(Req, Env) ->
  Req2 = cowboy_session:on_request(Req),
  {ok, Req2, Env}.
