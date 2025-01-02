defmodule PurseCraftWeb.UserConfirmationLiveTest do
  use PurseCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PurseCraft.Factory

  alias PurseCraft.Identity
  alias PurseCraft.Identity.Schemas.UserToken
  alias PurseCraft.Repo
  alias PurseCraft.TestHelpers.IdentityHelper

  setup do
    %{user: insert(:user)}
  end

  describe "Confirm user" do
    test "renders confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/confirm/some-token")
      assert html =~ "Confirm Account"
    end

    test "confirms the given token once", %{conn: conn, user: user} do
      token =
        IdentityHelper.extract_user_token(fn url ->
          Identity.deliver_user_confirmation_instructions(user, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/users/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "User confirmed successfully"

      assert IdentityHelper.get_user!(user.id).confirmed_at
      refute get_session(conn, :user_token)
      assert Repo.all(UserToken) == []

      # when not logged in
      {:ok, unauthenticated_lv, _html} = live(conn, ~p"/users/confirm/#{token}")

      unauthenticated_result =
        unauthenticated_lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = unauthenticated_result

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "User confirmation link is invalid or it has expired"

      # when logged in
      conn = log_in_user(build_conn(), user)

      {:ok, authenticated_lv, _html} = live(conn, ~p"/users/confirm/#{token}")

      authenticated_result =
        authenticated_lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = authenticated_result
      refute Phoenix.Flash.get(conn.assigns.flash, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/users/confirm/invalid-token")

      {:ok, conn} =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "User confirmation link is invalid or it has expired"

      refute IdentityHelper.get_user!(user.id).confirmed_at
    end
  end
end
