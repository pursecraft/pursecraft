defmodule PurseCraftWeb.PageController do
  use PurseCraftWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
