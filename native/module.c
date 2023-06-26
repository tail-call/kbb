#include <luajit-2.1/lua.h>

static int foo (lua_State *L) {
 int n = lua_gettop(L);    /* number of arguments */
 lua_Number sum = 0;
 int i;
 for (i = 1; i <= n; i++) {
   if (!lua_isnumber(L, i)) {
     lua_pushstring(L, "incorrect argument");
     lua_error(L);
   }
   sum += lua_tonumber(L, i);
 }
 lua_pushnumber(L, sum/n);        /* first result */
 lua_pushnumber(L, sum);         /* second result */
 return 2;                   /* number of results */
}