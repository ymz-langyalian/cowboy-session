%%%-------------------------------------------------------------------
%%% @author dasudian
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 六月 2015 下午6:18
%%%-------------------------------------------------------------------
-module(cowboy_pooler).

%% API
-export([use_member/2]).

use_member(Fun, Pool) ->
    Member = pooler:take_member(Pool),
    try Fun(Member) of
        Result ->
            pooler:return_member(Pool, Member, ok),
            Result
    catch
        Exception ->
            pooler:return_member(Pool, Member, fail),
            {exception, Exception}
    end.
