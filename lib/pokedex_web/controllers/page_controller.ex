defmodule PokedexWeb.PageController do
  use PokedexWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
