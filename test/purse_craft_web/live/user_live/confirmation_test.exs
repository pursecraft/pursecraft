defmodule PurseCraftWeb.UserLive.ConfirmationTest do
  use PurseCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias PurseCraft.Identity
  alias PurseCraft.IdentityFactory
  alias PurseCraft.TestHelpers.IdentityHelper

  setup do
    %{
      unconfirmed_user: IdentityFactory.insert(:unconfirmed_user),
      confirmed_user: IdentityFactory.insert(:user)
    }
  end

  describe "Confirm user" do
    test "renders confirmation page for unconfirmed user", %{conn: conn, unconfirmed_user: user} do
      token =
        IdentityHelper.extract_user_token(fn url ->
          Identity.deliver_login_instructions(user, url)
        end)

      {:ok, _lv, html} = live(conn, ~p"/users/log-in/#{token}")
      assert html =~ "Confirm my account"
    end

    test "renders login page for confirmed user", %{conn: conn, confirmed_user: user} do
      token =
        IdentityHelper.extract_user_token(fn url ->
          Identity.deliver_login_instructions(user, url)
        end)

      {:ok, _lv, html} = live(conn, ~p"/users/log-in/#{token}")
      refute html =~ "Confirm my account"
      assert html =~ "Log in"
    end

    test "confirms the given token once", %{conn: conn, unconfirmed_user: user} do
      token =
        IdentityHelper.extract_user_token(fn url ->
          Identity.deliver_login_instructions(user, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/users/log-in/#{token}")

      form = form(lv, "#confirmation_form", %{"user" => %{"token" => token}})
      render_submit(form)

      conn = follow_trigger_action(form, conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "User confirmed successfully"

      assert Identity.get_user!(user.id).confirmed_at
      # we are logged in now
      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/"

      # log out, new conn
      unauthenticated_conn = build_conn()

      {:ok, _lv, html} =
        unauthenticated_conn
        |> live(~p"/users/log-in/#{token}")
        |> follow_redirect(unauthenticated_conn, ~p"/users/log-in")

      assert html =~ "Magic link is invalid or it has expired"
    end

    test "logs confirmed user in without changing confirmed_at", %{
      conn: conn,
      confirmed_user: user
    } do
      token =
        IdentityHelper.extract_user_token(fn url ->
          Identity.deliver_login_instructions(user, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/users/log-in/#{token}")

      form = form(lv, "#login_form", %{"user" => %{"token" => token}})
      render_submit(form)

      conn = follow_trigger_action(form, conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Welcome back!"

      assert Identity.get_user!(user.id).confirmed_at == user.confirmed_at

      # log out, new conn
      unauthenticated_conn = build_conn()

      {:ok, _lv, html} =
        unauthenticated_conn
        |> live(~p"/users/log-in/#{token}")
        |> follow_redirect(unauthenticated_conn, ~p"/users/log-in")

      assert html =~ "Magic link is invalid or it has expired"
    end

    test "raises error for invalid token", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> live(~p"/users/log-in/invalid-token")
        |> follow_redirect(conn, ~p"/users/log-in")

      assert html =~ "Magic link is invalid or it has expired"
    end
  end
end
